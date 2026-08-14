// Regenerates Data_<Flavor>/mapdata_poi_instances.lua's Twm_instances from
// AreaTrigger.db2 joined against a --teleport-csv reference table (id ->
// target_map) -- see README.md for usage and where to get that file. No
// official client DB2 table encodes an AreaTrigger's teleport target (that
// link genuinely doesn't ship to players' clients -- confirmed by
// exhaustively checking every AreaTrigger*-related DB2 table:
// AreaTriggerActionSet has no map reference, AreaTriggerAction doesn't
// exist for these clients, and cross-referencing a trigger's outdoor
// position against Twm_poi_areas mostly returns the wrong name -- e.g.
// Deadmines' entrance resolves to "Demont's Place", an unrelated nearby
// landmark, not the dungeon itself), so --teleport-csv has to come from
// somewhere else entirely.
//
// Algorithm:
//   1. Every AreaTrigger row whose ContinentID is a Map.csv row matching a
//      continent actually declared in --mapareas-file's Twm_mapareas (an
//      open-world map, not some other random MapID).
//   2. ...that also has a matching row in --teleport-csv (id -> target_map)
//      -- i.e. it's an actually-functional teleport trigger, not some other
//      kind of AreaTrigger (ambience, quest zones, PvP flags, etc.).
//   3. ...whose target_map is itself a dungeon or raid (Map.InstanceType 1
//      or 2) -- excludes battlegrounds/scenarios/whatever else teleports
//      exist for (confirmed empirically: battlegrounds and scenarios are
//      entered through their own queue systems, not a walk-through trigger,
//      so they never have a --teleport-csv row to begin with).
//   4. Named via the target map's own Map.MapName_lang -- used only as a
//      fallback; sets/dungeons.lua resolves the live, locale-correct name
//      at render time via GetRealZoneText(mapID) (confirmed: this global
//      accepts the same Map.ID as target_map, e.g. GetRealZoneText(530)
//      returns "Outland" for Map.ID 530 = Expansion01). Type is "Dungeon"
//      or "Raid" (from InstanceType), also the name of the icon this addon
//      draws for it (Icon-Dungeon / Icon-Raid -- see sets/dungeons.lua).
// Each output entry is {"Type", MapID, "Name", x, y}.
//
// Multiple trigger boxes for the same physical door (confirmed: Stratholme
// main gate and Karazhan's entrance each have 2 adjacent trigger boxes) are
// merged by centroid if they're within DEDUP_DISTANCE of another point with
// the exact same resolved name -- distinct entrances to the same dungeon
// (Dire Maul's 3 wings, Maraudon's 2 mouths) are far enough apart to survive
// as separate points, and two different dungeons/raids are never merged
// into each other even if their entrances happen to be close together.

const fs = require('fs');
const { parseCsvFile, findCsv } = require('./csv');

const DEDUP_DISTANCE = 15; // yards -- same rule used by gen_poi_graveyards.js

function dedupeByDistance(points) {
	const parent = points.map((_, i) => i);
	function find(i) {
		while (parent[i] !== i) i = parent[i];
		return i;
	}
	function union(a, b) {
		const ra = find(a), rb = find(b);
		if (ra !== rb) parent[ra] = rb;
	}

	for (let i = 0; i < points.length; i++)
		for (let j = i + 1; j < points.length; j++)
			if (Math.hypot(points[i].x - points[j].x, points[i].y - points[j].y) <= DEDUP_DISTANCE)
				union(i, j);

	const groups = {};
	for (let i = 0; i < points.length; i++) {
		const r = find(i);
		(groups[r] = groups[r] || []).push(points[i]);
	}

	return Object.values(groups).map(cluster => ({
		type: cluster[0].type,
		mapID: cluster[0].mapID,
		name: cluster[0].name,
		x: cluster.reduce((s, p) => s + p.x, 0) / cluster.length,
		y: cluster.reduce((s, p) => s + p.y, 0) / cluster.length,
	}));
}

// dedupeByDistance only ever compares distance, not name -- callers must
// pre-group by name (see main()) so it never merges two different
// dungeons/raids that happen to have entrances near each other.

// Set of continent names declared via Twm_mapareas["<Continent>"] in a
// mapdata_continents.lua.
function extractContinentNames(luaText) {
	const names = new Set();
	const re = /Twm_mapareas\["([^"]+)"\]\s*=\s*\{/g;
	let m;
	while ((m = re.exec(luaText)))
		names.add(m[1]);
	return names;
}

