// Regenerates Data_<Flavor>/mapdata_dungeons.lua / mapdata_raids.lua /
// mapdata_scenarios.lua (Twm_mapareas entries for each map, plus
// Twm_DungeonNames/Twm_RaidNames/Twm_ScenarioNames) from Map.csv DBC data
// plus an already-generated mapdata_tiles_<kind>.lua. See README.md for usage.
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
const { flavorDir, listfilePath, ensureDb2Csv, ensureExtracted, ensureExtractedPaths, envOr, readCandidates } = require('./extract');
const { skipMaps, isSkipped } = require('./skip_lists');
const { tileBoundsFor, wmoTileBoundsFor } = require('./tile_bounds');

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

const escapeRegExp = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

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
//
// Pure local reads, no extraction -- callers must ensureExtracted() the
// map's own WDT (and, once its MODF nameId is known, the WMO root file)
// THEMSELVES first, batched across every candidate map. Extracting per-map
// one at a time here would mean one CASCConsole subprocess launch per
// candidate (each with its own ~20s CASC/listfile startup cost) -- fine for
// a single test map, but ruinous across dozens of dungeon/raid candidates
// at once (confirmed: hung for 20+ minutes on a full Mists dungeon run
// before this was split out of the loop).
function boxFromWdtGlobalPlacement(flavorDirPath, mapName, idToPath) {
	const wdtRelPath = path.join('world', 'maps', mapName, `${mapName}.wdt`);
	const modf = findWdtGlobalPlacement(path.join(flavorDirPath, wdtRelPath));
	if (!modf) return null;
	const wmoPath = idToPath[modf.nameId];
	if (!wmoPath) return null;

	const localWmoPath = path.join(flavorDirPath, wmoPath);
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
// /db2/Map/csv?product=<product>&locale=<locale>, self-downloaded per locale) --
// same set gen_arenas.js/gen_poi_flightmasters.js use.
const LOCALES = ['enUS', 'deDE', 'esES', 'esMX', 'frFR', 'itIT', 'koKR', 'ptBR', 'ruRU', 'zhCN', 'zhTW'];

// Tables the alias names come from (see addAliases).
const ALIAS_TABLES = ['LFGDungeons', 'AreaTable'];

// Other names a map is known by, for comparing only (the displayed name stays
// Map.csv's MapName_lang): the names the dungeon finder gives it (LFGDungeons,
// by MapID) and the names of its top-level areas (AreaTable, ContinentID =
// Map ID, no parent area) -- "The Black Morass" for Map.csv's "Opening of the
// Dark Portal". A trailing "(Heroic)"-like note is dropped, and so is a name
// equal to the map's own. Sets `a.alias = { <locale> = [names] }`.
function addAliases(candidates, localesDir) {
	for (const locale of LOCALES) {
		let lfgRows, areaRows;
		try {
			lfgRows = parseCsv(findCsv(localesDir, `LFGDungeons.${locale}.`));
			areaRows = parseCsv(findCsv(localesDir, `AreaTable.${locale}.`));
		} catch (e) {
			console.error(`Skipping aliases for ${locale}: ${e.message}`);
			continue;
		}
		for (const a of candidates) {
			const names = [];
			const add = (name) => {
				name = (name || '').replace(/\s*\([^)]*\)\s*$/, '').trim();
				if (!name || name.toLowerCase() === (a.names[locale] || '').toLowerCase()) return;
				if (!names.some(n => n.toLowerCase() === name.toLowerCase())) names.push(name);
			};
			for (const r of lfgRows) if (r.MapID === a.mapID) add(r.Name_lang);
			for (const r of areaRows) if (r.ContinentID === a.mapID && r.ParentAreaID === '0') add(r.AreaName_lang);
			if (names.length > 0) (a.alias = a.alias || {})[locale] = names;
		}
	}
}

