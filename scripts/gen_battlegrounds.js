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

// A standalone battleground: Map.csv row with ParentMapID=-1 (top-level),
// MapType=1, InstanceType=INSTANCE_TYPE_BATTLEGROUND -- same shape as
// gen_mapareas.js's continent filter, just the PvP InstanceType instead of
// the open-world one.
function findBattlegrounds(mapRows, assignRows) {
	const battlegrounds = [];

	for (const mapRow of mapRows) {
		if (mapRow.ParentMapID !== '-1' || mapRow.MapType !== '1' || mapRow.InstanceType !== INSTANCE_TYPE_BATTLEGROUND)
			continue;

		// Every UiMapAssignment row for this MapID, no UiMap.Type filter --
		// the Map.csv filter above already uniquely identifies this as a
		// real standalone battleground, and every one checked so far has
		// its own single, self-consistent Type across all its rows anyway
		// (UI_MAP_TYPE_ZONE=3 on Vanilla/TBC/Mists, UI_MAP_TYPE_ORPHAN=6 on
		// WoW: Forever/Camelot, UI_MAP_TYPE_DUNGEON=4 for Silvershard Mines
		// specifically -- Blizzard nests it like a dungeon since it's an
		// underground instance). Whitelisting each Type as it's discovered
		// is exactly how Silvershard Mines got silently missed before,
		// so don't filter on it at all.
		const zoneRows = assignRows.filter(r => r.MapID === mapRow.ID);
		if (zoneRows.length === 0)
			continue;

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

		battlegrounds.push({
			key: mapRow.Directory,
			name: mapRow.MapName_lang,
			mapID: mapRow.ID,
			uiMapID: zoneRows[0].UiMapID,
			box,
		});
	}

	return battlegrounds;
}

function parseArgs(argv) {
	const opts = { flavorDir: null, out: null };
	for (let i = 0; i < argv.length; i++) {
		const a = argv[i];
		if (a === '--flavor-dir') opts.flavorDir = argv[++i];
		else if (a === '--out') opts.out = argv[++i];
		else throw new Error(`Unknown option: ${a}`);
	}
	return opts;
}

function printUsage() {
	console.error('Usage: node gen_battlegrounds.js --flavor-dir <dir with Map/UiMap/UiMapAssignment CSVs> --out <out-file.lua>');
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

	if (!opts.flavorDir || !opts.out) {
		printUsage();
		process.exit(1);
	}

	const mapRows = parseCsv(findCsv(opts.flavorDir, 'Map.'));
	const assignRows = parseCsv(findCsv(opts.flavorDir, 'UiMapAssignment.'));

	const battlegrounds = findBattlegrounds(mapRows, assignRows);
	console.error(`${battlegrounds.length} battlegrounds found:`, battlegrounds.map(b => `${b.key} (${b.name}, MapID=${b.mapID}, UiMapID=${b.uiMapID})`));

	// stdout: case-sensitive Directory names, for parse_wdt.js's trailing
	// <ContinentName> args (battlegrounds slot into that same per-continent
	// tile-validity pipeline, they're real ADT terrain like any open-world
	// zone -- just a separate, smaller map).
	console.log(battlegrounds.map(b => b.key).join(' '));

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

main();
