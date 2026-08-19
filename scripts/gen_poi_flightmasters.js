// Regenerates Data_<Flavor>/mapdata_poi_flightmasters.lua's Twm_flightmasters
// (marker positions + faction + per-locale names), Twm_taxipaths (raw route
// graph), and Twm_taxipathnodes (real curved route shapes) from TaxiNodes.db2
// joined against TaxiPath.db2 and TaxiPathNode.db2.
//
// Each Twm_flightmasters entry is a table with named fields --
// {id, faction, name = {enUS = ..., deDE = ..., ...}, x, y} -- rather than
// the positional {field1, field2, ...} arrays every other Twm_poi_* table
// uses, specifically to fit the per-locale name table in cleanly. name is
// keyed by client locale because, unlike Landmarks/Capitals/Dungeons (see
// architecture.md's live-name-resolution section), a flight master has no
// AreaID/MapID of its own to resolve a live, locale-correct name from at
// render time -- every locale's name has to be baked in here instead, from
// TaxiNodes.db2 fetched once per locale (wago.tools:
// /db2/TaxiNodes/csv?product=<product>&locale=<locale>, see --locales-dir).
//
// Faction ("Alliance"/"Horde"/"Neutral"):
// TaxiNodes.Flags is a bitmask, bit 0x1 = usable by Alliance, bit 0x2 =
// usable by Horde (confirmed empirically against known-faction hubs, e.g.
// Stormwind/Ironforge = 1, Undercity/Tarren Mill = 2). Both bits set (3)
// means "usable by both factions" -- confirmed against the Eastern
// Plaguelands faction-war towers -- mapped to "Neutral". Flags == 0
// (neither bit) is NOT treated as Neutral -- see isRealFlightPoint below,
// it's dropped entirely instead, since in practice it only ever showed up
// on junk/duplicate rows in this data, never a genuinely reachable node
// that wasn't also covered by a proper Flags 1/2/3 row.
//
// Junk rows: TaxiNodes.db2 also carries a lot of rows that aren't real,
// player-choosable flight points -- boat/zeppelin dock waypoints ("Transport,
// ..."), scripted one-off quest flights ("Quest Path ...: ..."), a dev-only
// island ("Programmer Isle"), and generic scripted targets ("Generic, ...").
// Filtered out by a name-prefix heuristic (see JUNK_NAME_RE) -- confirmed by
// eyeballing every row in Vanilla's ~87-row table; no known false positives,
// but this is a heuristic, not something Map/AreaTable-style data backs up,
// so double-check the "N junk rows skipped" count against the table's total
// row count if this is ever re-run against a very different client build.
//
// Positions use the same {bigX, bigY} = {Pos_1, Pos_0} convention as
// AreaTrigger in gen_poi_instances.js (raw world coords ARE Big coords,
// just axis-swapped, no zone-box percentage math needed here). Each
// marker's TaxiNode ID is kept (the `id` field) so Lua can join it back
// against Twm_taxipaths.
//
// Twm_taxipaths is the raw TaxiPath.db2 table (id, from, to), filtered only
// to rows where BOTH endpoints survived the junk/continent filter above --
// deliberately NOT deduped (A->B and B->A can both exist as separate rows
// for the same real route) and NOT restricted to same-continent pairs.
// That's left to a runtime pass (see TaxiRoutes.lua) that builds both a
// per-node neighbor list (for the hover-preview line display) and a
// deduped per-continent route list (for the "always show" toggle) --
// dedup has to happen after the join since it depends on which pairs
// actually resolve to the same continent, which is runtime-only info.
//
// Twm_taxipathnodes holds TaxiPathNode.db2's actual spline points, keyed by
// TaxiPath.ID and ordered by NodeIndex -- only for PathIDs that survived
// into Twm_taxipaths above, so junk/filtered routes don't drag their spline
// data along. FlightPaths.lua draws the straight endpoint-to-endpoint line
// by default and only walks this curved spline while Shift is held (holding
// Shift is the toggle for "show the real flight path shape" -- see
// sets/flightmasters.lua's tooltip and FlightPaths.lua for the rendering
// side).

const fs = require('fs');
const { parseCsvFile, findCsv } = require('./csv');