// candidatesFile is this kind's own candidates/<file>.json (gen_candidates.js)
// -- plural, unlike --kind's own singular value, matching
// continents/battlegrounds/arenas' own natural plural filenames.
const KINDS = {
	dungeon: { instanceType: INSTANCE_TYPE_INSTANCE, namesVar: 'Twm_DungeonNames', label: 'dungeon', candidatesFile: 'dungeons' },
	raid: { instanceType: INSTANCE_TYPE_RAID, namesVar: 'Twm_RaidNames', label: 'raid', candidatesFile: 'raids' },
	scenario: { instanceType: INSTANCE_TYPE_SCENARIO, namesVar: 'Twm_ScenarioNames', label: 'scenario', candidatesFile: 'scenarios' },
};

// A standalone dungeon/raid/scenario: Map.csv row with ParentMapID=-1
// (top-level), InstanceType matching --kind. Deliberately NOT filtered by
// MapType=1 the way gen_arenas.js/gen_battlegrounds.js/gen_mapareas.js
// filter their own candidates -- Map.csv's MapType column is unrelated to
// InstanceType and is NOT a reliable "is this a real top-level map" signal
// for dungeons specifically (confirmed: Ragefire Chasm's own MapType is 2,
// Shadowfang Keep's is 1, despite both being ordinary InstanceType=1
// dungeons) -- InstanceType + ParentMapID=-1 is already precise enough on
// its own. Also excludes anything hand-listed in skip_lists.js's skipMaps
// for this flavor -- see that file's own header for what it's for.
function findCandidates(mapRows, instanceType, flavor) {
	return mapRows
		.filter(r => r.ParentMapID === '-1' && r.InstanceType === instanceType)
		.filter(r => !/unused/i.test(r.MapName_lang))
		.filter(r => !isSkipped(skipMaps, flavor, r.ID))
		.map(r => ({ key: r.Directory, mapID: r.ID, expansion: r.ExpansionID, names: { enUS: r.MapName_lang } }));
}

