// Regenerates Data_<Flavor>/mapdata_poi_areas.lua's Twm_poi_areas from
// AreaTable's own zone hierarchy instead of Blizzard's AreaPOI DB2 (which
// turned out to use a numeric Icon atlas index that shifts between client
// builds, plus assorted non-settlement noise -- see scripts/README.md's
// history for gen_towns.js, which this replaces). See README.md for usage.
//
// Algorithm:
//   A = the AreaIDs this continent actually displays (the keys of
//       Twm_mapareas["<Continent>"] in the flavor's own generated
//       mapdata_continents.lua, minus the [0] whole-map sentinel).
//   B = every AreaTable row whose parent chain (ParentAreaID, walked all
//       the way up) passes through some zone in A -- i.e. every real
//       sub-area/POI nested anywhere under a displayed zone -- PLUS every
//       top-level AreaID (ParentAreaID 0) not already in A, e.g. Northrend's
//       Dalaran, which has no Twm_mapareas box at all (this build has no
//       dedicated UiMapAssignment zone row for it) but is real terrain with
//       real ADT chunks. This is how a capital city with no zone box of its
//       own still gets a usable position -- see sets/capitals.lua, which
//       looks up a capital's AreaID here as a fallback when Twm_mapareas
//       has no box for it.
//   Twm_poi_areas gets B, positioned via each AreaID's own centroid
//   (average MCNK chunk position across every root ADT of this
//   continent -- see gen_area_centroids.js, same computation, duplicated
//   here to keep this script self-contained). Each entry is
//   {AreaID, "Name", x, y} -- the AreaID lets other code (sets/capitals.lua)
//   match an entry back to a known AreaID instead of just a display name.
//
// An AreaID in B with no matching centroid (never actually painted on any
// ADT chunk in this build) is silently skipped -- it exists in AreaTable
// but isn't real terrain here.
//
// Known caveat: this also picks up large non-settlement sub-areas whose
// ParentAreaID happens to point at a displayed zone -- e.g. "The Great
// Sea"/"The Veiled Sea" (open ocean, tens of thousands of chunks spread
// along the whole coastline). These aren't filtered out; if they show up
// as a stray point in open water, prune them by name/AreaID by hand or
// ask for an automatic filter.
//
// Phased-copy filter: some sub-areas' AreaID is painted on TWO disjoint,
// far-apart tile clusters in the same ADT set -- confirmed for Outland's
// Draenei starting zone (Ammen Vale/Emberglade/The Sacred Grove under
// Azuremyst Isle), which has a near-identical-sized duplicate copy of its
// own terrain elsewhere on the Outland map (almost certainly a private
// copy used only during the starting-zone intro/crash-landing sequence).
// Averaging both blindly lands the centroid in the ocean, between the two.
// Fix: chunks are only counted toward a sub-area's centroid if they fall
// within its resolved top-level zone's own Twm_mapareas box, padded by a
// margin scaled to that zone's own size (half its smaller dimension,
// clamped to [PADDING_MIN, PADDING_MAX]) rather than a flat distance --
// generous enough for legitimate edge overshoot on a small zone without
// needing a margin so large it'd also tolerate a real duplicate-copy on
// a huge zone. Actual duplicate-copy separations seen so far (~5000-10000+
// yards) are comfortably beyond even the PADDING_MAX ceiling.

const fs = require('fs');
const path = require('path');
const { parseCsvFile, findCsv } = require('./csv');
const { flavorDir, ensureDb2Csv, ensureExtracted, envOr, resolveMapKeys } = require('./extract');

const TILE_SIZE = 1600 / 3; // 533.33333...
const CHUNK_SIZE = TILE_SIZE / 16; // 33.33333...
const MAP_ORIGIN = 32 * TILE_SIZE; // 17066.66666...
const PADDING_FRACTION = 0.5; // of the box's smaller dimension
const PADDING_MIN = 500; // yards
const PADDING_MAX = 3000; // yards

function chunkID(a, b, c, d) {
	return (a.charCodeAt(0) << 24) | (b.charCodeAt(0) << 16) | (c.charCodeAt(0) << 8) | d.charCodeAt(0);
}

const ID_MCNK = chunkID('M', 'C', 'N', 'K');
const AREAID_OFFSET = 0x34;
const INDEXX_OFFSET = 0x04;
const INDEXY_OFFSET = 0x08;

function loadAreaTable(areaTableDir) {
	const rows = parseCsvFile(findCsv(areaTableDir, 'AreaTable.'));
	const parentOf = {};
	const nameOf = {};
	for (const r of rows) {
		parentOf[r.ID] = parseInt(r.ParentAreaID, 10);
		nameOf[r.ID] = r.AreaName_lang;
	}
	return { parentOf, nameOf, allIDs: rows.map(r => r.ID) };
}

