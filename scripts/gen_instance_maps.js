// Regenerates Data_<Flavor>/mapdata_dungeons.lua / mapdata_raids.lua /
// mapdata_scenarios.lua (Twm_mapareas entries for each map, plus
// Twm_DungeonNames/Twm_RaidNames/Twm_ScenarioNames) from Map.csv DBC data
// plus an already-generated mapdata_tiles.lua. See README.md for usage.
//
// One shared script for all three categories (--kind), not three separate
// files -- unlike gen_battlegrounds.js vs gen_arenas.js (genuinely
// different UiMapAssignment handling), dungeons/raids/scenarios differ from
// each other ONLY in which Map.csv InstanceType value selects them and
// which Lua globals the output populates. Same structural approach as
// gen_arenas.js in every other respect, for the same reasons:
//   - UiMapAssignment presence for these is flavor-INCONSISTENT (confirmed:
//     Ragefire Chasm has 0 rows on Vanilla/Forever but 6 on TBC/Mists, same
//     MapID) -- unlike arenas (always zero) or battlegrounds (always
//     present), so there's no single reliable rule to build a box or a
//     live-resolved name from it. Baking per-locale names and deriving the
//     box from valid-tile extent (both already validated by gen_arenas.js)
//     sidesteps that inconsistency uniformly, whether or not a given
//     dungeon happens to have real UiMapAssignment rows on a given flavor.
//   - Most of these are pure-WMO instances (a single global WDT-level MODF,
//     no real outdoor ADT terrain -- see .claude-docs/gotchas.md's
//     "Detecting a pure WMO dungeon" entry) rather than arenas' real ADT
//     tile grids, but parse_wdt.js's tile-validity detection already reads
//     from the baked minimap tile presence either way, so the same
//     --tiles-file-derived-box approach still works unmodified.
//
// Map.csv also carries genuinely non-functional test/scrapped content mixed
// into these InstanceTypes (e.g. "(UNUSED) Scenario: Mogu Ruins", "The
// Depths [UNUSED]") -- filtered out by a plain /unused/i test on
// MapName_lang, confirmed to match every such row across a full Mists scan
// with no false positives on real content.

const fs = require('fs');
const path = require('path');
const readline = require('readline');
const { parseCsvFile: parseCsv, findCsv } = require('./csv');
const { INSTANCE_TYPE_INSTANCE, INSTANCE_TYPE_RAID, INSTANCE_TYPE_SCENARIO } = require('./dbc_enums');

const MINI2BIG = 1600 / 3; // 533.3333..., matches TerrainWorldMap.lua's MINI2BIGX/Y
const MAP_ORIGIN = 32 * MINI2BIG;
function miniToBig(v) { return (v - 32) * -MINI2BIG; }

function chunkID(a, b, c, d) { return (a.charCodeAt(0) << 24) | (b.charCodeAt(0) << 16) | (c.charCodeAt(0) << 8) | d.charCodeAt(0); }
const ID_MPHD = chunkID('M', 'P', 'H', 'D');
const ID_MODF = chunkID('M', 'O', 'D', 'F');
const ID_MOHD = chunkID('M', 'O', 'H', 'D');

// A "pure WMO" map (no real ADT tile grid at all -- Ragefire Chasm, Onyxia's
// Lair, etc., see .claude-docs/gotchas.md's "Detecting a pure WMO dungeon")
// places its one global WMO via a WDT-level MODF, guarded by
// MPHD.flags & 0x1 -- same detection preview_wmo_tiles.js already uses.
function findWdtGlobalPlacement(wdtPath) {
	if (!fs.existsSync(wdtPath)) return null;
	const buf = fs.readFileSync(wdtPath);
	let offset = 0;
	let flags = 0, modf = null;
	while (offset + 8 <= buf.length) {
		const magic = buf.readUInt32LE(offset);
		const size = buf.readUInt32LE(offset + 4);
		const dataStart = offset + 8;
		if (magic === ID_MPHD) {
			flags = buf.readUInt32LE(dataStart);
		} else if (magic === ID_MODF && size >= 64) {
			const b = dataStart;
			modf = {
				nameId: buf.readUInt32LE(b),
				pos: [buf.readFloatLE(b + 8), buf.readFloatLE(b + 12), buf.readFloatLE(b + 16)],
				rot: [buf.readFloatLE(b + 20), buf.readFloatLE(b + 24), buf.readFloatLE(b + 28)],
			};
		}
		offset = dataStart + size;
	}
	if (!(flags & 0x1) || !modf) return null;
	return modf;
}

