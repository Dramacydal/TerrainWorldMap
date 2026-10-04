// Regenerates Data_<Flavor>/mapdata_arenas.lua (Twm_mapareas entries for
// each arena, plus Twm_ArenaNames) from Map.csv DBC data plus an already-
// generated mapdata_tiles_<kind>.lua. See README.md for usage.
//
// Unlike battlegrounds, an arena has ZERO UiMapAssignment rows at all
// (confirmed on TBC and Mists: every arena MapID matches zero rows,
// checked directly, not just zero Zone-type ones) -- Blizzard never wired
// arenas into the World Map system, even though their terrain is real (a
// full WDT/ADT tile grid, same as any other map). That means:
//   - no UiMapID at all for an arena, so no Twm_ArenaMapID/position
//     tracking/TWM_GetContinentForMapID hint -- selecting one from the
//     dropdown is the only way to view it.
//   - no Region box to read a box from either -- this script instead
//     derives one from --tiles-file's already-computed
//     Twm_WDTValidTiles["<arena>"] (run parse_wdt.js on the arena's own
//     Directory name first, same as any other continent/battleground),
//     converting the tile index range through TWM_Mini2Big_Coord's own
//     formula (TerrainWorldMap.lua) -- x/y = (index-32)*-533.3333 -- since
//     that's the same conversion WorldMapOverlay.lua's DrawTiles already
//     uses to place each tile, so the derived box lines up with the tiles
//     it's meant to bound.
//   - no live uiMapID to resolve a client-locale name from either (unlike
//     Twm_BattlegroundMapID's C_Map.GetMapInfo(uiMapID).name) -- names are
//     baked in per client locale here instead, same reason and same shape
//     as gen_poi_flightmasters.js's Twm_flightmasters name tables:
//     TerrainWorldMap.lua resolves the current client's locale from this at
//     load time (TWM_ResolveLocaleName, TaxiRoutes.lua) to build the actual
//     TWM_ARENAS dropdown table, falling back to enUS same as flight
//     masters do.

const fs = require('fs');
const path = require('path');
const { parseCsvFile: parseCsv, findCsv } = require('./csv');
const { INSTANCE_TYPE_ARENA } = require('./dbc_enums');
const { flavorDir, ensureDb2Csv, envOr, readCandidates } = require('./extract');
const { skipMaps, isSkipped } = require('./skip_lists');
const { tileBoundsFor, wmoTileBoundsFor } = require('./tile_bounds');

const MINI2BIG = 1600 / 3; // 533.3333..., matches TerrainWorldMap.lua's MINI2BIGX/Y
function miniToBig(v) { return (v - 32) * -MINI2BIG; }

// Client locales Map.csv's MapName_lang is fetched for (wago.tools:
// /db2/Map/csv?product=<product>&locale=<locale>, self-downloaded per locale) --
// same set gen_poi_flightmasters.js uses for TaxiNodes.
const LOCALES = ['enUS', 'deDE', 'esES', 'esMX', 'frFR', 'itIT', 'koKR', 'ptBR', 'ruRU', 'zhCN', 'zhTW'];

// A standalone arena: Map.csv row with ParentMapID=-1 (top-level), MapType=1,
// InstanceType=INSTANCE_TYPE_ARENA -- same structural shape as
// gen_battlegrounds.js's battleground filter, minus the UiMapAssignment
// zone-row requirement (arenas have none to require). Also excludes anything
// hand-listed in skip_lists.js's skipMaps for this flavor -- see that file's
// own header for what it's for (this was documented there as already
// applying here, but never actually was until now).
function findArenas(mapRows, flavor) {
	return mapRows
		.filter(r => r.ParentMapID === '-1' && r.MapType === '1' && r.InstanceType === INSTANCE_TYPE_ARENA)
		.filter(r => !isSkipped(skipMaps, flavor, r.ID))
		.map(r => ({ key: r.Directory, mapID: r.ID, names: { enUS: r.MapName_lang } }));
}

function parseArgs(argv) {
	const opts = { workDir: null, flavor: null, tilesFile: null, wmoTilesFile: null, out: null, force: false, proxy: null };
	for (let i = 0; i < argv.length; i++) {
		const a = argv[i];
		if (a === '--work-dir') opts.workDir = argv[++i];
		else if (a === '--flavor') opts.flavor = argv[++i];
		else if (a === '--tiles-file') opts.tilesFile = argv[++i];
		else if (a === '--wmo-tiles-file') opts.wmoTilesFile = argv[++i];
		else if (a === '--out') opts.out = argv[++i];
		else if (a === '--force') opts.force = true;
		else if (a === '--proxy') opts.proxy = argv[++i];
		else throw new Error(`Unknown option: ${a}`);
	}
	return opts;
}