// True if any ancestor of id (NOT including id itself) is in `zoneSet`.
function hasAncestorIn(id, zoneSet, parentOf) {
	let cur = id;
	let guard = 0;
	while (guard < 10) {
		const parent = parentOf[cur];
		if (!parent) return false;
		if (zoneSet.has(String(parent))) return true;
		cur = parent;
		guard++;
	}
	return false;
}

function resolveToZone(areaID, parentOf) {
	let id = areaID;
	let guard = 0;
	while (guard < 10) {
		const parent = parentOf[id];
		if (!parent) break;
		id = parent;
		guard++;
	}
	return id;
}

// {areaID: [x1, x2, y1, y2]} ({maxX, minX, maxY, minY}) for every zone box
// in Twm_mapareas["<Continent>"].
function extractMapareasBoxes(luaText, contName) {
	const marker = `Twm_mapareas["${contName}"] = {`;
	const start = luaText.indexOf(marker);
	if (start === -1) return {};
	const end = luaText.indexOf('\n}', start);
	const block = luaText.slice(start, end === -1 ? undefined : end);

	const boxes = {};
	const re = /\[(\d+)\]\s*=\s*\{([^}]+)\}/g;
	let m;
	while ((m = re.exec(block)))
		boxes[m[1]] = m[2].split(',').map(s => parseFloat(s));
	return boxes;
}

// False only when the box is known AND the point falls outside it (padded
// per zoneBoxPadding() below) -- i.e. "known to be a phased-copy chunk".
// Unknown/no box always passes (nothing to filter against).
function zoneBoxPadding(box) {
	const [x1, x2, y1, y2] = box;
	const smaller = Math.min(x1 - x2, y1 - y2);
	return Math.min(PADDING_MAX, Math.max(PADDING_MIN, smaller * PADDING_FRACTION));
}

function withinKnownBox(bigX, bigY, areaID, parentOf, zoneBoxes) {
	const box = zoneBoxes[resolveToZone(areaID, parentOf)];
	if (!box) return true;
	const [x1, x2, y1, y2] = box;
	const padding = zoneBoxPadding(box);
	return bigX <= x1 + padding && bigX >= x2 - padding
		&& bigY <= y1 + padding && bigY >= y2 - padding;
}

function chunkToBig(col, row, indexX, indexY) {
	const bigX = MAP_ORIGIN - col * TILE_SIZE - (indexX + 0.5) * CHUNK_SIZE;
	const bigY = MAP_ORIGIN - row * TILE_SIZE - (indexY + 0.5) * CHUNK_SIZE;
	return { bigX, bigY };
}

function accumulateAdt(filePath, col, row, sums, parentOf, zoneBoxes) {
	const buf = fs.readFileSync(filePath);
	let offset = 0;
	let skipped = 0;

	while (offset + 8 <= buf.length) {
		const magic = buf.readUInt32LE(offset);
		const size = buf.readUInt32LE(offset + 4);
		const dataStart = offset + 8;

		if (magic === ID_MCNK && dataStart + AREAID_OFFSET + 4 <= buf.length) {
			const indexX = buf.readUInt32LE(dataStart + INDEXX_OFFSET);
			const indexY = buf.readUInt32LE(dataStart + INDEXY_OFFSET);
			const areaID = buf.readUInt32LE(dataStart + AREAID_OFFSET);

			if (areaID) {
				const { bigX, bigY } = chunkToBig(col, row, indexX, indexY);
				if (withinKnownBox(bigX, bigY, areaID, parentOf, zoneBoxes)) {
					const s = sums[areaID] || (sums[areaID] = { sumX: 0, sumY: 0, count: 0 });
					s.sumX += bigX;
					s.sumY += bigY;
					s.count++;
				} else {
					skipped++;
				}
			}
		}

		offset = dataStart + size;
	}

	return skipped;
}

function centroidsForContinent(adtDir, parentOf, zoneBoxes) {
	const sums = {};
	let totalSkipped = 0;
	if (!fs.existsSync(adtDir))
		return { centroids: {}, totalSkipped };

	const re = /(?:^|_)(\d+)_(\d+)\.adt$/i;
	for (const f of fs.readdirSync(adtDir)) {
		const m = re.exec(f);
		if (!m) continue;
		totalSkipped += accumulateAdt(path.join(adtDir, f), parseInt(m[1], 10), parseInt(m[2], 10), sums, parentOf, zoneBoxes);
	}

	const centroids = {};
	for (const [areaID, s] of Object.entries(sums))
		centroids[areaID] = { x: s.sumX / s.count, y: s.sumY / s.count };
	return { centroids, totalSkipped };
}

