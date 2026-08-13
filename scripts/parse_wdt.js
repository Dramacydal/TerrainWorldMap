// Standalone port of wow.export's WDTLoader.js MAIN/MAID parsing, plus a
// per-tile AreaID resolver reading straight from ADT/MCNK and AreaTable.csv.
// Regenerates mapdata_tiles.lua (Twm_WDTValidTiles, and optionally
// Twm_NoLiquidTiles) -- a complete, ready-to-use replacement, covering as
// many continents as you pass in in one go.
//
// Usage:
//   node parse_wdt.js --flavor-dir <dir> --out <out-file.lua> [--noliquid] [--areatable-dir <dir>] <ContinentName> [<ContinentName> ...]
//
// <ContinentName> is case-SENSITIVE and used as-is for the
// Twm_WDTValidTiles/Twm_mapareas Lua table key (e.g. "HawaiiMainLand"). The
// WDT/ADT/minimap file paths are derived automatically from it (lowercased)
// under --flavor-dir, matching init_workdir.ps1's / wow.export's own
// extraction layout:
//   <flavor-dir>/world/maps/<lowercase>/<lowercase>.wdt        (WDT, MAIN/MAID)
//   <flavor-dir>/world/maps/<lowercase>/<lowercase>_C_R.adt    (root ADT files)
//   <flavor-dir>/world/minimaps/<lowercase>/                   (only if --noliquid)
//
// Example (regenerating Mists' mapdata_tiles.lua from all 11 continents,
// with underwater-tile detection and AreaTable-based zone resolution):
//   node parse_wdt.js --flavor-dir "C:/Users/you/wow-data/wow_classic" --out ../Data_Mists/mapdata_tiles.lua --noliquid Azeroth Kalimdor Expansion01 Northrend HawaiiMainLand Deephome LostIsles MaelstromZone Gilneas2 TolBarad MoguIslandDailyArea
//
// --noliquid: scan each continent's `<root>/world/minimaps/<lowercase>/` for
// noLiquid_mapXX_YY.blp/noliquid_mapXX_YY.blp files (underwater zones like
// Vashj'ir ship a second minimap texture per tile that the client swaps to
// when submerged, so the water tint baked into the normal tile doesn't
// muddy the minimap) -- see findNoLiquidTiles() below for why this needs
// the actual extracted files and can't be done from a community listfile
// or from WDT data alone. Omit this flag to skip the step entirely
// (Twm_NoLiquidTiles won't even be declared in the output -- this is also
// how the addon's "Show underwater terrain" option/menu-entry decide
// whether to show up at all, see TWM_HasNoLiquidData() in TerrainWorldMap.lua).
//
// Root ADT files under each continent's own `world/maps/<lowercase>/` are
// always read if present (majority-vote each tile's real AreaID straight
// out of its own ADT's 256 MCNK sub-chunks, see getDominantAreaID() for why
// this is both more accurate and fully offline compared to either a
// Twm_mapareas rectangular bounding-box check or a live
// C_Map.GetMapInfoAtPosition() scan) -- a continent with none found just
// keeps Twm_WDTValidTiles' plain `true` for every tile, existence only.
//
// --areatable-dir <dir>: defaults to --flavor-dir (init_workdir.ps1 always
// downloads AreaTable.<version>.csv straight into the work dir alongside
// the extracted WDT/ADT files, so this needs overriding only if your
// AreaTable CSV lives somewhere else). Without a resolvable AreaTable, each
// MCNK's raw AreaID would be used as-is, which can be a sub-area/POI (e.g.
// "Garadar") rather than the top-level zone ("Nagrand") -- won't match any
// Twm_mapareas/zone-dropdown key. Resolving walks every chunk's AreaID up
// its ParentAreaID chain to the top-level zone (ParentAreaID=0) BEFORE
// majority-voting -- this also fixes spurious "a border cuts through this
// tile" warnings caused by a zone's own POIs/sub-areas splitting votes
// against its own base terrain.
//
// Axis mapping (derived from wow.export's MapViewerScreen.js world<->tile
// formulas + TerrainWorldMap's own TWM_Mini2Big_Coord): TerrainWorldMap's tile "col" is
// the WDT's tile Y index, TerrainWorldMap's tile "row" is the WDT's tile X index.
// i.e. TerrainWorldMap key "COLxROW" <-> WDT tile (x=ROW, y=COL).
// This was empirically verified (not just theorized) by matching a real
// bug screenshot pixel-for-pixel against this script's output -- see
// README.md's "Axis mapping" section for the full story. If you ever
// re-derive this from scratch, treat it as a hypothesis to be
// cross-checked against known reference tiles (see checkTiles below)
// before trusting the output wholesale.

