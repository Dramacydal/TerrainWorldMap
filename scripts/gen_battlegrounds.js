// Regenerates Data_<Flavor>/mapdata_battlegrounds.lua (Twm_mapareas
// entries for each battleground, plus Twm_BattlegroundMapID/TWM_BATTLEGROUNDS)
// from Map/UiMap/UiMapAssignment DBC CSVs. See README.md for usage.
//
// Deliberately a separate script/table from gen_mapareas.js's continents --
// Twm_ContinentMapID/TWM_MAPS are specifically "the addon's known open-world
// continents" (used by TWM_GetContinentForMapID's parent-chain walk, the
// standalone window's continent dropdown, etc.); battlegrounds get their own
// parallel Twm_BattlegroundMapID/TWM_BATTLEGROUNDS instead of being mixed
// into that list, even though the runtime position-tracking mechanism
// (TWM_GetUnitContinentPosition) itself doesn't care which table a given
// top-level map came from -- see TerrainWorldMap.lua's merged
// TWM_ContinentByMapID reverse-index.
//
// Same coordinate transform as gen_mapareas.js: TerrainWorldMap{x1,x2,y1,y2}
// = {Region_4, Region_1, Region_3, Region_0} (Big-X = world-Y, Big-Y =
// world-X, no offset/scale).
//
// Unlike continents, a battleground's Map row has no separate "whole map"
// UiMapAssignment root row (UI_MAP_TYPE_CONTINENT/UI_MAP_SYSTEM_WORLD/
// AreaID=0) -- it's just one (or occasionally a couple, e.g. a BG with a
// genuinely disjoint second area) Zone row directly, which doubles as both
// the position-tracking UiMapID *and* the map's own [0] box (unioned if
// more than one row exists).

const fs = require('fs');
const { parseCsvFile: parseCsv, findCsv } = require('./csv');
const { INSTANCE_TYPE_BATTLEGROUND } = require('./dbc_enums');
const { flavorDir, ensureDb2Csv, envOr, readCandidates } = require('./extract');
const { skipMaps, isSkipped } = require('./skip_lists');

// Every UiMapAssignment row for this MapID, no UiMap.Type filter -- the
// Map.csv structural filter (findBattlegrounds, or gen_candidates.js's own
// prior run of it) already uniquely identifies this as a real standalone
// battleground, and every one checked so far has its own single,
// self-consistent Type across all its rows anyway (UI_MAP_TYPE_ZONE=3 on
// Vanilla/TBC/Mists, UI_MAP_TYPE_ORPHAN=6 on WoW: Forever/Camelot,
// UI_MAP_TYPE_DUNGEON=4 for Silvershard Mines specifically -- Blizzard
// nests it like a dungeon since it's an underground instance). Whitelisting
// each Type as it's discovered is exactly how Silvershard Mines got
// silently missed before, so don't filter on it at all. Returns null if
// this map genuinely has no UiMapAssignment rows at all (Map.csv row
// matching the structural filter but no map data generated yet in this
// build -- e.g. Forever's "Battle for Gilneas" as of this writing).
function battlegroundDataFor(mapRow, assignRows) {
	const zoneRows = assignRows.filter(r => r.MapID === mapRow.ID);
	if (zoneRows.length === 0)
		return null;

	const box = zoneRows.reduce((acc, r) => {
		const R0 = parseFloat(r.Region_0), R1 = parseFloat(r.Region_1);
		const R3 = parseFloat(r.Region_3), R4 = parseFloat(r.Region_4);
		return {
			x1: Math.max(acc.x1, R4), x2: Math.min(acc.x2, R1),
			y1: Math.max(acc.y1, R3), y2: Math.min(acc.y2, R0),
		};
	}, { x1: -Infinity, x2: Infinity, y1: -Infinity, y2: Infinity });

	// The UiMapID position-tracking needs (C_Map.GetPlayerMapPosition) is
	// this same zone row's own UiMapID -- there's no separate wrapper
	// UiMapID like continents have. If more than one zone row exists,
	// they should all share one UiMapID (confirmed for every BG checked
	// so far); warn instead of guessing if that's ever not true.
	const uiMapIDs = new Set(zoneRows.map(r => r.UiMapID));
	if (uiMapIDs.size > 1)
		console.error(`WARNING: ${mapRow.Directory} (${mapRow.MapName_lang}) has ${uiMapIDs.size} distinct UiMapIDs across its zone rows (${[...uiMapIDs].join(',')}) -- picking the first, double check this one by hand`);

	return {
		key: mapRow.Directory,
		name: mapRow.MapName_lang,
		mapID: mapRow.ID,
		uiMapID: zoneRows[0].UiMapID,
		box,
	};
}

// A standalone battleground: Map.csv row with ParentMapID=-1 (top-level),
// MapType=1, InstanceType=INSTANCE_TYPE_BATTLEGROUND -- same shape as
// gen_mapareas.js's continent filter, just the PvP InstanceType instead of
// the open-world one. Also excludes anything hand-listed in skip_lists.js's
// skipMaps for this flavor -- see that file's own header for what it's for
// (documented there as already applying here, but never actually did until
// now). Only ever called from gen_candidates.js now -- this script's own
// main() below reads the resulting candidates/battlegrounds.json instead of
// re-running this same discovery a second time.
function findBattlegrounds(mapRows, assignRows, flavor) {
	const battlegrounds = [];

	for (const mapRow of mapRows) {
		if (mapRow.ParentMapID !== '-1' || mapRow.MapType !== '1' || mapRow.InstanceType !== INSTANCE_TYPE_BATTLEGROUND)
			continue;
		if (isSkipped(skipMaps, flavor, mapRow.ID))
			continue;

		const bg = battlegroundDataFor(mapRow, assignRows);
		if (!bg)
			continue;

		battlegrounds.push(bg);
	}

	return battlegrounds;
}

