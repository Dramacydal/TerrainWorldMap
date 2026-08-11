// Regenerates mapdata_continents.lua (the Azeroth/Kalimdor/Expansion01
// blocks of Twm_mapareas) from official DBC CSV exports. The output file
// is a complete, ready-to-use replacement -- just overwrite
// mapdata_continents.lua with it, no manual merging needed.
// Usage:
//   node gen_mapareas.js <csv-dir> <out-file.lua>
//
// <csv-dir> must contain, for the target client build:
//   Map.<version>.csv
//   UiMap.<version>.csv
//   UiMapAssignment.<version>.csv
// (exact filenames are auto-detected by prefix match, see findCsv() below --
// export these via wow.export's DBC tab, or any other WDBX/DBD-based tool).
//
// Coordinate transform: TerrainWorldMap's "Big" (world-yard) coordinate box format is
// {x1, x2, y1, y2} = {maxX, minX, maxY, minY}. UiMapAssignment's Region_0..5
// fields are a raw world-space AABB (Region_0/1/2 = min X/Y/Z, Region_3/4/5
// = max X/Y/Z). Cross-calibrated against Outland (never touched by
// Cataclysm, so old hand-collected data and fresh DBC data should
// match exactly if the transform is right) -- confirmed exact match with:
//   TerrainWorldMap{x1,x2,y1,y2} = {Region_4, Region_1, Region_3, Region_0}
// i.e. TerrainWorldMap-X = world Y, TerrainWorldMap-Y = world X, no offset/scale needed.
//
// Why regenerate at all instead of trusting old hand-collected data: even
// "untouched" Eastern Kingdoms/Kalimdor zones (e.g. Dun Morogh) differ from
// the ~2011 data by up to a few hundred yards using this exact same
// transform -- Cataclysm's Shattering subtly recalibrated Azeroth/Kalimdor
// terrain even where no content revamp happened. Outland is the only
// continent guaranteed unchanged, which is why it was used as the control.
//
// Continents covered: auto-detected from the CSVs themselves (see
// findContinents() below) -- whatever open-world continents exist in the
// target client's own UiMap/UiMapAssignment/Map data, no hardcoded name or
// uiMapID list to maintain per flavor (Vanilla has 2, TBC 3, Mists+ more).

const fs = require('fs');
const { parseCsvFile: parseCsv, findCsv } = require('./csv');

// Auto-detects every standalone open-world map in this client's own data
// instead of relying on a hardcoded name/uiMapID whitelist (which is exactly
// what breaks every time a new expansion adds one -- Northrend, Pandaria,
// and, it turns out, also small "island" maps like Deepholm).
//
// Earlier version of this filtered on UiMap.csv's Type=2 (Continent), but
// that's unreliable in both directions: "The Maelstrom" (Mists) is Type=2
// yet has zero UiMapAssignment rows anywhere (pure UI-tree grouping node,
// no MapID, no terrain -- nothing to render), while Deepholm/Lost Isles/
// Tol Barad/Gilneas2/the Mogu daily island/the Deathwing-fight Maelstrom
// Zone are all Type=3 (Zone) despite being genuine standalone open-world
// maps with their own MapID and real terrain.
//
// The reliable signal turned out to live in Map.csv instead: a standalone
// open-world map is ParentMapID=-1 (top-level, not nested under another
// map) AND MapType=1 AND InstanceType=0 (rules out dungeons/raids/
// battlegrounds/scenarios, which all have a non-zero InstanceType). Confirmed
// against known-good TBC/Vanilla data (Azeroth/Kalimdor/Outland all match,
// and the rule produces no extra false positives there) and against Mists
// (correctly separates all 6 real standalone maps from "The Maelstrom").
//
// A candidate only counts if it actually has at least one Type=3 (Zone)
// UiMapAssignment row under it -- i.e. real playable terrain, not just an
// unused/orphaned MapID.
function findContinents(uiMapRows, assignRows, mapRows, uiMapType, uiMapSystem) {
	const continents = [];

	for (const mapRow of mapRows) {
		if (mapRow.ParentMapID !== '-1' || mapRow.MapType !== '1' || mapRow.InstanceType !== '0')
			continue;

		const zoneRows = assignRows.filter(r => r.MapID === mapRow.ID && r.AreaID !== '0' && uiMapType[r.UiMapID] === '3');
		if (zoneRows.length === 0)
			continue;

		// The whole-map [0] box: prefer an explicit AreaID=0 row if this map
		// has one (true for the "big" continents), else fall back to the
		// union of every zone box found above (true for single/few-zone
		// islands like Deepholm, which have no AreaID=0 row of their own).
		//
		// AreaID=0 can have more than one candidate row per MapID though --
		// e.g. TBC's MapID=0 (Azeroth) has THREE: uiMapID 1415 (System=0, the
		// live one), 1463 (System=1, an orphaned duplicate), and 947 (the
		// "World" cosmic map, also System=0 but Type=1 not a real per-
		// continent box). Only the System=0 AND Type=2 one is trustworthy --
		// same two-filter rule the old Type=2-based detection used, just
		// applied here to picking the root row instead of picking continents.
		let rootBox;
		const rootRow = assignRows.find(r => r.MapID === mapRow.ID && r.AreaID === '0'
			&& uiMapType[r.UiMapID] === '2' && uiMapSystem[r.UiMapID] === '0');
		if (rootRow) {
			const R0 = parseFloat(rootRow.Region_0), R1 = parseFloat(rootRow.Region_1);
			const R3 = parseFloat(rootRow.Region_3), R4 = parseFloat(rootRow.Region_4);
			rootBox = { x1: R4, x2: R1, y1: R3, y2: R0 };
		} else {
			rootBox = zoneRows.reduce((acc, r) => {
				const R0 = parseFloat(r.Region_0), R1 = parseFloat(r.Region_1);
				const R3 = parseFloat(r.Region_3), R4 = parseFloat(r.Region_4);
				return {
					x1: Math.max(acc.x1, R4), x2: Math.min(acc.x2, R1),
					y1: Math.max(acc.y1, R3), y2: Math.min(acc.y2, R0),
				};
			}, { x1: -Infinity, x2: Infinity, y1: -Infinity, y2: Infinity });
		}

		continents.push({ name: mapRow.Directory, mapID: mapRow.ID, rootBox, hasOwnRootRow: !!rootRow });
	}

	return continents;
}