const fs = require('fs');
const path = require('path');

const MAP_SIZE = 64;
const MAP_SIZE_SQ = MAP_SIZE * MAP_SIZE;

function chunkID(a, b, c, d) {
	// Matches wow.export's convention: chunk magic bytes read as a
	// little-endian uint32 straight off the file (no manual reversal).
	return (a.charCodeAt(0) << 24) | (b.charCodeAt(0) << 16) | (c.charCodeAt(0) << 8) | d.charCodeAt(0);
}

const ID_MAIN = chunkID('M', 'A', 'I', 'N');
const ID_MAID = chunkID('M', 'A', 'I', 'D');
const ID_MCNK = chunkID('M', 'C', 'N', 'K');
const AREAID_OFFSET = 0x34; // uint32 field inside MCNK's own chunk data
const EXPECTED_MCNK_COUNT = 256;

// id -> ParentAreaID, from AreaTable.csv. Walking this chain (see
// resolveToZone()) turns a raw MCNK sub-area/POI AreaID into its top-level
// zone AreaID (ParentAreaID=0), matching Twm_mapareas' own keys.
//
// Lazy require: csv.js pulls in the `csv-parse` npm package, which only
// needs to be installed (`npm install` in this scripts/ folder) if
// --areatable-dir is actually used -- the rest of this script (WDT/ADT
// parsing) has no CSV dependency at all.
function loadAreaParents(areaTableDir) {
	const { parseCsvFile, findCsv } = require('./csv');
	const rows = parseCsvFile(findCsv(areaTableDir, 'AreaTable.'));
	const parentOf = {};
	for (const r of rows)
		parentOf[r.ID] = parseInt(r.ParentAreaID, 10);
	return parentOf;
}

function resolveToZone(areaID, parentOf) {
	let id = areaID;
	let guard = 0;
	while (guard < 10) {
		const parent = parentOf[id];
		if (!parent)
			break;
		id = parent;
		guard++;
	}
	return id;
}

function parseWDT(buf) {
	let offset = 0;
	const result = { tiles: null, entries: null };

	while (offset < buf.length) {
		const chunkMagic = buf.readUInt32LE(offset);
		const chunkSize = buf.readUInt32LE(offset + 4);
		const dataStart = offset + 8;
		const nextOffset = dataStart + chunkSize;

		if (chunkMagic === ID_MAIN) {
			const tiles = new Array(MAP_SIZE_SQ);
			let p = dataStart;
			for (let x = 0; x < MAP_SIZE; x++) {
				for (let y = 0; y < MAP_SIZE; y++) {
					tiles[(y * MAP_SIZE) + x] = buf.readUInt32LE(p);
					p += 8; // 4 bytes read + 4 bytes skipped (matches WDTLoader.js's data.move(4))
				}
			}
			result.tiles = tiles;
		} else if (chunkMagic === ID_MAID) {
			const entries = new Array(MAP_SIZE_SQ);
			let p = dataStart;
			for (let x = 0; x < MAP_SIZE; x++) {
				for (let y = 0; y < MAP_SIZE; y++) {
					entries[(y * MAP_SIZE) + x] = {
						rootADT: buf.readUInt32LE(p),
						obj0ADT: buf.readUInt32LE(p + 4),
						obj1ADT: buf.readUInt32LE(p + 8),
						tex0ADT: buf.readUInt32LE(p + 12),
						lodADT: buf.readUInt32LE(p + 16),
						mapTexture: buf.readUInt32LE(p + 20),
						mapTextureN: buf.readUInt32LE(p + 24),
						minimapTexture: buf.readUInt32LE(p + 28),
					};
					p += 32;
				}
			}
			result.entries = entries;
		}

		offset = nextOffset;
	}

	return result;
}

