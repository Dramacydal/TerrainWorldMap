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
// Continents covered: Azeroth (Eastern Kingdoms), Kalimdor, Expansion01
// (Outland). Their uiMapIDs (for the [0] whole-continent box, matched by
// UiMapID rather than by AreaID=0 since multiple AreaID=0 rows can exist
// per continent -- see ourUiMapID below) must be updated if Blizzard ever
// renumbers them; get current values via, in-game:
//   /run for _,v in ipairs(C_Map.GetMapChildrenInfo(946, Enum.UIMapType.Continent, true)) do print(v.mapID, v.name) end

const fs = require('fs');
const path = require('path');

function parseCsv(filePath) {
	const text = fs.readFileSync(filePath, 'utf8');
	const lines = text.split(/\r?\n/).filter(l => l.length > 0);
	const header = lines[0].split(',');
	const rows = [];

	for (let i = 1; i < lines.length; i++) {
		const fields = [];
		let cur = '';
		let inQuotes = false;
		const line = lines[i];

		for (let j = 0; j < line.length; j++) {
			const ch = line[j];
			if (ch === '"') inQuotes = !inQuotes;
			else if (ch === ',' && !inQuotes) { fields.push(cur); cur = ''; }
			else cur += ch;
		}
		fields.push(cur);

		const obj = {};
		header.forEach((h, idx) => obj[h] = fields[idx]);
		rows.push(obj);
	}

	return rows;
}

function findCsv(dir, prefix) {
	const match = fs.readdirSync(dir).find(f => f.toLowerCase().startsWith(prefix.toLowerCase()) && f.toLowerCase().endsWith('.csv'));
	if (!match)
		throw new Error(`No ${prefix}*.csv found in ${dir}`);
	return path.join(dir, match);
}

function main() {
	const csvDir = process.argv[2];
	const outFile = process.argv[3];

	if (!csvDir || !outFile) {
		console.error('Usage: node gen_mapareas.js <csv-dir> <out-file.lua>');
		process.exit(1);
	}

	const mapRows = parseCsv(findCsv(csvDir, 'Map.'));
	const uiMapRows = parseCsv(findCsv(csvDir, 'UiMap.'));
	const assignRows = parseCsv(findCsv(csvDir, 'UiMapAssignment.'));

	const continents = { 'Azeroth': null, 'Kalimdor': null, 'Expansion01': null };
	for (const r of mapRows) {
		if (r.Directory in continents)
			continents[r.Directory] = r.ID;
	}
	console.error('Continent MapIDs:', continents);

	const uiMapName = {};
	for (const r of uiMapRows)
		uiMapName[r.ID] = r.Name_lang;

	// uiMapIDs for the whole-continent [0] box -- update if Blizzard
	// renumbers these (see header comment for the live /run check).
	const ourUiMapID = { 'Azeroth': '1415', 'Kalimdor': '1414', 'Expansion01': '1945' };

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
		+ "-- Zone bounding boxes for the 3 open-world continents, extracted straight\n"
		+ "-- from this client's own Map/UiMap/UiMapAssignment DBC data (rather than\n"
		+ "-- hand-collected). Loads after mapdata_zones.lua, which declares Twm_mapareas.\n\n";

	for (const [contName, mapID] of Object.entries(continents)) {
		if (!mapID) {
			console.error(`WARNING: continent "${contName}" not found in Map.csv, skipping`);
			continue;
		}

		const rows = assignRows.filter(r => r.MapID === mapID && r.AreaID !== '0');
		const out = [];

		for (const r of rows) {
			const R0 = parseFloat(r.Region_0), R1 = parseFloat(r.Region_1);
			const R3 = parseFloat(r.Region_3), R4 = parseFloat(r.Region_4);
			const name = uiMapName[r.UiMapID] || '?';
			const areaID = parseInt(r.AreaID, 10);
			out.push({
				areaID, uiMapID: r.UiMapID,
				x1: R4, x2: R1, y1: R3, y2: R0,
				name,
			});
			uiMapIDIndex[r.UiMapID] = { continent: contName, areaID };
		}
		out.sort((a, b) => a.areaID - b.areaID);

		const rootRow = assignRows.find(r => r.MapID === mapID && r.UiMapID === ourUiMapID[contName]);
		let rootStr = '';
		if (rootRow) {
			const R0 = parseFloat(rootRow.Region_0), R1 = parseFloat(rootRow.Region_1);
			const R3 = parseFloat(rootRow.Region_3), R4 = parseFloat(rootRow.Region_4);
			rootStr = `\t[0] = {${R4}, ${R1}, ${R3}, ${R0}},    --${contName}\n`;
		} else {
			console.error(`WARNING: no UiMapAssignment row found for ${contName}'s continent uiMapID (${ourUiMapID[contName]}) -- [0] box will be missing`);
		}

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

	fs.writeFileSync(outFile, fullOutput);
	console.error(`\nWritten: ${outFile}`);
	console.error('Overwrite mapdata_continents.lua with this file (or copy it there).');
}

main();