// Root WMO's own MOHD chunk carries the whole model's local-space bounding
// box (fixed 64-byte struct: bbox min at offset 36, max at offset 48 --
// already the union of every group, no need to touch group files at all).
function readWmoBoundingBox(wmoPath) {
	const buf = fs.readFileSync(wmoPath);
	let offset = 0;
	while (offset + 8 <= buf.length) {
		const magic = buf.readUInt32LE(offset);
		const size = buf.readUInt32LE(offset + 4);
		const dataStart = offset + 8;
		if (magic === ID_MOHD) {
			return {
				min: [buf.readFloatLE(dataStart + 36), buf.readFloatLE(dataStart + 40), buf.readFloatLE(dataStart + 44)],
				max: [buf.readFloatLE(dataStart + 48), buf.readFloatLE(dataStart + 52), buf.readFloatLE(dataStart + 56)],
			};
		}
		offset = dataStart + size;
	}
	return null;
}

// Fallback box for a pure-WMO map (parse_wdt.js finds 0 valid tiles for
// these -- there's no ADT tile grid to derive one from at all): the WMO's
// own bounding box, placed by the WDT-level MODF, converted straight to Big
// coordinates -- same "World = MODF.position + local, Big = MAP_ORIGIN -
// World" placement convention gen_wmo_tiles.js's header derives, minus that
// script's own minimap-tile-baking-specific 90-degree content quirk (that's
// about how Blizzard's baking tool oriented TEXTURES, not a property of the
// WMO's own placed geometry -- irrelevant here, this is just a bounding
// box). Yaw is applied for correctness/consistency with the rest of this
// codebase, though every WDT-level global placement checked so far
// (21-map sample, see .claude-docs/gotchas.md) has none.
function pureWmoBoxFor(flavorDir, mapName, idToPath) {
	const modf = findWdtGlobalPlacement(path.join(flavorDir, 'world', 'maps', mapName, `${mapName}.wdt`));
	if (!modf) return null;
	const wmoPath = idToPath[modf.nameId];
	if (!wmoPath) return null;
	const localWmoPath = path.join(flavorDir, wmoPath);
	if (!fs.existsSync(localWmoPath)) return null;
	const bbox = readWmoBoundingBox(localWmoPath);
	if (!bbox) return null;

	const yawRad = -modf.rot[1] * Math.PI / 180;
	const cosT = Math.cos(yawRad), sinT = Math.sin(yawRad);
	function toBig(localX, localY) {
		const finalLocalX = localX * cosT - localY * sinT;
		const finalLocalY = localX * sinT + localY * cosT;
		const worldX = modf.pos[0] + finalLocalX, worldY = modf.pos[2] + finalLocalY;
		return [MAP_ORIGIN - worldX, MAP_ORIGIN - worldY];
	}
	const corners = [
		toBig(bbox.min[0], bbox.min[1]), toBig(bbox.max[0], bbox.min[1]),
		toBig(bbox.max[0], bbox.max[1]), toBig(bbox.min[0], bbox.max[1]),
	];
	return {
		x1: Math.max(...corners.map(c => c[0])), x2: Math.min(...corners.map(c => c[0])),
		y1: Math.max(...corners.map(c => c[1])), y2: Math.min(...corners.map(c => c[1])),
	};
}

// Client locales Map.csv's MapName_lang is fetched for (wago.tools:
// /db2/Map/csv?product=<product>&locale=<locale>, see --locales-dir) --
// same set gen_arenas.js/gen_poi_flightmasters.js use.
const LOCALES = ['enUS', 'deDE', 'esES', 'esMX', 'frFR', 'itIT', 'koKR', 'ptBR', 'ruRU', 'zhCN', 'zhTW'];

const KINDS = {
	dungeon: { instanceType: INSTANCE_TYPE_INSTANCE, namesVar: 'Twm_DungeonNames', label: 'dungeon' },
	raid: { instanceType: INSTANCE_TYPE_RAID, namesVar: 'Twm_RaidNames', label: 'raid' },
	scenario: { instanceType: INSTANCE_TYPE_SCENARIO, namesVar: 'Twm_ScenarioNames', label: 'scenario' },
};