function getValidTiles(filePath) {
	const buf = fs.readFileSync(filePath);
	const wdt = parseWDT(buf);

	const hasMaid = !!wdt.entries;
	console.error(`  parsed ${filePath}: hasMAID=${hasMaid}, hasMAIN=${!!wdt.tiles}`);

	const validTiles = [];

	for (let x = 0; x < MAP_SIZE; x++) {
		for (let y = 0; y < MAP_SIZE; y++) {
			const idx = (y * MAP_SIZE) + x;

			let exists = false;
			if (hasMaid) {
				const entry = wdt.entries[idx];
				exists = !!(entry && entry.rootADT);
			} else if (wdt.tiles) {
				exists = !!wdt.tiles[idx];
			}

			if (exists) {
				// TerrainWorldMap col = WDT y, TerrainWorldMap row = WDT x (see header comment).
				const key = String(y).padStart(2, '0') + 'x' + String(x).padStart(2, '0');
				validTiles.push(key);
			}
		}
	}

	console.error(`  valid (rootADT-backed) tiles: ${validTiles.length} / ${MAP_SIZE_SQ}`);
	return validTiles;
}

// Known reference tiles to sanity-check per continent, from prior manual
// investigation -- if these stop matching, double check the axis mapping
// above before trusting a fresh run's output.
const sanityChecks = {
	Azeroth: { '43x39': false, '44x39': false, '41x39': true, '42x39': true, '41x40': true, '42x40': true },
	Expansion01: { '45x06': true },
};

// Confirmed empirically: the minimap filename's own "mapXX_YY" numbering
// already matches TerrainWorldMap's own tile-key numbering directly (no
// axis swap like the WDT MAIN/MAID chunk needed) -- e.g. Data_Mists's
// existing key "16x18" for HawaiiMainLand corresponds to the real files
// map16_18.blp / noliquid_map16_18.blp on disk.
function findNoLiquidTiles(dir) {
	if (!fs.existsSync(dir)) {
		console.error(`  no noLiquid check: ${dir} doesn't exist (minimaps not extracted for this continent)`);
		return [];
	}

	const tiles = [];
	for (const f of fs.readdirSync(dir)) {
		const m = /^noliquid_map(\d+)_(\d+)\.blp$/i.exec(f);
		if (m)
			tiles.push(m[1].padStart(2, '0') + 'x' + m[2].padStart(2, '0'));
	}

	console.error(`  noLiquid tiles found: ${tiles.length}`);
	return tiles;
}

// Majority-vote AreaID across every MCNK in this ADT (not just "the center
// one"), plus how many MCNKs were found (sanity -- should be 256) and what
// fraction agreed with the winning AreaID (low agreement = a real zone
// border cuts through this tile -- confirmed case: Outland's Nagrand and
// Terokkar Forest, whose Twm_mapareas *rectangular* boxes overlap by
// several tiles even though the real terrain border between them is
// nowhere near that wide -- rectangles can't represent irregular zone
// shapes, this reads the actual per-chunk ground truth instead).
//
// If parentOf is given, each chunk's raw AreaID is resolved to its
// top-level zone (see resolveToZone()) BEFORE counting -- important, not
// just cosmetic: a zone's own base terrain and every little POI/sub-area
// scattered around it (a town, a cave mouth, a landmark) all carry
// DIFFERENT raw AreaIDs, so counting raw IDs needlessly splits votes within
// a single real zone and reports false "a border cuts through this tile"
// warnings. Resolving first makes agreement reflect genuine zone-to-zone
// borders only.
function getDominantAreaID(filePath, parentOf) {
	const buf = fs.readFileSync(filePath);
	const counts = {};
	let offset = 0;
	let mcnkCount = 0;

	while (offset + 8 <= buf.length) {
		const magic = buf.readUInt32LE(offset);
		const size = buf.readUInt32LE(offset + 4);
		const dataStart = offset + 8;

		if (magic === ID_MCNK && dataStart + AREAID_OFFSET + 4 <= buf.length) {
			mcnkCount++;
			let areaID = buf.readUInt32LE(dataStart + AREAID_OFFSET);
			if (parentOf)
				areaID = resolveToZone(areaID, parentOf);
			counts[areaID] = (counts[areaID] || 0) + 1;
		}

		offset = dataStart + size;
	}

	let bestID = null, bestCount = -1;
	for (const [idStr, count] of Object.entries(counts)) {
		if (count > bestCount) {
			bestID = parseInt(idStr, 10);
			bestCount = count;
		}
	}

	return { areaID: bestID, mcnkCount, agreement: mcnkCount ? bestCount / mcnkCount : 0 };
}