// Client locales TaxiNodes.Name_lang is fetched for (wago.tools:
// /db2/TaxiNodes/csv?product=<product>&locale=<locale>) -- flight masters
// have no live-resolvable name API (unlike Landmarks/Capitals/Dungeons,
// see architecture.md's live-name-resolution section), so every locale's
// name has to be baked in at generation time instead. enUS is also the
// structural source of truth (Flags/CharacterBitNumber/Pos/ContinentID are
// identical across locale exports -- only Name_lang differs), so it's
// required; the rest are optional per-locale name overlays.
const LOCALES = ['enUS', 'deDE', 'esES', 'esMX', 'frFR', 'itIT', 'koKR', 'ptBR', 'ruRU', 'zhCN', 'zhTW'];

const JUNK_NAME_RE = /^(Transport,|Quest Path\b|Generic\b|Programmer Isle)/i;

// A node with neither faction bit set (Flags & 3 == 0) or with
// CharacterBitNumber == 0 is dropped -- CharacterBitNumber is which bit of
// the player's "known taxi nodes" bitmask this node occupies once unlocked;
// 0 turned out to mean "not a real, individually-unlockable flight point"
// (confirmed: junk rows like "Northshire Abbey"/"Naxxramas"/"Southshore
// Ferry" all have it, alongside a redundant zero-flags duplicate of the
// real Booty Bay node that already exists separately with Flags 1 and 2).
// Trade-off: this also drops a few rows that otherwise looked legitimate --
// the Eastern Plaguelands faction-war towers and one of the two "Nighthaven,
// Moonglade" entries all have Flags == 3 (a real faction-restriction value)
// but CharacterBitNumber == 0 too, so they're excluded as well.
function isRealFlightPoint(n) {
	const flags = parseInt(n.Flags, 10) || 0;
	if ((flags & 3) === 0) return false;
	if ((parseInt(n.CharacterBitNumber, 10) || 0) === 0) return false;
	return true;
}

function extractContinentNames(luaText) {
	const names = new Set();
	const re = /Twm_mapareas\["([^"]+)"\]\s*=\s*\{/g;
	let m;
	while ((m = re.exec(luaText)))
		names.add(m[1]);
	return names;
}

function factionFor(flagsStr) {
	const flags = parseInt(flagsStr, 10) || 0;
	const alliance = (flags & 1) !== 0;
	const horde = (flags & 2) !== 0;
	if (alliance && !horde) return 'Alliance';
	if (horde && !alliance) return 'Horde';
	return 'Neutral';
}

function parseArgs(argv) {
	const opts = { flavorDir: null, localesDir: null, mapareasFile: null, out: null };
	for (let i = 0; i < argv.length; i++) {
		const a = argv[i];
		if (a === '--flavor-dir') opts.flavorDir = argv[++i];
		else if (a === '--locales-dir') opts.localesDir = argv[++i];
		else if (a === '--mapareas-file') opts.mapareasFile = argv[++i];
		else if (a === '--out') opts.out = argv[++i];
		else throw new Error(`Unknown option: ${a}`);
	}
	return opts;
}

