// Computes each AreaID's centroid (average chunk position) straight from
// this client's own root ADT/MCNK data. See README.md for usage.
//
// Unlike parse_wdt.js's getDominantAreaID() (majority-vote AreaID PER
// TILE, for Twm_WDTValidTiles), this aggregates every MCNK chunk of a
// given raw AreaID across an ENTIRE continent into one centroid -- keyed
// by raw AreaID as-is (sub-areas/POIs kept separate from their parent
// zone, not resolved up via ParentAreaID).
//
// World position per chunk: WoW's tile grid is 64x64 tiles of
// TILE_SIZE=533.33333 yards, each split into a 16x16 grid of
// CHUNK_SIZE=33.33333-yard MCNK chunks. MCNK's own IndexX/IndexY (header
// offset 0x04/0x08 -- stable across every ADT version, unlike offsets
// further into the header) give the chunk's position within its tile;
// the ADT filename's own two numbers give the tile's position in the
// world grid. Same axis convention already validated elsewhere in this
// codebase (ADT filename col/row <-> TerrainWorldMap tile-key col/row
// directly, no swap -- see parse_wdt.js's findAdtAreaIDs comment) and the
// same world<->Big transform gen_mapareas.js/gen_poi_areas.js use
// (Big-X = world Y, Big-Y = world X, no offset/scale).
//
// Self-check: rolls raw AreaIDs up to their top-level zone (ParentAreaID
// chain) purely for validation, and flags (stderr WARNING) any zone whose
// rolled-up centroid falls outside that zone's own Twm_mapareas bounding
// box -- if this ever fires, suspect the coordinate formula above, not
// the data.

const fs = require('fs');
const path = require('path');
const { parseCsvFile, findCsv } = require('./csv');

const MAP_SIZE = 64;
const TILE_SIZE = 1600 / 3; // 533.33333...
const CHUNK_SIZE = TILE_SIZE / 16; // 33.33333...
const MAP_ORIGIN = MAP_SIZE / 2 * TILE_SIZE; // 17066.66666...

function chunkID(a, b, c, d) {
	return (a.charCodeAt(0) << 24) | (b.charCodeAt(0) << 16) | (c.charCodeAt(0) << 8) | d.charCodeAt(0);
}

const ID_MCNK = chunkID('M', 'C', 'N', 'K');
const AREAID_OFFSET = 0x34;
const INDEXX_OFFSET = 0x04;
const INDEXY_OFFSET = 0x08;

function loadAreaParents(areaTableDir) {
	const rows = parseCsvFile(findCsv(areaTableDir, 'AreaTable.'));
	const parentOf = {};
	const nameOf = {};
	for (const r of rows) {
		parentOf[r.ID] = parseInt(r.ParentAreaID, 10);
		nameOf[r.ID] = r.AreaName_lang;
	}
	return { parentOf, nameOf };
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

// {bigX, bigY} for the given tile (col/row, from the ADT filename) and
// chunk (indexX/indexY, from the MCNK header) -- see header comment.
function chunkToBig(col, row, indexX, indexY) {
	const bigX = MAP_ORIGIN - col * TILE_SIZE - (indexX + 0.5) * CHUNK_SIZE;
	const bigY = MAP_ORIGIN - row * TILE_SIZE - (indexY + 0.5) * CHUNK_SIZE;
	return { bigX, bigY };
}

function accumulateAdt(filePath, col, row, sums) {
	const buf = fs.readFileSync(filePath);
	let offset = 0;

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
				const s = sums[areaID] || (sums[areaID] = { sumX: 0, sumY: 0, count: 0 });
				s.sumX += bigX;
				s.sumY += bigY;
				s.count++;
			}
		}

		offset = dataStart + size;
	}
}

function centroidsForContinent(adtDir) {
	const sums = {};
	if (!fs.existsSync(adtDir))
		return sums;

	const re = /(?:^|_)(\d+)_(\d+)\.adt$/i;
	for (const f of fs.readdirSync(adtDir)) {
		const m = re.exec(f);
		if (!m) continue;
		accumulateAdt(path.join(adtDir, f), parseInt(m[1], 10), parseInt(m[2], 10), sums);
	}

	const centroids = {};
	for (const [areaID, s] of Object.entries(sums))
		centroids[areaID] = { x: s.sumX / s.count, y: s.sumY / s.count, count: s.count };
	return centroids;
}