// A standalone dungeon/raid/scenario: Map.csv row with ParentMapID=-1
// (top-level), InstanceType matching --kind. Deliberately NOT filtered by
// MapType=1 the way gen_arenas.js/gen_battlegrounds.js/gen_mapareas.js
// filter their own candidates -- Map.csv's MapType column is unrelated to
// InstanceType and is NOT a reliable "is this a real top-level map" signal
// for dungeons specifically (confirmed: Ragefire Chasm's own MapType is 2,
// Shadowfang Keep's is 1, despite both being ordinary InstanceType=1
// dungeons) -- InstanceType + ParentMapID=-1 is already precise enough on
// its own.
function findCandidates(mapRows, instanceType) {
	return mapRows
		.filter(r => r.ParentMapID === '-1' && r.InstanceType === instanceType)
		.filter(r => !/unused/i.test(r.MapName_lang))
		.map(r => ({ key: r.Directory, mapID: r.ID, names: { enUS: r.MapName_lang } }));
}

// {col, row} min/max across every key in Twm_WDTValidTiles["<name>"] of an
// already-generated mapdata_tiles.lua -- same "COLxROW" keys parse_wdt.js
// itself writes. Verbatim from gen_arenas.js.
function tileBoundsFor(tilesLua, name) {
	const marker = `Twm_WDTValidTiles["${name}"] = {`;
	const start = tilesLua.indexOf(marker);
	if (start === -1) return null;
	const end = tilesLua.indexOf('\n}', start);
	const block = tilesLua.slice(start, end === -1 ? undefined : end);

	let colMin = Infinity, colMax = -Infinity, rowMin = Infinity, rowMax = -Infinity;
	const re = /\["(\d+)x(\d+)"\]/g;
	let m, count = 0;
	while ((m = re.exec(block))) {
		const col = parseInt(m[1], 10), row = parseInt(m[2], 10);
		colMin = Math.min(colMin, col); colMax = Math.max(colMax, col);
		rowMin = Math.min(rowMin, row); rowMax = Math.max(rowMax, row);
		count++;
	}
	if (count === 0) return null;
	return { colMin, colMax, rowMin, rowMax, count };
}

function parseArgs(argv) {
	const opts = { kind: null, flavorDir: null, localesDir: null, tilesFile: null, listfile: null, out: null };
	for (let i = 0; i < argv.length; i++) {
		const a = argv[i];
		if (a === '--kind') opts.kind = argv[++i];
		else if (a === '--flavor-dir') opts.flavorDir = argv[++i];
		else if (a === '--locales-dir') opts.localesDir = argv[++i];
		else if (a === '--tiles-file') opts.tilesFile = argv[++i];
		else if (a === '--listfile') opts.listfile = argv[++i];
		else if (a === '--out') opts.out = argv[++i];
		else throw new Error(`Unknown option: ${a}`);
	}
	return opts;
}

function printUsage() {
	console.error('Usage: node gen_instance_maps.js --kind dungeon|raid|scenario --flavor-dir <dir with Map.*.csv> --locales-dir <dir with Map.<locale>.csv for each of ' + LOCALES.join('/') + '> --tiles-file <mapdata_tiles.lua, already regenerated including these Directory names> --listfile <community-listfile.csv, for pure-WMO maps with 0 valid tiles> --out <out-file.lua>');
}