function printUsage() {
	console.error('Usage: node gen_arenas.js --work-dir <dir> --flavor <product> --tiles-file <mapdata_tiles_arenas.lua, from parse_wdt.js --candidates arenas> [--wmo-tiles-file <mapdata_wmo_tiles_arenas.lua, from gen_wmo_tiles.js --candidates arenas>] --out <out-file.lua> [--force] [--proxy <url>]');
	console.error('  An arena with no valid ADT tile (skip_lists.js\'s skipAdtTiles) gets its box from --wmo-tiles-file\'s tile corners instead.');
	console.error('  Requires scripts/gen_candidates.js to have been run first (reads candidates/arenas.json for its own candidate list).');
	console.error('  Map.<locale>.csv is self-downloaded for each of ' + LOCALES.join('/') + '.');
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

	if (!opts.workDir || !opts.flavor || !opts.tilesFile || !opts.out) {
		printUsage();
		process.exit(1);
	}

	const dl = { workDir: opts.workDir, flavor: opts.flavor, force: opts.force, proxy: opts.proxy };
	ensureDb2Csv({ ...dl, table: 'Map' });
	for (const locale of LOCALES)
		ensureDb2Csv({ ...dl, table: 'Map', locale });
	const flavorDirPath = flavorDir(opts.workDir, opts.flavor);
	const localesDir = path.join(flavorDirPath, 'locales');

	const mapRows = parseCsv(findCsv(flavorDirPath, 'Map.'));
	const tilesLua = fs.readFileSync(opts.tilesFile, 'utf8');
	const wmoTilesLua = opts.wmoTilesFile ? fs.readFileSync(opts.wmoTilesFile, 'utf8') : null;

	// Candidate discovery/filtering (structural Map.csv filter + skipMaps)
	// happens exactly once, in gen_candidates.js's own findArenas call --
	// this script just looks each candidate's own Map.csv row back up by ID
	// (for its locale-independent fields: Directory/enUS name) instead of
	// re-running the same filter against Map.csv a second time.
	const byID = {};
	for (const r of mapRows) byID[r.ID] = r;
	const candidates = readCandidates(opts.workDir, opts.flavor, 'arenas').map(c => {
		const r = byID[c.id];
		if (!r) {
			console.error(`WARNING: candidates/arenas.json has ${c.key} (ID=${c.id}) but it's no longer in Map.csv -- stale candidates file? Re-run gen_candidates.js. Skipping.`);
			return null;
		}
		return { key: r.Directory, mapID: r.ID, names: { enUS: r.MapName_lang } };
	}).filter(Boolean);
	console.error(`${candidates.length} arena Map rows found:`, candidates.map(a => `${a.key} (${a.names.enUS}, MapID=${a.mapID})`));

	// Name_lang for every other locale, keyed by Map ID -- missing locale
	// files are skipped with a warning rather than a hard failure, same as
	// gen_poi_flightmasters.js.
	for (const locale of LOCALES) {
		if (locale === 'enUS') continue;
		let rows;
		try {
			rows = parseCsv(findCsv(localesDir, `Map.${locale}.`));
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

	const arenas = [];
	for (const a of candidates) {
		const bounds = tileBoundsFor(tilesLua, a.key);
		if (bounds) {
			const box = {
				x1: miniToBig(bounds.colMin), x2: miniToBig(bounds.colMax + 1),
				y1: miniToBig(bounds.rowMin), y2: miniToBig(bounds.rowMax + 1),
			};
			arenas.push({ ...a, box, tileCount: bounds.count });
			continue;
		}
		// No valid ADT tile (e.g. skipAdtTiles): the extent of its WMO tiles.
		const wmoBounds = wmoTilesLua && wmoTileBoundsFor(wmoTilesLua, a.key);
		if (wmoBounds) {
			const { x1, x2, y1, y2, count } = wmoBounds;
			arenas.push({ ...a, box: { x1, x2, y1, y2 }, tileCount: count });
			continue;
		}
		console.error(`  (skipping ${a.key} "${a.names.enUS}" -- no Twm_WDTValidTiles entry in --tiles-file and no WMO tiles in --wmo-tiles-file; regenerate them with ${a.key} included first)`);
	}
	console.error(`${arenas.length} arenas with usable tile data.`);

	let fullOutput = "-- GENERATED FILE -- do not hand-edit, regenerate with scripts/gen_arenas.js\n"
		+ "-- and replace this file wholesale. See scripts/README.md for details.\n"
		+ "--\n"
		+ "-- Arena zone boxes, kept deliberately separate from Twm_ContinentMapID/\n"
		+ "-- TWM_MAPS and Twm_BattlegroundMapID/TWM_BATTLEGROUNDS (see this script's\n"
		+ "-- header) -- own \"Arenas\" dropdown category. No Twm_ArenaMapID table:\n"
		+ "-- arenas have no UiMapID at all (unlike battlegrounds), so there's no\n"
		+ "-- position tracking or continent-hint lookup to back with one.\n"
		+ "-- Twm_mapareas is the same generic per-map-name box registry every other\n"
		+ "-- top-level map category already populates, just derived from valid-tile\n"
		+ "-- extent (Big coordinates, via TWM_Mini2Big_Coord's own formula) instead\n"
		+ "-- of a UiMapAssignment Region box, which doesn't exist for these.\n"
		+ "-- Twm_ArenaNames is resolved into the actual TWM_ARENAS dropdown table at\n"
		+ "-- load time (TerrainWorldMap.lua), same as Twm_flightmasters' name\n"
		+ "-- tables (TaxiRoutes.lua) -- see this file's own header comment.\n\n"
		+ "Twm_ArenaNames = {\n";
	for (const a of arenas.slice().sort((x, y) => x.names.enUS.localeCompare(y.names.enUS))) {
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

	for (const a of arenas)
		fullOutput += `Twm_mapareas["${a.key}"] = {\n    [0] = {${a.box.x1}, ${a.box.x2}, ${a.box.y1}, ${a.box.y2}},    --${a.names.enUS.replace(/[^A-Za-z0-9']/g, '')}\n}\n`;

	fs.writeFileSync(opts.out, fullOutput);
	console.error(`\nWritten: ${opts.out}`);
}

module.exports = { findArenas };
if (require.main === module) { main(); }