// Root ADT files only (not the split _tex0/_obj0/_obj1 files -- MCNK/areaid
// lives in the root file), named however wow.export exports them as long as
// the filename ends in "..._<col>_<row>.adt". <col>/<row> use the exact
// same x,y tile-grid numbering as this addon's own "COLxROW" tile-key
// convention -- empirically confirmed against the minimap tile filenames in
// findNoLiquidTiles() above (same grid, same numbering, no axis swap here
// either, unlike the WDT MAIN/MAID chunk which does need one -- see header
// comment).
function findAdtAreaIDs(dir, parentOf) {
	if (!fs.existsSync(dir)) {
		console.error(`  no ADT areaID check: ${dir} doesn't exist (ADTs not extracted for this continent)`);
		return {};
	}

	const re = /(?:^|_)(\d+)_(\d+)\.adt$/i;
	const byKey = {};
	let fileCount = 0;

	for (const f of fs.readdirSync(dir)) {
		const m = re.exec(f);
		if (!m)
			continue;
		fileCount++;

		const col = parseInt(m[1], 10), row = parseInt(m[2], 10);
		const key = String(col).padStart(2, '0') + 'x' + String(row).padStart(2, '0');
		const { areaID, mcnkCount, agreement } = getDominantAreaID(path.join(dir, f), parentOf);

		if (mcnkCount !== EXPECTED_MCNK_COUNT)
			console.error(`  WARNING: ${f} has ${mcnkCount} MCNK chunks (expected ${EXPECTED_MCNK_COUNT})`);
		if (areaID === null || areaID === 0)
			continue; // no real area assignment anywhere on this tile
		if (agreement < 0.5) {
			console.error(`  NOTE: ${f} -> areaID ${areaID} only agrees on `
				+ `${(agreement * 100).toFixed(0)}% of chunks -- a real zone border cuts through this tile`);
		}

		byKey[key] = areaID;
	}

	console.error(`  ADT files found: ${fileCount}, resolved areaIDs: ${Object.keys(byKey).length}`);
	return byKey;
}

function parseArgs(argv) {
	const opts = { flavorDir: null, out: null, noliquid: false, areaTableDir: null };
	const continents = [];

	for (let i = 0; i < argv.length; i++) {
		const a = argv[i];
		if (a === '--flavor-dir') opts.flavorDir = argv[++i];
		else if (a === '--out') opts.out = argv[++i];
		else if (a === '--noliquid') opts.noliquid = true;
		else if (a === '--areatable-dir') opts.areaTableDir = argv[++i];
		else if (a.startsWith('--')) throw new Error(`Unknown option: ${a}`);
		else continents.push(a);
	}

	if (opts.areaTableDir === null)
		opts.areaTableDir = opts.flavorDir;

	return { opts, continents };
}

function printUsage() {
	console.error('Usage: node parse_wdt.js --flavor-dir <dir> --out <out-file.lua> [--noliquid] [--areatable-dir <dir>] <ContinentName> [<ContinentName> ...]');
	console.error('  <ContinentName> is case-sensitive (used as-is for the Twm_mapareas/Twm_WDTValidTiles key);');
	console.error('  paths are derived under --flavor-dir as world/maps/<lowercase>/<lowercase>.wdt etc.');
	console.error('  --areatable-dir defaults to --flavor-dir if omitted.');
}