async function main() {
	let opts;
	try {
		opts = parseArgs(process.argv.slice(2));
	} catch (e) {
		console.error(e.message);
		printUsage();
		process.exit(1);
	}

	if (!opts.kind || !KINDS[opts.kind] || !opts.flavorDir || !opts.localesDir || !opts.tilesFile || !opts.listfile || !opts.out) {
		printUsage();
		process.exit(1);
	}
	const kind = KINDS[opts.kind];

	const mapRows = parseCsv(findCsv(opts.flavorDir, 'Map.'));
	const tilesLua = fs.readFileSync(opts.tilesFile, 'utf8');

	const candidates = findCandidates(mapRows, kind.instanceType);
	console.error(`${candidates.length} ${kind.label} Map rows found:`, candidates.map(a => `${a.key} (${a.names.enUS}, MapID=${a.mapID})`));

	// stdout: case-sensitive Directory names, for parse_wdt.js's trailing
	// <ContinentName> args (run BEFORE this script, so --tiles-file already
	// has these).
	console.log(candidates.map(a => a.key).join(' '));

	// Name_lang for every other locale, keyed by Map ID -- missing locale
	// files are skipped with a warning rather than a hard failure, same as
	// gen_arenas.js/gen_poi_flightmasters.js.
	for (const locale of LOCALES) {
		if (locale === 'enUS') continue;
		let rows;
		try {
			rows = parseCsv(findCsv(opts.localesDir, `Map.${locale}.`));
		} catch (e) {
			console.error(`Skipping ${locale}: ${e.message}`);
			continue;
		}
		const byID = {};
		for (const r of rows) byID[r.ID] = r.MapName_lang;
		for (const a of candidates) {
			if (byID[a.mapID]) a.names[locale] = byID[a.mapID];
		}
	}

	// nameId -> WMO path, for the pure-WMO fallback below only (candidates
	// that DO have tile data never touch this).
	const idToPath = {};
	const rl = readline.createInterface({ input: fs.createReadStream(opts.listfile) });
	for await (const line of rl) {
		const idx = line.indexOf(';');
		if (idx === -1) continue;
		idToPath[parseInt(line.slice(0, idx), 10)] = line.slice(idx + 1).trim();
	}

	const found = [];
	for (const a of candidates) {
		const bounds = tileBoundsFor(tilesLua, a.key);
		if (bounds) {
			const box = {
				x1: miniToBig(bounds.colMin), x2: miniToBig(bounds.colMax + 1),
				y1: miniToBig(bounds.rowMin), y2: miniToBig(bounds.rowMax + 1),
			};
			found.push({ ...a, box, tileCount: bounds.count });
			continue;
		}
		// No real ADT tile grid at all -- most dungeons/raids are a single
		// global WMO (see pureWmoBoxFor's own header), unlike arenas which
		// always have real terrain even when parse_wdt.js found nothing for
		// them for some other reason.
		const box = pureWmoBoxFor(opts.flavorDir, a.key, idToPath);
		if (!box) {
			console.error(`  (skipping ${a.key} "${a.names.enUS}" -- no Twm_WDTValidTiles entry AND no pure-WMO WDT-level placement found; regenerate --tiles-file with ${a.key} included, or check it manually)`);
			continue;
		}
		found.push({ ...a, box, tileCount: 0 });
	}
	console.error(`${found.length} ${kind.label}(s) with a usable box.`);

	let fullOutput = "-- GENERATED FILE -- do not hand-edit, regenerate with scripts/gen_instance_maps.js\n"
		+ "-- and replace this file wholesale. See scripts/README.md for details.\n"
		+ "--\n"
		+ `-- ${kind.label[0].toUpperCase()}${kind.label.slice(1)} zone boxes, kept deliberately separate from\n`
		+ "-- Twm_ContinentMapID/TWM_MAPS and Twm_BattlegroundMapID/TWM_BATTLEGROUNDS\n"
		+ "-- (own dropdown category, see this script's header). No MapID table:\n"
		+ "-- same as arenas, these have no reliable UiMapID to back position\n"
		+ "-- tracking or a continent-hint lookup with.\n"
		+ "-- Twm_mapareas is the same generic per-map-name box registry every other\n"
		+ "-- top-level map category already populates, derived from valid-tile\n"
		+ "-- extent (Big coordinates, via TWM_Mini2Big_Coord's own formula) when a\n"
		+ "-- real ADT tile grid exists, or (most dungeons/raids: a single global\n"
		+ "-- WMO, no ADT grid at all) from that WMO's own MOHD bounding box placed\n"
		+ "-- by the WDT-level MODF instead -- see pureWmoBoxFor's header. Does NOT\n"
		+ "-- depend on baked minimap art existing at all (absent on Vanilla).\n"
		+ `-- ${kind.namesVar} is resolved into the actual TWM_${kind.label.toUpperCase()}S dropdown\n`
		+ "-- table at load time (TerrainWorldMap.lua), same as Twm_ArenaNames/\n"
		+ "-- Twm_flightmasters' name tables -- see this file's own header comment.\n\n"
		+ `${kind.namesVar} = {\n`;
	for (const a of found.slice().sort((x, y) => x.names.enUS.localeCompare(y.names.enUS))) {
		fullOutput += `    {\n`;
		fullOutput += `        key = "${a.key}",\n`;
		fullOutput += `        name = {\n`;
		for (const locale of LOCALES) {
			if (!a.names[locale]) continue;
			const name = a.names[locale].replace(/\\/g, '\\\\').replace(/"/g, '\\"');
			fullOutput += `            ${locale} = "${name}",\n`;
		}
		fullOutput += `        },\n`;
		fullOutput += `    },\n`;
	}
	fullOutput += "}\n\n";

	for (const a of found)
		fullOutput += `Twm_mapareas["${a.key}"] = {\n    [0] = {${a.box.x1}, ${a.box.x2}, ${a.box.y1}, ${a.box.y2}},    --${a.names.enUS.replace(/[^A-Za-z0-9']/g, '')}\n}\n`;

	fs.writeFileSync(opts.out, fullOutput);
	console.error(`\nWritten: ${opts.out}`);
}

main().catch(e => { console.error(e); process.exit(1); });
