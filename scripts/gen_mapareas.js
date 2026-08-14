// Regenerates Data_<Flavor>/mapdata_continents.lua (Twm_mapareas) from
// Map/UiMap/UiMapAssignment DBC CSVs. See README.md for usage.
//
// Coordinate transform: UiMapAssignment's Region_0..5 is a raw world-space
// AABB (Region_0/1/2 = min X/Y/Z, Region_3/4/5 = max X/Y/Z).
//   TerrainWorldMap{x1,x2,y1,y2} = {Region_4, Region_1, Region_3, Region_0}
// i.e. TerrainWorldMap-X = world Y, TerrainWorldMap-Y = world X, no offset/scale.

const fs = require('fs');
const path = require('path');
const { parseCsvFile: parseCsv, findCsv } = require('./csv');

// Reads mapdata_zones.lua's own Twm_CapitalAreaIDs table (the single
// source of truth for which AreaIDs are capitals) instead of keeping a
// second, driftable copy of the same list in this script.
function loadCapitalAreaIDs() {
	const luaPath = path.join(__dirname, '..', 'mapdata_zones.lua');
	const text = fs.readFileSync(luaPath, 'utf8');
	const start = text.indexOf('Twm_CapitalAreaIDs = {');
	if (start === -1)
		throw new Error(`Twm_CapitalAreaIDs not found in ${luaPath}`);
	const end = text.indexOf('\n}', start);
	const block = text.slice(start, end === -1 ? undefined : end);

	const ids = new Set();
	const re = /\[(\d+)\]\s*=\s*"/g;
	let m;
	while ((m = re.exec(block)))
		ids.add(parseInt(m[1], 10));
	return ids;
}

// {uiMapID: areaID} for every UiMapAssignment row whose AreaID is a known
// capital -- replaces the old per-flavor Twm_CityMapIDs, which used 3
// different, inconsistent hand/semi-hand methods (see scripts/README.md).
function findCityMapIDs(assignRows, capitalAreaIDs) {
	const cityMapIDs = {};
	for (const r of assignRows) {
		const areaID = parseInt(r.AreaID, 10);
		if (capitalAreaIDs.has(areaID))
			cityMapIDs[r.UiMapID] = areaID;
	}
	return cityMapIDs;
}

// A standalone open-world map: Map.csv row with ParentMapID=-1 (top-level),
// MapType=1, InstanceType=0 (excludes dungeons/raids/battlegrounds/
// scenarios), and at least one Type=3 (Zone) UiMapAssignment row (real
// playable terrain, not an unused/orphaned MapID).
function findContinents(uiMapRows, assignRows, mapRows, uiMapType, uiMapSystem) {
	const continents = [];

	for (const mapRow of mapRows) {
		if (mapRow.ParentMapID !== '-1' || mapRow.MapType !== '1' || mapRow.InstanceType !== '0')
			continue;

		const zoneRows = assignRows.filter(r => r.MapID === mapRow.ID && r.AreaID !== '0' && uiMapType[r.UiMapID] === '3');
		if (zoneRows.length === 0)
			continue;

		// Whole-map [0] box: prefer the AreaID=0 row with System=0 + Type=2
		// (a MapID can have multiple AreaID=0 candidates -- duplicates, a
		// "World" cosmic map row -- only this combination is the real one).
		// Falls back to the union of zone boxes for maps with no such row
		// (single/few-zone islands like Deepholm).
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

	// stdout (not stderr): case-sensitive continent names, for
	// parse_wdt.js's trailing <ContinentName> args.
	console.log(continents.map(c => c.name).join(' '));

	// Ready-to-paste wow.export search regexes (lowercased folder names;
	// escaped in case a Directory name ever contains a regex metacharacter).
	const escapeRegExp = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
	const lowerAlt = continents.map(c => escapeRegExp(c.name.toLowerCase())).join('|');
	console.log(`minimaps/(${lowerAlt})/noliq`);
	console.log(`(${lowerAlt})\\.wdt`);
	console.log(`maps/(${lowerAlt})/\\w+_\\d+_\\d+\\.adt`);

	// uiMapID -> {continent, areaID}: a few zones (Draenei/Blood Elf isles)
	// are filed under a different continent's MapID than C_Map's own
	// uiMap tree parents them under.
	const uiMapIDIndex = {};

	const cityMapIDs = findCityMapIDs(assignRows, loadCapitalAreaIDs());
	console.error(`City maps found: ${Object.keys(cityMapIDs).length}`);

	let fullOutput = "-- GENERATED FILE -- do not hand-edit, regenerate with scripts/gen_mapareas.js\n"
		+ "-- and replace this file wholesale. See scripts/README.md for details.\n"
		+ "--\n"
		+ "-- Capital-city uiMapIDs (WorldMapFrame zoom-in sub-maps), derived from\n"
		+ "-- mapdata_zones.lua's Twm_CapitalAreaIDs via UiMapAssignment's own\n"
		+ "-- AreaID<->UiMapID join. See WorldMapOverlay.lua's city-map-tiles option.\n"
		+ "Twm_CityMapIDs = {\n";
	for (const uiMapID of Object.keys(cityMapIDs).sort((a, b) => parseInt(a, 10) - parseInt(b, 10))) {
		const name = uiMapName[uiMapID] || '?';
		fullOutput += `\t[${uiMapID}] = true,    --${name.replace(/[^A-Za-z0-9' ]/g, '')}\n`;
	}
	fullOutput += '}\n\n';

	fullOutput += "-- Zone bounding boxes for this client's open-world continents, extracted\n"
		+ "-- straight from this client's own Map/UiMap/UiMapAssignment DBC data\n"
		+ "-- (rather than hand-collected). Loads after mapdata_zones.lua, which\n"
		+ "-- declares Twm_mapareas.\n\n";

	for (const { name: contName, mapID, rootBox } of continents) {
		// Type=3 (Zone) only -- excludes Dungeon/Micro/scenario uiMapIDs that
		// can share an AreaID with a real zone but carry a different Region box.
		const rows = assignRows.filter(r => r.MapID === mapID && r.AreaID !== '0' && uiMapType[r.UiMapID] === '3');
		const out = [];
		const seenAreaID = {};

		for (const r of rows) {
			const R0 = parseFloat(r.Region_0), R1 = parseFloat(r.Region_1);
			const R3 = parseFloat(r.Region_3), R4 = parseFloat(r.Region_4);
			const name = uiMapName[r.UiMapID] || '?';
			const areaID = parseInt(r.AreaID, 10);

			// Multiple UiMapAssignment rows can share the same (MapID, AreaID)
			// (e.g. per-building interior scoping) -- keep the first, warn if a
			// later one disagrees on the box (would mean the dedupe is wrong).
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