function parseArgs(argv) {
	const opts = {
		kind: null, workDir: null, flavor: null, clientDir: null, online: false, clientLocale: 'enUS',
		tilesFile: null, wmoTilesFile: null, out: null, force: false, proxy: null,
	};
	for (let i = 0; i < argv.length; i++) {
		const a = argv[i];
		if (a === '--kind') opts.kind = argv[++i];
		else if (a === '--work-dir') opts.workDir = argv[++i];
		else if (a === '--flavor') opts.flavor = argv[++i];
		else if (a === '--client-dir') opts.clientDir = argv[++i];
		else if (a === '--online') opts.online = true;
		else if (a === '--client-locale') opts.clientLocale = argv[++i];
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
	console.error('Usage: node gen_instance_maps.js --kind dungeon|raid|scenario --work-dir <dir> --flavor <product> (--client-dir <path> | --online) --tiles-file <mapdata_tiles_<kind>.lua, from parse_wdt.js --candidates <kind>> [--wmo-tiles-file <mapdata_wmo_tiles_<kind>.lua, from gen_wmo_tiles.js --candidates <kind>>] --out <out-file.lua> [--force] [--proxy <url>]');
	console.error('  Requires scripts/gen_candidates.js to have been run first (reads candidates/<dungeons|raids|scenarios>.json for its own candidate list).');
	console.error('  Map.<locale>.csv is self-downloaded for each of ' + LOCALES.join('/') + '.');
	console.error('  A pure-WMO map (no Twm_WDTValidTiles entry) prefers a box derived from --wmo-tiles-file\'s own real tile corners (matches what actually renders); falls back to self-extracting its WDT + WMO root file to derive a coarser one only when no WMO tile data exists for it either.');
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

	opts.workDir = envOr(opts.workDir, 'WORK_DIR');
	opts.clientDir = envOr(opts.clientDir, 'CLIENT_DIR');
	opts.flavor = envOr(opts.flavor, 'FLAVOR');
	opts.proxy = envOr(opts.proxy, 'PROXY');

	if (!opts.kind || !KINDS[opts.kind] || !opts.workDir || !opts.flavor || !opts.tilesFile || !opts.out) {
		printUsage();
		process.exit(1);
	}
	const kind = KINDS[opts.kind];

	const extractOpts = {
		workDir: opts.workDir, flavor: opts.flavor,
		clientDir: opts.clientDir, online: opts.online, clientLocale: opts.clientLocale,
		force: opts.force,
	};
	const dl = { ...extractOpts, proxy: opts.proxy };
	ensureDb2Csv({ ...dl, table: 'Map' });
	for (const locale of LOCALES)
		ensureDb2Csv({ ...dl, table: 'Map', locale });
	for (const table of ALIAS_TABLES)
		for (const locale of LOCALES)
			ensureDb2Csv({ ...dl, table, locale });
	const flavorDirPath = flavorDir(opts.workDir, opts.flavor);
	const localesDir = path.join(flavorDirPath, 'locales');

	const mapRows = parseCsv(findCsv(flavorDirPath, 'Map.'));
	const tilesLua = fs.readFileSync(opts.tilesFile, 'utf8');
	const wmoTilesLua = opts.wmoTilesFile ? fs.readFileSync(opts.wmoTilesFile, 'utf8') : null;

	// Candidate discovery/filtering (structural Map.csv filter + skipMaps)
	// happens exactly once, in gen_candidates.js's own findCandidates call --
	// this script just looks each candidate's own Map.csv row back up by ID
	// (for its locale-independent fields: Directory/enUS name/ExpansionID)
	// instead of re-running the same filter against Map.csv a second time.
	const byID = {};
	for (const r of mapRows) byID[r.ID] = r;
	const candidates = readCandidates(opts.workDir, opts.flavor, kind.candidatesFile).map(c => {
		const r = byID[c.id];
		if (!r) {
			console.error(`WARNING: candidates/${kind.candidatesFile}.json has ${c.key} (ID=${c.id}) but it's no longer in Map.csv -- stale candidates file? Re-run gen_candidates.js. Skipping.`);
			return null;
		}
		return { key: r.Directory, mapID: r.ID, expansion: c.expansion, names: { enUS: r.MapName_lang } };
	}).filter(Boolean);
	console.error(`${candidates.length} ${kind.label} Map rows found:`, candidates.map(a => `${a.key} (${a.names.enUS}, MapID=${a.mapID}, ExpansionID=${a.expansion})`));

	// Name_lang for every other locale, keyed by Map ID -- missing locale
	// files are skipped with a warning rather than a hard failure, same as
	// gen_arenas.js/gen_poi_flightmasters.js.
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

	addAliases(candidates, localesDir);

	// nameId -> WMO path, for the pure-WMO fallback below only (candidates
	// that DO have tile data never touch this).
	const idToPath = {};
	const rl = readline.createInterface({ input: fs.createReadStream(listfilePath(opts.workDir)) });
	for await (const line of rl) {
		const idx = line.indexOf(';');
		if (idx === -1) continue;
		idToPath[parseInt(line.slice(0, idx), 10)] = line.slice(idx + 1).trim();
	}

	// Split by whether --tiles-file already has real tile-extent data before
	// touching CASCConsole at all -- most dungeons/raids are a single global
	// WMO with no ADT tile grid (unlike arenas, which always have real
	// terrain), so the pure-WMO fallback below is the common case, not the
	// exception, once MapType stops being used to filter candidates.
	const withBounds = [], noBounds = [], wmoBoxed = [];
	for (const a of candidates) {
		const bounds = tileBoundsFor(tilesLua, a.key);
		if (bounds) { withBounds.push({ a, bounds }); continue; }
		// Prefer --wmo-tiles-file's own real tile corners over re-deriving a
		// box from the WMO's MOHD bounding box below -- see wmoTileBoundsFor's
		// header. Also means no WDT/WMO-root extraction is needed at all for
		// these, since the answer's already sitting in an already-generated
		// file.
		const wmoBounds = wmoTilesLua && wmoTileBoundsFor(wmoTilesLua, a.key);
		if (wmoBounds) { wmoBoxed.push({ a, bounds: wmoBounds }); continue; }
		noBounds.push(a);
	}

	// Batch phase 1: every no-bounds candidate's own WDT, in ONE CASCConsole
	// call -- not one subprocess launch per candidate (each launch pays its
	// own ~20s CASC/listfile startup cost; this hung for 20+ minutes on a
	// full Mists dungeon run, most of which have no tile-file entry, before
	// this was batched).
	if (noBounds.length > 0) {
		const wdtRelPaths = noBounds.map(a => path.join('world', 'maps', a.key, `${a.key}.wdt`));
		ensureExtracted({
			...extractOpts,
			pattern: `^(${noBounds.map(a => `world/maps/${escapeRegExp(a.key)}/${escapeRegExp(a.key)}\\.wdt`).join('|')})$`,
			checkPaths: wdtRelPaths,
		});
	}

	// Now that every candidate's WDT is local, resolve which ones actually
	// have a pure-WMO global placement (pure local reads, no extraction),
	// and batch phase 2: every one of THEIR WMO root files, again in ONE
	// CASCConsole call. (flavorDirPath already declared above, near the
	// Map.csv read.)
	const modfByKey = {};
	for (const a of noBounds) {
		const wdtRelPath = path.join('world', 'maps', a.key, `${a.key}.wdt`);
		const modf = findWdtGlobalPlacement(path.join(flavorDirPath, wdtRelPath));
		if (!modf) continue;
		const wmoPath = idToPath[modf.nameId];
		if (!wmoPath) continue;
		modfByKey[a.key] = { modf, wmoPath };
	}
	const neededWmoPaths = [...new Set(Object.values(modfByKey).map(m => m.wmoPath))];
	if (neededWmoPaths.length > 0) {
		// ensureExtractedPaths, not a hand-built alternation -- see
		// gen_wmo_tiles.js's own equivalent fix (ENAMETOOLONG at scale).
		ensureExtractedPaths({ ...extractOpts, paths: neededWmoPaths });
	}

	const found = [];
	for (const { a, bounds } of withBounds) {
		const box = {
			x1: miniToBig(bounds.colMin), x2: miniToBig(bounds.colMax + 1),
			y1: miniToBig(bounds.rowMin), y2: miniToBig(bounds.rowMax + 1),
		};
		found.push({ ...a, box, tileCount: bounds.count });
	}
	for (const { a, bounds } of wmoBoxed) {
		found.push({ ...a, box: bounds, tileCount: bounds.count });
	}
	for (const a of noBounds) {
		// Neither ADT tiles (--tiles-file) nor WMO tiles (--wmo-tiles-file) --
		// nothing would be drawn, so the map is not listed at all. Only when a
		// --wmo-tiles-file was given: without one the absence of a WMO entry
		// proves nothing.
		if (wmoTilesLua) {
			console.error(`  (skipping ${a.key} "${a.names.enUS}" -- no ADT tiles and no WMO tiles, nothing to show)`);
			continue;
		}
		const m = modfByKey[a.key];
		const box = m && boxFromWdtGlobalPlacement(flavorDirPath, a.key, idToPath);
		if (!box) {
			console.error(`  (skipping ${a.key} "${a.names.enUS}" -- no Twm_WDTValidTiles entry, no --wmo-tiles-file entry, AND no pure-WMO WDT-level placement found; regenerate --tiles-file/--wmo-tiles-file with ${a.key} included, or check it manually)`);
			continue;
		}
		console.error(`  (${a.key} "${a.names.enUS}" -- using a coarse box from the WMO's own MOHD bounding box; no --wmo-tiles-file entry to derive a more precise one from, since it has no baked WMO minimap tiles at all)`);
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
		+ "-- top-level map category already populates, derived from (in preference\n"
		+ "-- order): valid-tile extent (Big coordinates, via TWM_Mini2Big_Coord's\n"
		+ "-- own formula) when a real ADT tile grid exists; the union of\n"
		+ "-- Twm_WMOTiles' own real tile corners (--wmo-tiles-file) for a pure-WMO\n"
		+ "-- map (most dungeons/raids: a single global WMO, no ADT grid at all)\n"
		+ "-- that has baked WMO minimap tiles -- guaranteed to match what actually\n"
		+ "-- renders, since it's the same corner data; or, only when neither is\n"
		+ "-- available, a coarser box from the WMO's own MOHD bounding box placed\n"
		+ "-- by the WDT-level MODF -- see boxFromWdtGlobalPlacement's header. Only\n"
		+ "-- the last of these depends on baked minimap art NOT existing --\n"
		+ "-- Vanilla has none at all, so its dungeons/raids always use this path.\n"
		+ `-- ${kind.namesVar} is resolved into the actual TWM_${kind.label.toUpperCase()}S dropdown\n`
		+ "-- table at load time (TerrainWorldMap.lua), same as Twm_ArenaNames/\n"
		+ "-- Twm_flightmasters' name tables -- see this file's own header comment.\n"
		+ "-- `mapID` is Map.csv's own ID (a string) -- used by per-flavor visibility\n"
		+ "-- lists such as Twm_SeasonOnlyMaps (Data_Vanilla/mapdata_seasons.lua).\n"
		+ "-- `alias` ({ <locale> = {names} }, optional) are other names the map is known\n"
		+ "-- by (dungeon finder, top-level area names) -- only for comparing, never shown.\n"
		+ "-- `expansion` is Map.csv's own ExpansionID (a string, like every other ID\n"
		+ "-- in this codebase) -- drives the expansion-selection dropdown level\n"
		+ "-- TerrainWorldMap.lua inserts between this category and the actual list.\n\n"
		+ `${kind.namesVar} = {\n`;
	for (const a of found.slice().sort((x, y) => x.names.enUS.localeCompare(y.names.enUS))) {
		fullOutput += `    {\n`;
		fullOutput += `        key = "${a.key}",\n`;
		fullOutput += `        mapID = "${a.mapID}",\n`;
		fullOutput += `        expansion = "${a.expansion}",\n`;
		fullOutput += `        name = {\n`;
		for (const locale of LOCALES) {
			if (!a.names[locale]) continue;
			const name = a.names[locale].replace(/\\/g, '\\\\').replace(/"/g, '\\"');
			fullOutput += `            ${locale} = "${name}",\n`;
		}
		fullOutput += `        },\n`;
		if (a.alias) {
			fullOutput += `        alias = {\n`;
			for (const locale of LOCALES) {
				if (!a.alias[locale]) continue;
				const list = a.alias[locale].map(n => `"${n.replace(/\\/g, '\\\\').replace(/"/g, '\\"')}"`).join(', ');
				fullOutput += `            ${locale} = {${list}},\n`;
			}
			fullOutput += `        },\n`;
		}
		fullOutput += `    },\n`;
	}
	fullOutput += "}\n\n";

	for (const a of found)
		fullOutput += `Twm_mapareas["${a.key}"] = {\n    [0] = {${a.box.x1}, ${a.box.x2}, ${a.box.y1}, ${a.box.y2}},    --${a.names.enUS.replace(/[^A-Za-z0-9']/g, '')}\n}\n`;

	fs.writeFileSync(opts.out, fullOutput);
	console.error(`\nWritten: ${opts.out}`);
}

module.exports = { findCandidates, KINDS };
if (require.main === module) { main().catch(e => { console.error(e); process.exit(1); }); }