// Set of Twm_mapareas["<Continent>"]'s AreaID keys (set A), excluding the
// [0] whole-map box sentinel (not a real AreaID).
function extractMapareasKeys(luaText, contName) {
	const marker = `Twm_mapareas["${contName}"] = {`;
	const start = luaText.indexOf(marker);
	if (start === -1) return null;
	const end = luaText.indexOf('\n}', start);
	const block = luaText.slice(start, end === -1 ? undefined : end);

	const keys = new Set();
	const re = /\[(\d+)\]\s*=\s*\{/g;
	let m;
	while ((m = re.exec(block))) {
		if (m[1] !== '0')
			keys.add(m[1]);
	}
	return keys;
}

const escapeRegExp = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

function parseArgs(argv) {
	const opts = {
		workDir: null, flavor: null, clientDir: null, online: false, clientLocale: 'enUS',
		out: null, areaTableDir: null, mapareasFile: null, force: false, proxy: null,
		maps: null, candidatesKind: null,
	};

	for (let i = 0; i < argv.length; i++) {
		const a = argv[i];
		if (a === '--work-dir') opts.workDir = argv[++i];
		else if (a === '--flavor') opts.flavor = argv[++i];
		else if (a === '--client-dir') opts.clientDir = argv[++i];
		else if (a === '--online') opts.online = true;
		else if (a === '--client-locale') opts.clientLocale = argv[++i];
		else if (a === '--out') opts.out = argv[++i];
		else if (a === '--areatable-dir') opts.areaTableDir = argv[++i];
		else if (a === '--mapareas-file') opts.mapareasFile = argv[++i];
		else if (a === '--force') opts.force = true;
		else if (a === '--proxy') opts.proxy = argv[++i];
		else if (a === '--maps') opts.maps = argv[++i];
		else if (a === '--candidates') opts.candidatesKind = argv[++i];
		else throw new Error(`Unknown option: ${a}`);
	}

	return opts;
}

function printUsage() {
	console.error('Usage: node gen_poi_areas.js --work-dir <dir> --flavor <product> (--client-dir <path> | --online) --mapareas-file <mapdata_continents.lua|mapdata_battlegrounds.lua> --out <out-file.lua> (--candidates <continents|battlegrounds> | --maps <Name1,Name2,...>) [--areatable-dir <dir>]');
	console.error('  --candidates reads <work-dir>/<flavor>/candidates/<kind>.json (scripts/gen_candidates.js, run that first) --');
	console.error('  continents for the usual pass, battlegrounds for the separate battleground-zone pass (--mapareas-file');
	console.error('  pointed at mapdata_battlegrounds.lua instead). --maps is an explicit comma-separated override.');
	console.error('  Root ADTs are self-extracted (via CASCConsole) if not already present under <work-dir>/<flavor>/world/...');
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
	opts.clientDir = envOr(opts.clientDir, 'CLIENT_DIR');
	opts.flavor = envOr(opts.flavor, 'FLAVOR');
	opts.proxy = envOr(opts.proxy, 'PROXY');

	if (!opts.workDir || !opts.flavor || !opts.out || !opts.mapareasFile) {
		printUsage();
		process.exit(1);
	}
	let continents;
	try {
		continents = resolveMapKeys({ maps: opts.maps, candidatesKind: opts.candidatesKind, workDir: opts.workDir, flavor: opts.flavor });
	} catch (e) {
		console.error(e.message);
		printUsage();
		process.exit(1);
	}
	if (continents.length === 0) {
		console.error(`No maps to process (candidates/${opts.candidatesKind}.json is empty) -- nothing to do.`);
		process.exit(0);
	}

	const flavorDirPath = flavorDir(opts.workDir, opts.flavor);
	const extractOpts = {
		workDir: opts.workDir, flavor: opts.flavor,
		clientDir: opts.clientDir, online: opts.online, clientLocale: opts.clientLocale,
		force: opts.force,
	};

	if (!opts.areaTableDir) {
		ensureDb2Csv({ ...extractOpts, table: 'AreaTable', proxy: opts.proxy });
		opts.areaTableDir = flavorDirPath;
	}

	for (const contName of continents) {
		const lower = escapeRegExp(contName.toLowerCase());
		ensureExtracted({
			...extractOpts,
			// [^/]+ (only excludes the path separator), not \w+ -- see
			// parse_wdt.js's own identical fix for why (a tile's filename can
			// embed a Directory stem containing a space/apostrophe).
			pattern: `^world/maps/${lower}/([^/]+\\.wdt|[^/]+_\\d+_\\d+\\.adt)$`,
			checkPaths: [path.join('world', 'maps', contName.toLowerCase(), `${contName.toLowerCase()}.wdt`)],
		});
	}

	const { parentOf, nameOf } = loadAreaTable(opts.areaTableDir);
	const mapareasLua = fs.readFileSync(opts.mapareasFile, 'utf8');

	// Per-key assignment (Twm_poi_areas["X"] = {...}), NOT a single
	// `Twm_poi_areas = {...}` literal -- this file can be regenerated/loaded
	// independently of other Twm_poi_areas producers (e.g. a separate
	// battlegrounds POI file alongside the continents' one) without one
	// clobbering the other's entries regardless of .toc load order.
	// Twm_poi_areas itself must already exist (declared in mapdata_zones.lua,
	// loaded before any per-continent/per-battleground data file).
	let fullOutput = "-- GENERATED FILE -- do not hand-edit, regenerate with scripts/gen_poi_areas.js\n"
		+ "-- and replace this file wholesale. See scripts/README.md for details.\n"
		+ "--\n"
		+ "-- Named sub-areas/POIs (Twm_poi_areas) nested under each of these zones'\n"
		+ "-- own displayed zones (Twm_mapareas), extracted from AreaTable's own\n"
		+ "-- parent hierarchy. Coordinates are each AreaID's own centroid (average\n"
		+ "-- MCNK chunk position across this client's ADT data).\n\n";

	for (const contName of continents) {
		const setA = extractMapareasKeys(mapareasLua, contName);
		if (!setA) {
			console.error(`WARNING: ${contName} not found in --mapareas-file -- skipping`);
			continue;
		}

		const lower = contName.toLowerCase();
		const adtDir = path.join(flavorDirPath, 'world', 'maps', lower);
		const zoneBoxes = extractMapareasBoxes(mapareasLua, contName);
		const { centroids, totalSkipped } = centroidsForContinent(adtDir, parentOf, zoneBoxes);

		// Battlegrounds (and similar single-zone maps) have no numbered
		// Twm_mapareas keys -- setA is empty, since there's no "displayed
		// sub-zone" tier the way a continent has. Widening the ancestor-match
		// target to every top-level AreaID (ParentAreaID 0) actually found in
		// this map's own ADT data -- not just setA -- lets a battleground's
		// own children (e.g. Alterac Valley/2597's Frostwolf Keep, Tower
		// Point, ...) resolve via hasAncestorIn; for a continent this only
		// adds coverage for an orphan top-level zone's own children, if any.
		const topLevelInCentroids = new Set(Object.keys(centroids).filter(id => !parentOf[id]));
		const ancestorSet = new Set([...setA, ...topLevelInCentroids]);

		// A flat map's own top-level AreaID (e.g. Alterac Valley/2597 on
		// PVPZone01) acts as the parent for its real sub-areas (Frostwolf
		// Keep, Tower Point, ...) found in this same scan -- i.e. it has
		// children here, unlike a genuine standalone landmark (e.g.
		// Northrend's Dalaran, usually childless). Excluded the same way a
		// continent's own displayed zones are (setA), so it doesn't show up
		// as a redundant POI duplicating the map's own title; its children
		// still resolve via ancestorSet above.
		const hasChildrenHere = id => Object.keys(centroids).some(other => other !== id && hasAncestorIn(other, new Set([id]), parentOf));

		const entries = [];
		for (const areaID of Object.keys(centroids)) {
			if (setA.has(areaID)) continue; // the zone itself, not a sub-area
			if (topLevelInCentroids.has(areaID) && hasChildrenHere(areaID)) continue;
			// A sub-area nested under a displayed zone (the usual case), OR a
			// top-level zone (ParentAreaID 0) that isn't itself displayed --
			// e.g. Northrend's Dalaran, which has no Twm_mapareas box at all
			// (no dedicated UiMapAssignment zone row in this build) but is
			// real terrain with real ADT chunks.
			const isTopLevel = !parentOf[areaID];
			if (!isTopLevel && !hasAncestorIn(areaID, ancestorSet, parentOf)) continue;
			const name = nameOf[areaID];
			if (!name) continue;
			entries.push({ areaID, name, ...centroids[areaID] });
		}
		entries.sort((a, b) => a.name.localeCompare(b.name));

		console.error(`${contName}: ${setA.size} displayed zones, ${entries.length} sub-area POIs found (${totalSkipped} phased-copy chunks excluded)`);

		fullOutput += `Twm_poi_areas["${contName}"] = {\n`;
		for (const e of entries) {
			const name = e.name.replace(/"/g, '\\"');
			fullOutput += `    {${e.areaID}, "${name}", ${e.x.toFixed(2)}, ${e.y.toFixed(2)}},\n`;
		}
		fullOutput += '}\n';
	}

	fs.writeFileSync(opts.out, fullOutput);
	console.error(`\nWritten: ${opts.out}`);
}

main();