function parseArgs(argv) {
	const opts = { flavorDir: null, teleportCsv: null, mapareasFile: null, out: null };
	for (let i = 0; i < argv.length; i++) {
		const a = argv[i];
		if (a === '--flavor-dir') opts.flavorDir = argv[++i];
		else if (a === '--teleport-csv') opts.teleportCsv = argv[++i];
		else if (a === '--mapareas-file') opts.mapareasFile = argv[++i];
		else if (a === '--out') opts.out = argv[++i];
		else throw new Error(`Unknown option: ${a}`);
	}
	return opts;
}

function printUsage() {
	console.error('Usage: node gen_poi_instances.js --flavor-dir <dir with AreaTrigger.*.csv and Map.*.csv> --teleport-csv <areatrigger_teleport.csv> --mapareas-file <target flavor mapdata_continents.lua> --out <out-file.lua>');
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

	if (!opts.flavorDir || !opts.teleportCsv || !opts.mapareasFile || !opts.out) {
		printUsage();
		process.exit(1);
	}

	const areaTriggerRows = parseCsvFile(findCsv(opts.flavorDir, 'AreaTrigger.'));
	const mapRows = parseCsvFile(findCsv(opts.flavorDir, 'Map.'));
	const teleportRows = parseCsvFile(opts.teleportCsv);
	const continentNames = extractContinentNames(fs.readFileSync(opts.mapareasFile, 'utf8'));

	const mapByID = {};
	for (const r of mapRows) mapByID[r.ID] = r;

	const teleByID = {};
	for (const r of teleportRows) teleByID[r.id] = r;

	const byContinent = {};
	let matched = 0, noContinentMap = 0, noTeleport = 0, notInstance = 0;

	for (const at of areaTriggerRows) {
		const contMapRow = mapByID[at.ContinentID];
		const contName = contMapRow && contMapRow.Directory;
		if (!contName || !continentNames.has(contName)) {
			noContinentMap++;
			continue;
		}

		const tele = teleByID[at.ID];
		if (!tele) {
			noTeleport++;
			continue;
		}

		const targetMap = mapByID[tele.target_map];
		if (!targetMap || (targetMap.InstanceType !== '1' && targetMap.InstanceType !== '2')) {
			notInstance++;
			continue;
		}

		const type = targetMap.InstanceType === '2' ? 'Raid' : 'Dungeon';
		const list = byContinent[contName] || (byContinent[contName] = []);
		list.push({ type, mapID: tele.target_map, name: targetMap.MapName_lang, x: parseFloat(at.Pos_1), y: parseFloat(at.Pos_0) });
		matched++;
	}

	console.error(`${matched} entrance triggers matched (${noContinentMap} not on an open-world continent, ${noTeleport} no --teleport-csv row, ${notInstance} teleport target isn't a dungeon/raid)`);

	let fullOutput = "-- GENERATED FILE -- do not hand-edit, regenerate with scripts/gen_poi_instances.js\n"
		+ "-- and replace this file wholesale. See scripts/README.md for details.\n"
		+ "--\n"
		+ "-- Dungeon/raid entrance markers, derived from AreaTrigger.db2 joined\n"
		+ "-- against a teleport-target reference table. See scripts/README.md for\n"
		+ "-- the generator's --teleport-csv input. Name is a fallback only --\n"
		+ "-- sets/dungeons.lua resolves the live name via GetRealZoneText(MapID).\n\n"
		+ "Twm_instances = {\n";

	for (const contName of Object.keys(byContinent).sort()) {
		const byName = {};
		for (const p of byContinent[contName])
			(byName[p.name] = byName[p.name] || []).push(p);
		const deduped = Object.values(byName).flatMap(dedupeByDistance);
		deduped.sort((a, b) => a.name.localeCompare(b.name));

		fullOutput += `    ["${contName}"] = {\n`;
		for (const e of deduped) {
			const name = e.name.replace(/"/g, '\\"');
			fullOutput += `        {"${e.type}", ${e.mapID}, "${name}", ${e.x.toFixed(2)}, ${e.y.toFixed(2)}},\n`;
		}
		fullOutput += '    },\n';
	}
	fullOutput += '}\n';

	fs.writeFileSync(opts.out, fullOutput);
	console.error(`Written: ${opts.out}`);
}

main();