function printUsage() {
	console.error('Usage: node gen_poi_flightmasters.js --flavor-dir <dir with TaxiPath.*.csv, TaxiPathNode.*.csv and Map.*.csv> --locales-dir <dir with TaxiNodes.<locale>.csv for each of ' + LOCALES.join('/') + '> --mapareas-file <target flavor mapdata_continents.lua> --out <out-file.lua>');
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

	if (!opts.flavorDir || !opts.localesDir || !opts.mapareasFile || !opts.out) {
		printUsage();
		process.exit(1);
	}

	// enUS is both a name locale AND the structural source of truth --
	// Flags/CharacterBitNumber/Pos/ContinentID are identical across every
	// locale's export of the same DB2 row, only Name_lang differs.
	const taxiNodeRows = parseCsvFile(findCsv(opts.localesDir, 'TaxiNodes.enUS.'));
	const taxiPathRows = parseCsvFile(findCsv(opts.flavorDir, 'TaxiPath.'));
	const taxiPathNodeRows = parseCsvFile(findCsv(opts.flavorDir, 'TaxiPathNode.'));
	const mapRows = parseCsvFile(findCsv(opts.flavorDir, 'Map.'));
	const continentNames = extractContinentNames(fs.readFileSync(opts.mapareasFile, 'utf8'));

	// Name_lang for every other locale, keyed by TaxiNode ID -- missing
	// locale files are skipped with a warning rather than a hard failure,
	// so a partial locale set still produces usable (just less-translated)
	// output instead of nothing.
	const namesByLocale = {};
	for (const locale of LOCALES) {
		if (locale === 'enUS') continue;
		let rows;
		try {
			rows = parseCsvFile(findCsv(opts.localesDir, `TaxiNodes.${locale}.`));
		} catch (e) {
			console.error(`Skipping ${locale}: ${e.message}`);
			continue;
		}
		const byID = {};
		for (const r of rows) byID[r.ID] = r.Name_lang;
		namesByLocale[locale] = byID;
	}

	const mapByID = {};
	for (const r of mapRows) mapByID[r.ID] = r;

	// Surviving nodes only, keyed by TaxiNode ID -- TaxiPath edges reference
	// junk/off-continent nodes too, and both endpoints must have survived
	// for a route to be drawable.
	const nodeByID = {};
	const byContinent = {};
	let kept = 0, junkSkipped = 0, notRealSkipped = 0, noContinentSkipped = 0;

	for (const n of taxiNodeRows) {
		if (JUNK_NAME_RE.test(n.Name_lang)) {
			junkSkipped++;
			continue;
		}

		if (!isRealFlightPoint(n)) {
			notRealSkipped++;
			continue;
		}

		const contMapRow = mapByID[n.ContinentID];
		const contName = contMapRow && contMapRow.Directory;
		if (!contName || !continentNames.has(contName)) {
			noContinentSkipped++;
			continue;
		}

		const x = parseFloat(n.Pos_1), y = parseFloat(n.Pos_0);
		const names = { enUS: n.Name_lang };
		for (const locale of Object.keys(namesByLocale)) {
			const localized = namesByLocale[locale][n.ID];
			if (localized) names[locale] = localized;
		}
		const entry = { id: n.ID, continent: contName, faction: factionFor(n.Flags), names, x, y };
		nodeByID[n.ID] = entry;
		(byContinent[contName] = byContinent[contName] || []).push(entry);
		kept++;
	}

	console.error(`${kept} flight masters kept (${junkSkipped} junk rows skipped, ${notRealSkipped} failed the faction-flags/CharacterBitNumber check, ${noContinentSkipped} not on an open-world continent)`);

	// Raw TaxiPath rows, filtered only to pairs where both endpoints
	// survived the junk/continent filter above -- no dedup, no
	// continent-matching. See this file's header for why.
	const paths = [];
	let pathsKept = 0, pathsMissingNode = 0;

	for (const p of taxiPathRows) {
		if (!nodeByID[p.FromTaxiNode] || !nodeByID[p.ToTaxiNode]) {
			pathsMissingNode++;
			continue;
		}
		paths.push({ id: p.ID, from: p.FromTaxiNode, to: p.ToTaxiNode });
		pathsKept++;
	}

	console.error(`${pathsKept} flight paths kept (${pathsMissingNode} referenced a filtered-out node)`);

	// Spline points, grouped by PathID and ordered by NodeIndex -- only for
	// PathIDs that survived into `paths` above.
	const keptPathIDs = new Set(paths.map(p => p.id));
	const nodesByPath = {};
	let splineNodesKept = 0, splineNodesSkipped = 0;

	for (const n of taxiPathNodeRows) {
		if (!keptPathIDs.has(n.PathID)) {
			splineNodesSkipped++;
			continue;
		}
		(nodesByPath[n.PathID] = nodesByPath[n.PathID] || []).push(n);
		splineNodesKept++;
	}
	for (const pid in nodesByPath) {
		nodesByPath[pid].sort((a, b) => parseInt(a.NodeIndex, 10) - parseInt(b.NodeIndex, 10));
	}

	console.error(`${splineNodesKept} spline points kept across ${Object.keys(nodesByPath).length} paths (${splineNodesSkipped} belonged to a filtered-out path)`);

	let fullOutput = "-- GENERATED FILE -- do not hand-edit, regenerate with scripts/gen_poi_flightmasters.js\n"
		+ "-- and replace this file wholesale. See scripts/README.md for details.\n"
		+ "--\n"
		+ "-- Flight master markers, derived from TaxiNodes.db2. Faction is baked in\n"
		+ "-- (\"Alliance\"/\"Horde\"/\"Neutral\") since flight masters have no live-\n"
		+ "-- resolvable API of their own to re-derive it from at render time. name is\n"
		+ "-- keyed by client locale (enUS/deDE/esES/esMX/frFR/itIT/koKR/ptBR/ruRU/\n"
		+ "-- zhCN/zhTW) for the same reason -- unlike Landmarks/Capitals/Dungeons\n"
		+ "-- (see architecture.md's live-name-resolution section), a flight master has\n"
		+ "-- no AreaID/MapID of its own to resolve a live name from, so every locale's\n"
		+ "-- name has to be baked in here instead; TaxiRoutes.lua picks the current\n"
		+ "-- client's own locale at load time, falling back to enUS if that locale is\n"
		+ "-- missing (e.g. enGB/ptPT clients, which aren't fetched separately -- see\n"
		+ "-- LOCALE_ALIASES there).\n\n"
		+ "Twm_flightmasters = {\n";

	for (const contName of Object.keys(byContinent).sort()) {
		const list = byContinent[contName].slice().sort((a, b) => a.names.enUS.localeCompare(b.names.enUS));
		fullOutput += `    ["${contName}"] = {\n`;
		for (const e of list) {
			fullOutput += `        {\n`;
			fullOutput += `            id = ${e.id},\n`;
			fullOutput += `            faction = "${e.faction}",\n`;
			fullOutput += `            name = {\n`;
			for (const locale of LOCALES) {
				if (!e.names[locale]) continue;
				const name = e.names[locale].replace(/\\/g, '\\\\').replace(/"/g, '\\"');
				fullOutput += `                ${locale} = "${name}",\n`;
			}
			fullOutput += `            },\n`;
			fullOutput += `            x = ${e.x.toFixed(2)},\n`;
			fullOutput += `            y = ${e.y.toFixed(2)},\n`;
			fullOutput += `        },\n`;
		}
		fullOutput += '    },\n';
	}
	fullOutput += '}\n\n';

	fullOutput += "-- Raw TaxiPath.db2 rows -- {ID, FromTaxiNode, ToTaxiNode} -- deliberately\n"
		+ "-- undeduped and not grouped by continent (see this file's header);\n"
		+ "-- TaxiRoutes.lua builds the actual per-node/per-continent lookup tables\n"
		+ "-- from this at load time.\n\n"
		+ "Twm_taxipaths = {\n";
	for (const e of paths) {
		fullOutput += `    {${e.id}, ${e.from}, ${e.to}},\n`;
	}
	fullOutput += '}\n\n';

	fullOutput += "-- TaxiPathNode.db2's real spline points per TaxiPath.ID, ordered by\n"
		+ "-- NodeIndex -- {x, y} in Big coords, same convention as everything else in\n"
		+ "-- this file. Only used for the curved-route display (hold Shift -- see\n"
		+ "-- FlightPaths.lua); the straight-line default only needs each route's two\n"
		+ "-- endpoints, already in Twm_flightmasters above.\n\n"
		+ "Twm_taxipathnodes = {\n";
	for (const pid of Object.keys(nodesByPath).sort((a, b) => parseInt(a, 10) - parseInt(b, 10))) {
		fullOutput += `    [${pid}] = {\n`;
		for (const n of nodesByPath[pid]) {
			const x = parseFloat(n.Loc_1).toFixed(2), y = parseFloat(n.Loc_0).toFixed(2);
			fullOutput += `        {${x}, ${y}},\n`;
		}
		fullOutput += '    },\n';
	}
	fullOutput += '}\n';

	fs.writeFileSync(opts.out, fullOutput);
	console.error(`Written: ${opts.out}`);
}

main();