function main() {
	const csvDir = process.argv[2];
	const outFile = process.argv[3]; // optional -- see below

	if (!csvDir) {
		console.error('Usage: node gen_mapareas.js <csv-dir> [<out-file.lua>]');
		console.error('  <out-file.lua> is optional -- omit it to just print the continent name');
		console.error('  list (for parse_wdt.js / wow.export folder names) without writing anything.');
		process.exit(1);
	}

	const mapRows = parseCsv(findCsv(csvDir, 'Map.'));
	const uiMapRows = parseCsv(findCsv(csvDir, 'UiMap.'));
	const assignRows = parseCsv(findCsv(csvDir, 'UiMapAssignment.'));

	const uiMapName = {};
	const uiMapType = {};
	const uiMapSystem = {};
	for (const r of uiMapRows) {
		uiMapName[r.ID] = r.Name_lang;
		uiMapType[r.ID] = r.Type;
		uiMapSystem[r.ID] = r.System;
	}

	const continents = findContinents(uiMapRows, assignRows, mapRows, uiMapType, uiMapSystem);
	console.error('Continents found:', continents.map(c => `${c.name} (MapID=${c.mapID}${c.hasOwnRootRow ? '' : ', [0] box = union of its zones'})`));

	// Printed to stdout (not stderr, unlike everything else here) so it's
	// easy to capture/copy-paste straight into parse_wdt.js's trailing
	// <ContinentName> args -- same case-sensitive names, and the lowercased
	// form of each is exactly the wow.export folder name to extract
	// WDT/ADT/minimaps from (world/maps/<lowercase>/, world/minimaps/<lowercase>/).
	console.log(continents.map(c => c.name).join(' '));

	// Same names lowercased (real wow.export folder names) built into ready-
	// to-paste search regexes for wow.export's file-list search box, one per
	// extraction target -- saves typing/matching each continent by hand.
	// Escaped before joining: Directory names come from Map.csv data, not a
	// hardcoded constant, so a future/unusual client build could in theory
	// have one containing a regex metacharacter (e.g. a literal ".").
	const escapeRegExp = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
	const lowerAlt = continents.map(c => escapeRegExp(c.name.toLowerCase())).join('|');
	console.log(`minimaps/(${lowerAlt})/noliq`);
	console.log(`(${lowerAlt})\\.wdt`);
	console.log(`maps/(${lowerAlt})/\\w+_\\d+_\\d+\\.adt`);

	// uiMapID -> {continent, areaID}, so callers with a WorldMapFrame-style
	// uiMapID (not an AreaID) can look up its Twm_mapareas box directly --
	// needed because a handful of zones (Draenei/Blood Elf starting isles)
	// are filed under a *different* continent's MapID here than where
	// C_Map's own uiMap hierarchy nominally parents them (e.g. Eversong
	// Woods is a "child" of Eastern Kingdoms in C_Map's map tree for world-
	// map navigation purposes, but its actual UiMapAssignment row -- and
	// its real WDT terrain -- is filed under Expansion01/Outland).
	const uiMapIDIndex = {};

	let fullOutput = "-- GENERATED FILE -- do not hand-edit, regenerate with scripts/gen_mapareas.js\n"
		+ "-- and replace this file wholesale. See scripts/README.md for details.\n"
		+ "--\n"
		+ "-- Zone bounding boxes for this client's open-world continents, extracted\n"
		+ "-- straight from this client's own Map/UiMap/UiMapAssignment DBC data\n"
		+ "-- (rather than hand-collected). Loads after mapdata_zones.lua, which\n"
		+ "-- declares Twm_mapareas.\n\n";

	for (const { name: contName, mapID, rootBox } of continents) {
		// Type=3 (Enum.UIMapType.Zone) only -- excludes Dungeon/Micro/etc.
		// uiMapIDs that can share an AreaID with a real outdoor zone but carry
		// a totally different (phased/instanced) Region box, e.g. Mists'
		// "Shrine of Two Moons"/"Ruins of Ogudei" scenario maps colliding with
		// Pandaria zone AreaIDs. Cities have no dedicated UIMapType of their
		// own -- they're Type=3 same as regular zones -- so this doesn't drop them.
		const rows = assignRows.filter(r => r.MapID === mapID && r.AreaID !== '0' && uiMapType[r.UiMapID] === '3');
		const out = [];
		const seenAreaID = {};

		for (const r of rows) {
			const R0 = parseFloat(r.Region_0), R1 = parseFloat(r.Region_1);
			const R3 = parseFloat(r.Region_3), R4 = parseFloat(r.Region_4);
			const name = uiMapName[r.UiMapID] || '?';
			const areaID = parseInt(r.AreaID, 10);

			// Multiple UiMapAssignment rows can share the same (MapID, AreaID) --
			// seen in Mists data as e.g. 3 Orgrimmar rows differing only by
			// WMOGroupID (per-building interior scoping), all with identical
			// Region_* bounds. Twm_mapareas is keyed by areaID alone, so extra
			// rows are pure duplicates -- keep the first, warn if a later one
			// actually disagrees on the box (would mean the dedupe is wrong).
			if (seenAreaID[areaID] !== undefined) {
				const prev = seenAreaID[areaID];
				if (prev.x1 !== R4 || prev.x2 !== R1 || prev.y1 !== R3 || prev.y2 !== R0)
					console.error(`WARNING: ${contName} areaID ${areaID} has conflicting boxes across UiMapAssignment rows (kept the first) -- uiMapID ${prev.uiMapID} vs ${r.UiMapID}`);
				continue;
			}

			const entry = {
				areaID, uiMapID: r.UiMapID,
				x1: R4, x2: R1, y1: R3, y2: R0,
				name,
			};
			seenAreaID[areaID] = entry;
			out.push(entry);
			uiMapIDIndex[r.UiMapID] = { continent: contName, areaID };
		}
		out.sort((a, b) => a.areaID - b.areaID);

		const rootStr = `\t[0] = {${rootBox.x1}, ${rootBox.x2}, ${rootBox.y1}, ${rootBox.y2}},    --${contName}\n`;

		console.error(`${contName} (MapID=${mapID}): ${out.length} zones`);

		let lua = `Twm_mapareas["${contName}"] = {\n` + rootStr;
		for (const e of out)
			lua += `\t[${e.areaID}] = {${e.x1}, ${e.x2}, ${e.y1}, ${e.y2}},    --${e.name.replace(/[^A-Za-z0-9']/g, '')}\n`;
		lua += `}\n`;

		fullOutput += lua;
	}

	fullOutput += '\nTwm_UiMapID2Zone = {\n';
	for (const uiMapID of Object.keys(uiMapIDIndex).sort((a, b) => parseInt(a, 10) - parseInt(b, 10))) {
		const e = uiMapIDIndex[uiMapID];
		fullOutput += `\t[${uiMapID}] = {"${e.continent}", ${e.areaID}},\n`;
	}
	fullOutput += '}\n';

	if (outFile) {
		fs.writeFileSync(outFile, fullOutput);
		console.error(`\nWritten: ${outFile}`);
		console.error('Overwrite mapdata_continents.lua with this file (or copy it there).');
	}
}

main();