function main() {
	let opts, continents;
	try {
		({ opts, continents } = parseArgs(process.argv.slice(2)));
	} catch (e) {
		console.error(e.message);
		printUsage();
		process.exit(1);
	}

	if (!opts.flavorDir || !opts.out || continents.length === 0) {
		printUsage();
		process.exit(1);
	}

	const parentOf = loadAreaParents(opts.areaTableDir);

	let lua = "-- GENERATED FILE -- do not hand-edit, regenerate with scripts/parse_wdt.js\n"
		+ "-- and replace this file wholesale. See scripts/README.md for details.\n"
		+ "--\n"
		+ "-- Which map tiles (TerrainWorldMap grid-cell coords) have real terrain, extracted\n"
		+ "-- from this client's own world/maps/<continent>/<continent>.wdt files\n"
		+ "-- (MAIN/MAID chunks, rootADT field). This is ground truth: a tile is only\n"
		+ "-- ever real if the client actually ships terrain for it, regardless of\n"
		+ "-- what the (possibly orphaned) minimap preview texture or C_Map zone data\n"
		+ "-- might otherwise suggest. Value is `true` if no ADT areaID could be\n"
		+ "-- resolved for that tile (see --flavor-dir's ADT dir), otherwise the tile's own\n"
		+ "-- majority-vote AreaID (a real, truthy number) -- resolve to a display\n"
		+ "-- name via Twm_areadb[id].\n"
		+ "Twm_WDTValidTiles = {}\n";

	const noLiquidByContinent = {};

	for (const contName of continents) {
		const lower = contName.toLowerCase();
		const wdtPath = path.join(opts.flavorDir, 'world', 'maps', lower, `${lower}.wdt`);
		const adtDir = path.join(opts.flavorDir, 'world', 'maps', lower);

		console.error(`${contName}:`);
		const validTiles = getValidTiles(wdtPath);

		const areaIDByKey = findAdtAreaIDs(adtDir, parentOf);

		lua += `\nTwm_WDTValidTiles["${contName}"] = {\n`;
		for (const key of validTiles)
			lua += `    ["${key}"] = ${areaIDByKey[key] !== undefined ? areaIDByKey[key] : 'true'},\n`;
		lua += '}\n';

		const checks = sanityChecks[contName];
		if (checks) {
			for (const [key, expected] of Object.entries(checks)) {
				const found = validTiles.includes(key);
				const ok = found === expected;
				console.error(`  sanity check: tile ${key} -> ${found ? 'VALID' : 'not valid'} (expected ${expected ? 'VALID' : 'not valid'}) ${ok ? 'OK' : '*** MISMATCH ***'}`);
			}
		}

		if (opts.noliquid) {
			const minimapDir = path.join(opts.flavorDir, 'world', 'minimaps', lower);
			noLiquidByContinent[contName] = findNoLiquidTiles(minimapDir);
		}
	}

	if (opts.noliquid) {
		lua += "\n-- Tiles that additionally have a noLiquid_mapXX_YY.blp minimap variant --\n"
			+ "-- the client swaps to this when IsSubmerged() (see Settings.lua's \"Draw\n"
			+ "-- underwater\" option). Only declared at all when this flavor's data was\n"
			+ "-- generated with --noliquid -- TerrainWorldMap.lua feature-detects the\n"
			+ "-- underwater-texture option/menu-entry on whether this table is non-empty.\n"
			+ "Twm_NoLiquidTiles = {}\n";
		for (const [contName, tiles] of Object.entries(noLiquidByContinent)) {
			if (tiles.length === 0)
				continue;
			lua += `\nTwm_NoLiquidTiles["${contName}"] = {\n`;
			for (const key of tiles)
				lua += `    ["${key}"] = true,\n`;
			lua += '}\n';
		}
	}

	fs.writeFileSync(opts.out, lua);
	console.error(`\nWritten: ${opts.out}`);
}

main();
