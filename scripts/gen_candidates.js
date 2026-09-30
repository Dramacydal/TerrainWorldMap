// Writes <work-dir>/<flavor>/candidates/{continents,battlegrounds,arenas,
// dungeons,raids,scenarios}.json -- the single, one-time-per-flavor source
// of "which maps exist in this category" that parse_wdt.js/gen_wmo_tiles.js/
// gen_poi_areas.js/gen_area_centroids.js's own --candidates <kind> reads
// instead of requiring an explicit map list on every invocation. Run this
// BEFORE any of those, once per flavor -- see README.md for the full
// pipeline order.
//
// Doesn't re-implement any filtering logic -- imports the exact same
// findContinents/findBattlegrounds/findArenas/findCandidates functions
// gen_mapareas.js/gen_battlegrounds.js/gen_arenas.js/gen_instance_maps.js
// already use for their own output, so there's exactly one place each
// category's filter rules live (this script would silently drift from
// those otherwise).
//
// Each JSON file is an array of {id, key} (plus one category-specific
// extra field where it's already known for free -- see below), NOT a
// plain string array: `key` is Map.csv's own Directory (what every
// consumer actually needs for a CASC path/Lua table key -- same thing
// this codebase already calls a map's `key` everywhere else), `id` is
// Map.csv's own ID (same thing skip_lists.js keys its own lists on) --
// kept so a consumer can cross-reference back to Map.csv/skip_lists.js
// without re-parsing Map.csv just to recover an ID it already had at
// generation time. Extra fields: dungeons/raids/scenarios carry
// `expansion` (Map.csv's ExpansionID -- TerrainWorldMap.lua's own
// expansion-selection dropdown needs exactly this), battlegrounds carries
// `uiMapID` (findBattlegrounds already resolves it for live position
// tracking). Empty array (not a missing file) for a category with no
// candidates at all on this flavor (e.g. TBC's own scenarios.json).

const { parseCsvFile: parseCsv, findCsv } = require('./csv');
const { flavorDir, envOr, ensureDb2Csv, writeCandidates } = require('./extract');
const { findContinents } = require('./gen_mapareas');
const { findBattlegrounds } = require('./gen_battlegrounds');
const { findArenas } = require('./gen_arenas');
const { findCandidates, KINDS } = require('./gen_instance_maps');

function parseArgs(argv) {
	const opts = { workDir: null, flavor: null, force: false, proxy: null };
	for (let i = 0; i < argv.length; i++) {
		const a = argv[i];
		if (a === '--work-dir') opts.workDir = argv[++i];
		else if (a === '--flavor') opts.flavor = argv[++i];
		else if (a === '--force') opts.force = true;
		else if (a === '--proxy') opts.proxy = argv[++i];
		else throw new Error(`Unknown option: ${a}`);
	}
	return opts;
}

function printUsage() {
	console.error('Usage: node gen_candidates.js --work-dir <dir> --flavor <product> [--force] [--proxy <url>]');
	console.error('  Writes <work-dir>/<flavor>/candidates/{continents,battlegrounds,arenas,dungeons,raids,scenarios}.json.');
	console.error('  Run this once per flavor, before parse_wdt.js/gen_wmo_tiles.js/gen_poi_areas.js/gen_area_centroids.js.');
}

// gen_instance_maps.js's own KINDS[kind].candidatesFile is the single
// source of truth for the singular (--kind value) -> plural (JSON filename)
// mapping -- both this script and gen_instance_maps.js's own main() (which
// reads candidates/<candidatesFile>.json back) need the exact same mapping.
const INSTANCE_KINDS = Object.entries(KINDS).map(([kind, k]) => ({ kind, file: k.candidatesFile }));

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

	if (!opts.workDir || !opts.flavor) {
		printUsage();
		process.exit(1);
	}

	const dl = { workDir: opts.workDir, flavor: opts.flavor, force: opts.force, proxy: opts.proxy };
	const csvDir = flavorDir(opts.workDir, opts.flavor);
	ensureDb2Csv({ ...dl, table: 'Map' });
	ensureDb2Csv({ ...dl, table: 'UiMap' });
	ensureDb2Csv({ ...dl, table: 'UiMapAssignment' });

	const mapRows = parseCsv(findCsv(csvDir, 'Map.'));
	const uiMapRows = parseCsv(findCsv(csvDir, 'UiMap.'));
	const assignRows = parseCsv(findCsv(csvDir, 'UiMapAssignment.'));

	const uiMapType = {};
	const uiMapSystem = {};
	for (const r of uiMapRows) {
		uiMapType[r.ID] = r.Type;
		uiMapSystem[r.ID] = r.System;
	}

	const continents = findContinents(uiMapRows, assignRows, mapRows, uiMapType, uiMapSystem)
		.map(c => ({ id: c.mapID, key: c.name }));
	writeCandidates(opts.workDir, opts.flavor, 'continents', continents);
	console.error(`continents.json: ${continents.length} (${continents.map(c => c.key).join(', ')})`);

	const battlegrounds = findBattlegrounds(mapRows, assignRows, opts.flavor)
		.map(b => ({ id: b.mapID, key: b.key, uiMapID: b.uiMapID }));
	writeCandidates(opts.workDir, opts.flavor, 'battlegrounds', battlegrounds);
	console.error(`battlegrounds.json: ${battlegrounds.length} (${battlegrounds.map(b => b.key).join(', ')})`);

	const arenas = findArenas(mapRows, opts.flavor)
		.map(a => ({ id: a.mapID, key: a.key }));
	writeCandidates(opts.workDir, opts.flavor, 'arenas', arenas);
	console.error(`arenas.json: ${arenas.length} (${arenas.map(a => a.key).join(', ')})`);

	for (const { kind, file } of INSTANCE_KINDS) {
		const entries = findCandidates(mapRows, KINDS[kind].instanceType, opts.flavor)
			.map(c => ({ id: c.mapID, key: c.key, expansion: c.expansion }));
		writeCandidates(opts.workDir, opts.flavor, file, entries);
		console.error(`${file}.json: ${entries.length} (${entries.map(c => c.key).join(', ')})`);
	}

	console.error(`\nWritten to ${flavorDir(opts.workDir, opts.flavor)}\\candidates\\`);
}

main();
