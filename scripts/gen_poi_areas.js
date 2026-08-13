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
//       sub-area/POI nested anywhere under a displayed zone.
//   Twm_poi_areas gets B, positioned via each AreaID's own centroid
//   (average MCNK chunk position across every root ADT of this
//   continent -- see gen_area_centroids.js, same computation, duplicated
//   here to keep this script self-contained).
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

function parseArgs(argv) {
	const opts = { flavorDir: null, out: null, areaTableDir: null, mapareasFile: null };
	const continents = [];

	for (let i = 0; i < argv.length; i++) {
		const a = argv[i];
		if (a === '--flavor-dir') opts.flavorDir = argv[++i];
		else if (a === '--out') opts.out = argv[++i];
		else if (a === '--areatable-dir') opts.areaTableDir = argv[++i];
		else if (a === '--mapareas-file') opts.mapareasFile = argv[++i];
		else if (a.startsWith('--')) throw new Error(`Unknown option: ${a}`);
		else continents.push(a);
	}

	if (opts.areaTableDir === null)
		opts.areaTableDir = opts.flavorDir;

	return { opts, continents };
}

function printUsage() {
	console.error('Usage: node gen_poi_areas.js --flavor-dir <dir> --mapareas-file <mapdata_continents.lua> --out <out-file.lua> [--areatable-dir <dir>] <ContinentName> [<ContinentName> ...]');
}

function main() {
	let opts, continents;
	try {
		({ opts, continents } = parseArgs(process.argv.slice(2)));
	} catch (e) {
		console.error(e.message);
		printUsage();
		process.exit(1);
	}

	if (!opts.flavorDir || !opts.out || !opts.mapareasFile || continents.length === 0) {
		printUsage();
		process.exit(1);
	}

	const { parentOf, nameOf } = loadAreaTable(opts.areaTableDir);
	const mapareasLua = fs.readFileSync(opts.mapareasFile, 'utf8');

	let fullOutput = "-- GENERATED FILE -- do not hand-edit, regenerate with scripts/gen_poi_areas.js\n"
		+ "-- and replace this file wholesale. See scripts/README.md for details.\n"
		+ "--\n"
		+ "-- Named sub-areas/POIs (Twm_poi_areas) nested under this continent's own\n"
		+ "-- displayed zones (Twm_mapareas), extracted from AreaTable's own parent\n"
		+ "-- hierarchy. Coordinates are each AreaID's own centroid (average MCNK\n"
		+ "-- chunk position across this client's ADT data).\n\n"
		+ "Twm_poi_areas = {\n";

	for (const contName of continents) {
		const setA = extractMapareasKeys(mapareasLua, contName);
		if (!setA) {
			console.error(`WARNING: ${contName} not found in --mapareas-file -- skipping`);
			continue;
		}

		const lower = contName.toLowerCase();
		const adtDir = path.join(opts.flavorDir, 'world', 'maps', lower);
		const zoneBoxes = extractMapareasBoxes(mapareasLua, contName);
		const { centroids, totalSkipped } = centroidsForContinent(adtDir, parentOf, zoneBoxes);

		const entries = [];
		for (const areaID of Object.keys(centroids)) {
			if (setA.has(areaID)) continue; // the zone itself, not a sub-area
			if (!hasAncestorIn(areaID, setA, parentOf)) continue;
			const name = nameOf[areaID];
			if (!name) continue;
			entries.push({ name, ...centroids[areaID] });
		}
		entries.sort((a, b) => a.name.localeCompare(b.name));

		console.error(`${contName}: ${setA.size} displayed zones, ${entries.length} sub-area POIs found (${totalSkipped} phased-copy chunks excluded)`);

		fullOutput += `    ["${contName}"] = {\n`;
		for (const e of entries) {
			const name = e.name.replace(/"/g, '\\"');
			fullOutput += `        {"${name}", ${e.x.toFixed(2)}, ${e.y.toFixed(2)}},\n`;
		}
		fullOutput += '    },\n';
	}

	fullOutput += '}\n';

	fs.writeFileSync(opts.out, fullOutput);
	console.error(`\nWritten: ${opts.out}`);
}

main();