function parseArgs(argv) {
	const opts = { workDir: null, flavor: null, out: null, force: false, proxy: null };
	for (let i = 0; i < argv.length; i++) {
		const a = argv[i];
		if (a === '--work-dir') opts.workDir = argv[++i];
		else if (a === '--flavor') opts.flavor = argv[++i];
		else if (a === '--out') opts.out = argv[++i];
		else if (a === '--force') opts.force = true;
		else if (a === '--proxy') opts.proxy = argv[++i];
		else throw new Error(`Unknown option: ${a}`);
	}
	return opts;
}

function printUsage() {
	console.error('Usage: node gen_battlegrounds.js --work-dir <dir> --flavor <product> --out <out-file.lua> [--force] [--proxy <url>]');
	console.error('  Requires scripts/gen_candidates.js to have been run first (reads candidates/battlegrounds.json for its own candidate list).');
}

function main() {
	let opts;
	try {
		opts = parseArgs(process.argv.slice(2));
	} catch (e) {
		console.error(e.message);
		printUsage();
		process.exit(1);
	}

	opts.workDir = envOr(opts.workDir, 'WORK_DIR');
	opts.flavor = envOr(opts.flavor, 'FLAVOR');
	opts.proxy = envOr(opts.proxy, 'PROXY');

	if (!opts.workDir || !opts.flavor || !opts.out) {
		printUsage();
		process.exit(1);
	}

	const dl = { workDir: opts.workDir, flavor: opts.flavor, force: opts.force, proxy: opts.proxy };
	ensureDb2Csv({ ...dl, table: 'Map' });
	ensureDb2Csv({ ...dl, table: 'UiMapAssignment' });
	const flavorDirPath = flavorDir(opts.workDir, opts.flavor);

	const mapRows = parseCsv(findCsv(flavorDirPath, 'Map.'));
	const assignRows = parseCsv(findCsv(flavorDirPath, 'UiMapAssignment.'));

	// Candidate discovery/filtering (structural Map.csv filter + skipMaps)
	// happens exactly once, in gen_candidates.js's own findBattlegrounds call
	// -- this script just looks each candidate's own Map.csv row back up by
	// ID and recomputes its box/uiMapID from assignRows (battlegroundDataFor,
	// not stored in the lightweight candidates JSON), instead of re-running
	// the same discovery filter against Map.csv a second time.
	const byID = {};
	for (const r of mapRows) byID[r.ID] = r;
	const battlegrounds = readCandidates(opts.workDir, opts.flavor, 'battlegrounds').map(c => {
		const mapRow = byID[c.id];
		if (!mapRow) {
			console.error(`WARNING: candidates/battlegrounds.json has ${c.key} (ID=${c.id}) but it's no longer in Map.csv -- stale candidates file? Re-run gen_candidates.js. Skipping.`);
			return null;
		}
		return battlegroundDataFor(mapRow, assignRows);
	}).filter(Boolean);
	console.error(`${battlegrounds.length} battlegrounds found:`, battlegrounds.map(b => `${b.key} (${b.name}, MapID=${b.mapID}, UiMapID=${b.uiMapID})`));

	let fullOutput = "-- GENERATED FILE -- do not hand-edit, regenerate with scripts/gen_battlegrounds.js\n"
		+ "-- and replace this file wholesale. See scripts/README.md for details.\n"
		+ "--\n"
		+ "-- Battleground zone boxes + their own position-tracking UiMapIDs, kept\n"
		+ "-- deliberately separate from Twm_ContinentMapID/TWM_MAPS (see this\n"
		+ "-- script's header). Twm_mapareas is the same generic per-map-name box\n"
		+ "-- registry gen_mapareas.js's continents already populate -- adding\n"
		+ "-- battleground keys to it isn't the same thing as mixing into the\n"
		+ "-- continent-list tables.\n\n"
		+ "Twm_BattlegroundMapID = {\n";
	for (const b of battlegrounds)
		fullOutput += `    ["${b.key}"] = ${b.uiMapID},    --${b.name.replace(/[^A-Za-z0-9' ]/g, '')}\n`;
	fullOutput += "}\n\n"
		+ "TWM_BATTLEGROUNDS = {\n";
	for (const b of battlegrounds)
		fullOutput += `    [C_Map.GetMapInfo(Twm_BattlegroundMapID["${b.key}"]).name] = {"${b.key}"},\n`;
	fullOutput += "}\n\n";

	for (const b of battlegrounds)
		fullOutput += `Twm_mapareas["${b.key}"] = {\n    [0] = {${b.box.x1}, ${b.box.x2}, ${b.box.y1}, ${b.box.y2}},    --${b.name.replace(/[^A-Za-z0-9']/g, '')}\n}\n`;

	fs.writeFileSync(opts.out, fullOutput);
	console.error(`\nWritten: ${opts.out}`);
}

module.exports = { findBattlegrounds };
if (require.main === module) { main(); }