// Rolls raw centroids up to their top-level zone (count-weighted average)
// and checks the result falls inside that zone's own Twm_mapareas box --
// pure sanity check, not part of the output.
function selfCheck(contName, centroids, parentOf, mapareasLua) {
	const zoneBoxes = extractMapareasBoxes(mapareasLua, contName);
	if (!zoneBoxes) {
		console.error(`  (no Twm_mapareas["${contName}"] found for self-check -- skipping)`);
		return;
	}

	const rollup = {};
	for (const [areaID, c] of Object.entries(centroids)) {
		const zone = resolveToZone(parseInt(areaID, 10), parentOf);
		const r = rollup[zone] || (rollup[zone] = { sumX: 0, sumY: 0, count: 0 });
		r.sumX += c.x * c.count;
		r.sumY += c.y * c.count;
		r.count += c.count;
	}

	let checked = 0, warned = 0;
	for (const [zone, r] of Object.entries(rollup)) {
		const box = zoneBoxes[zone];
		if (!box) continue;
		const [x1, x2, y1, y2] = box; // {maxX, minX, maxY, minY}
		const x = r.sumX / r.count, y = r.sumY / r.count;
		checked++;
		if (x > x1 || x < x2 || y > y1 || y < y2) {
			warned++;
			console.error(`  WARNING: zone ${zone} rolled-up centroid (${x.toFixed(1)}, ${y.toFixed(1)}) falls outside its Twm_mapareas box [${x2},${x1}]x[${y2},${y1}]`);
		}
	}
	console.error(`  self-check: ${checked} zones checked against Twm_mapareas, ${warned} outside their box`);
}

function extractMapareasBoxes(luaText, contName) {
	const marker = `Twm_mapareas["${contName}"] = {`;
	const start = luaText.indexOf(marker);
	if (start === -1) return null;
	const end = luaText.indexOf('\n}', start);
	const block = luaText.slice(start, end === -1 ? undefined : end);

	const boxes = {};
	const re = /\[(\d+)\]\s*=\s*\{([^}]+)\}/g;
	let m;
	while ((m = re.exec(block))) {
		const areaID = m[1];
		const nums = m[2].split(',').map(s => parseFloat(s));
		boxes[areaID] = nums;
	}
	return boxes;
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
	console.error('Usage: node gen_area_centroids.js --flavor-dir <dir> --out <out-file.lua> [--areatable-dir <dir>] [--mapareas-file <mapdata_continents.lua>] <ContinentName> [<ContinentName> ...]');
	console.error('  --mapareas-file enables the Twm_mapareas bounding-box self-check (optional).');
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

	if (!opts.flavorDir || !opts.out || continents.length === 0) {
		printUsage();
		process.exit(1);
	}

	const { parentOf, nameOf } = loadAreaParents(opts.areaTableDir);
	const mapareasLua = opts.mapareasFile ? fs.readFileSync(opts.mapareasFile, 'utf8') : null;

	let fullOutput = "-- GENERATED FILE -- do not hand-edit, regenerate with scripts/gen_area_centroids.js\n"
		+ "-- and replace this file wholesale. See scripts/README.md for details.\n"
		+ "--\n"
		+ "-- Per-AreaID centroid (average MCNK chunk position), computed straight\n"
		+ "-- from this client's own ADT data. Keyed by raw AreaID (sub-areas/POIs\n"
		+ "-- kept separate from their parent zone).\n\n"
		+ "Twm_area_centroids = {\n";

	for (const contName of continents) {
		const lower = contName.toLowerCase();
		const adtDir = path.join(opts.flavorDir, 'world', 'maps', lower);
		const centroids = centroidsForContinent(adtDir);

		console.error(`${contName}: ${Object.keys(centroids).length} distinct AreaIDs`);
		if (mapareasLua)
			selfCheck(contName, centroids, parentOf, mapareasLua);

		fullOutput += `    ["${contName}"] = {\n`;
		for (const areaID of Object.keys(centroids).sort((a, b) => parseInt(a, 10) - parseInt(b, 10))) {
			const c = centroids[areaID];
			const name = (nameOf[areaID] || '?').replace(/[^A-Za-z0-9' ]/g, '');
			fullOutput += `        [${areaID}] = {${c.x.toFixed(2)}, ${c.y.toFixed(2)}},    --${name} (${c.count} chunks)\n`;
		}
		fullOutput += '    },\n';
	}

	fullOutput += '}\n';

	fs.writeFileSync(opts.out, fullOutput);
	console.error(`\nWritten: ${opts.out}`);
}

main();
