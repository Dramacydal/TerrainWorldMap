// Regenerates Data_<Flavor>/mapdata_tiles.lua (Twm_WDTValidTiles, optionally
// Twm_NoLiquidTiles) from real WDT/ADT/minimap files. See README.md for usage.
//
// Axis mapping: TerrainWorldMap tile key "COLxROW" <-> WDT tile (x=ROW, y=COL)
// (WDT's MAIN/MAID chunks index tiles by (x, y); TerrainWorldMap's "col" is the WDT's y,
// "row" is the WDT's x). Empirically verified against a known bug screenshot --
// if tiles come out systematically transposed/mirrored, check this first.

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

// id -> ParentAreaID, from AreaTable.csv. resolveToZone() walks this chain
// to turn a raw MCNK sub-area/POI AreaID into its top-level zone AreaID
// (ParentAreaID=0), matching Twm_mapareas' own keys.
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

// Reference tiles for regression-checking the axis mapping (Azeroth's are
// Vanilla-era; a mismatch on a post-Cataclysm client is expected, not a bug).
const sanityChecks = {
	Azeroth: { '43x39': false, '44x39': false, '41x39': true, '42x39': true, '41x40': true, '42x40': true },
	Expansion01: { '45x06': true },
};

// Minimap filename's own "mapXX_YY" numbering already matches
// TerrainWorldMap's tile-key numbering directly -- no axis swap here.
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

// Majority-vote AreaID across every MCNK in this ADT. `agreement` < 1 means
// a real zone border cuts through this tile. Resolves each chunk's raw
// AreaID to its top-level zone (resolveToZone()) BEFORE counting, so a
// zone's own POIs/sub-areas don't split votes against its base terrain.
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

// Root ADT files only (not split _tex0/_obj0/_obj1 -- MCNK/areaid lives in
// the root file), matched by filename ending in "..._<col>_<row>.adt".
// col/row match TerrainWorldMap's "COLxROW" tile-key numbering directly, no
// axis swap needed here (unlike the WDT MAIN/MAID chunk, see header comment).
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
