// One-off audit: for every WMO placement (MODF entry) on the given maps,
// transform the WMO's own MOHD bounding box through the placement's
// position/yaw and compare it with the MODF's baked world-space extents
// (center offset, width, height, all in Big coordinates). Sorted by the
// worst discrepancy. Read-only: nothing is extracted, missing files are
// reported and skipped.
const fs = require('fs');
const path = require('path');
const readline = require('readline');
const { flavorDir, listfilePath, readCandidates, envOr } = require('./extract');
const { getValidTiles } = require('./parse_wdt');

function chunkID(a, b, c, d) { return (a.charCodeAt(0) << 24) | (b.charCodeAt(0) << 16) | (c.charCodeAt(0) << 8) | d.charCodeAt(0); }
const ID_MPHD = chunkID('M', 'P', 'H', 'D');
const ID_MODF = chunkID('M', 'O', 'D', 'F');
const ID_MOHD = chunkID('M', 'O', 'H', 'D');

const MAP_ORIGIN = 32 * 1600 / 3;

function readModfEntry(buf, b) {
	return {
		nameId: buf.readUInt32LE(b),
		uniqueId: buf.readUInt32LE(b + 4),
		pos: [buf.readFloatLE(b + 8), buf.readFloatLE(b + 12), buf.readFloatLE(b + 16)],
		rot: [buf.readFloatLE(b + 20), buf.readFloatLE(b + 24), buf.readFloatLE(b + 28)],
		extents: {
			min: [buf.readFloatLE(b + 32), buf.readFloatLE(b + 36), buf.readFloatLE(b + 40)],
			max: [buf.readFloatLE(b + 44), buf.readFloatLE(b + 48), buf.readFloatLE(b + 52)],
		},
		flags: buf.readUInt16LE(b + 56),
		scale: buf.readUInt16LE(b + 62),
	};
}

// Every distinct placement (by uniqueId) across the map's real obj0 ADTs.
function findAllPlacements(mapDir, validTileKeys) {
	const out = [];
	const seen = new Set();
	for (const f of fs.readdirSync(mapDir)) {
		if (!f.endsWith('_obj0.adt')) continue;
		const m = f.match(/_(\d+)_(\d+)_obj0\.adt$/i);
		if (m && !validTileKeys.has(`${m[1].padStart(2, '0')}x${m[2].padStart(2, '0')}`)) continue;
		const buf = fs.readFileSync(path.join(mapDir, f));
		let offset = 0;
		while (offset + 8 <= buf.length) {
			const magic = buf.readUInt32LE(offset), size = buf.readUInt32LE(offset + 4), dataStart = offset + 8;
			if (magic === ID_MODF) {
				for (let i = 0; i < size / 64; i++) {
					const e = readModfEntry(buf, dataStart + i * 64);
					if (seen.has(e.uniqueId)) continue;
					seen.add(e.uniqueId);
					out.push(e);
				}
			}
			offset = dataStart + size;
		}
	}
	return out;
}

// Pure-WMO map: one global placement in the WDT, guarded by MPHD.flags & 1.
function findWdtPlacement(wdtPath) {
	if (!fs.existsSync(wdtPath)) return [];
	const buf = fs.readFileSync(wdtPath);
	let offset = 0, flags = 0, modf = null;
	while (offset + 8 <= buf.length) {
		const magic = buf.readUInt32LE(offset), size = buf.readUInt32LE(offset + 4), dataStart = offset + 8;
		if (magic === ID_MPHD) flags = buf.readUInt32LE(dataStart);
		else if (magic === ID_MODF && size >= 64) modf = readModfEntry(buf, dataStart);
		offset = dataStart + size;
	}
	if (!(flags & 0x1) || !modf) return [];
	modf.wdtLevel = true;
	return [modf];
}

function readMohdBbox(p) {
	const buf = fs.readFileSync(p);
	let offset = 0;
	while (offset + 8 <= buf.length) {
		const magic = buf.readUInt32LE(offset), size = buf.readUInt32LE(offset + 4), dataStart = offset + 8;
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

// Same yaw-only transform gen_wmo_tiles.js uses: local (x,y) -> Big (X,Y).
function localToBig(e, x, y) {
	const yaw = -e.rot[1] * Math.PI / 180;
	const c = Math.cos(yaw), s = Math.sin(yaw);
	const lx = y, ly = x;
	return [MAP_ORIGIN - e.pos[0] - (lx * c - ly * s), MAP_ORIGIN - e.pos[2] - (lx * s + ly * c)];
}

function compare(e, bbox) {
	const corners = [
		localToBig(e, bbox.min[0], bbox.min[1]), localToBig(e, bbox.min[0], bbox.max[1]),
		localToBig(e, bbox.max[0], bbox.max[1]), localToBig(e, bbox.max[0], bbox.min[1]),
	];
	const xs = corners.map(c => c[0]), ys = corners.map(c => c[1]);
	const pred = { cx: (Math.min(...xs) + Math.max(...xs)) / 2, cy: (Math.min(...ys) + Math.max(...ys)) / 2, w: Math.max(...xs) - Math.min(...xs), h: Math.max(...ys) - Math.min(...ys) };
	const ex = e.extents;
	const ext = {
		cx: MAP_ORIGIN - (ex.min[0] + ex.max[0]) / 2, cy: MAP_ORIGIN - (ex.min[2] + ex.max[2]) / 2,
		w: ex.max[0] - ex.min[0], h: ex.max[2] - ex.min[2],
	};
	const dx = ext.cx - pred.cx, dy = ext.cy - pred.cy;
	const dCenter = Math.hypot(dx, dy), dW = ext.w - pred.w, dH = ext.h - pred.h;
	const predZ = e.pos[1] + (bbox.min[2] + bbox.max[2]) / 2, extZ = (ex.min[1] + ex.max[1]) / 2;
	// A WDT-level global WMO has position 0 and extents == its raw model-space
	// box, so a center comparison is meaningless there -- size only.
	const score = e.wdtLevel ? Math.max(Math.abs(dW), Math.abs(dH)) : Math.max(dCenter, Math.abs(dW), Math.abs(dH));
	// Center delta expressed in the WMO's own local frame (inverse of localToBig's rotation).
	const yaw = -e.rot[1] * Math.PI / 180, c = Math.cos(yaw), s = Math.sin(yaw);
	const fx = -dx, fy = -dy;
	const locX = -fx * s + fy * c, locY = -(fx * c + fy * s);
	const bcx = (bbox.min[0] + bbox.max[0]) / 2, bcy = (bbox.min[1] + bbox.max[1]) / 2;
	return { dx, dy, dCenter, dW, dH, dZ: extZ - predZ, score, locX, locY, bcx, bcy };
}

function parseArgs(argv) {
	const opts = { workDir: null, flavor: null, kinds: 'dungeons,raids', maps: null, top: 40, out: null };
	for (let i = 0; i < argv.length; i++) {
		const a = argv[i];
		if (a === '--work-dir') opts.workDir = argv[++i];
		else if (a === '--flavor') opts.flavor = argv[++i];
		else if (a === '--candidates') opts.kinds = argv[++i];
		else if (a === '--maps') opts.maps = argv[++i];
		else if (a === '--top') opts.top = parseInt(argv[++i], 10);
		else if (a === '--out') opts.out = argv[++i];
		else throw new Error(`Unknown option: ${a}`);
	}
	return opts;
}

async function main() {
	let opts;
	try { opts = parseArgs(process.argv.slice(2)); } catch (e) {
		console.error(e.message);
		console.error('Usage: node audit_wmo_extents.js [--work-dir <dir>] [--flavor <product>] [--candidates dungeons,raids | --maps A,B] [--top N] [--out report.tsv]');
		process.exit(1);
	}
	opts.workDir = envOr(opts.workDir, 'WORK_DIR');
	opts.flavor = envOr(opts.flavor, 'FLAVOR');
	if (!opts.workDir || !opts.flavor) { console.error('WORK_DIR/FLAVOR (bootstrap.ps1 or --work-dir/--flavor) required.'); process.exit(1); }
	const flavorDirPath = flavorDir(opts.workDir, opts.flavor);

	const mapKinds = [];
	if (opts.maps) for (const m of opts.maps.split(',')) mapKinds.push({ key: m.trim(), kind: 'manual' });
	else for (const kind of opts.kinds.split(',')) for (const c of readCandidates(opts.workDir, opts.flavor, kind.trim())) mapKinds.push({ key: c.key, kind: kind.trim() });

	const placements = [];
	const wanted = new Set();
	for (const { key, kind } of mapKinds) {
		const mapDir = path.join(flavorDirPath, 'world', 'maps', key);
		if (!fs.existsSync(mapDir)) { console.error(`${key}: no extracted map dir, skipped`); continue; }
		const wdt = path.join(mapDir, `${key}.wdt`);
		const valid = fs.existsSync(wdt) ? new Set(getValidTiles(wdt, 'obj0ADT')) : new Set();
		let list = findAllPlacements(mapDir, valid);
		if (list.length === 0) list = findWdtPlacement(wdt);
		for (const e of list) { e.map = key; e.kind = kind; placements.push(e); wanted.add(e.nameId); }
	}

	const idToPath = {};
	const rl = readline.createInterface({ input: fs.createReadStream(listfilePath(opts.workDir)) });
	for await (const line of rl) {
		const idx = line.indexOf(';');
		if (idx === -1) continue;
		const id = parseInt(line.slice(0, idx), 10);
		if (wanted.has(id)) idToPath[id] = line.slice(idx + 1).trim();
	}

	const bboxCache = {};
	const rows = [];
	let missing = 0;
	for (const e of placements) {
		const wmoPath = idToPath[e.nameId];
		const local = wmoPath && path.join(flavorDirPath, wmoPath);
		if (!local || !fs.existsSync(local)) { missing++; continue; }
		if (!(e.nameId in bboxCache)) bboxCache[e.nameId] = readMohdBbox(local);
		if (!bboxCache[e.nameId]) { missing++; continue; }
		rows.push({ ...e, wmo: path.basename(wmoPath), ...compare(e, bboxCache[e.nameId]) });
	}
	rows.sort((a, b) => b.score - a.score);

	const fmt = (v, n = 1) => v.toFixed(n).padStart(8);
	const header = `${'map'.padEnd(22)}${'wmo'.padEnd(34)}${'uniqueId'.padStart(10)}${'yaw'.padStart(8)}${'dCenter'.padStart(9)}${'dX'.padStart(8)}${'dY'.padStart(8)}${'dW'.padStart(8)}${'dH'.padStart(8)}${'dZ'.padStart(8)}${'score'.padStart(9)}${'locDX'.padStart(8)}${'locDY'.padStart(8)}${'bboxCx'.padStart(8)}${'bboxCy'.padStart(8)}  notes`;
	const line = r => {
		const notes = [];
		if (r.wdtLevel) notes.push('WDT-level, size only');
		if (Math.abs(r.rot[0]) > 0.05 || Math.abs(r.rot[2]) > 0.05) notes.push(`pitch/roll ${r.rot[0].toFixed(1)}/${r.rot[2].toFixed(1)}`);
		if (r.scale !== 1024) notes.push(`scale ${r.scale}`);
		return `${r.map.padEnd(22).slice(0, 22)}${r.wmo.padEnd(34).slice(0, 34)}${String(r.uniqueId).padStart(10)}${fmt(r.rot[1], 2)}${fmt(r.dCenter).padStart(9)}${fmt(r.dx)}${fmt(r.dy)}${fmt(r.dW)}${fmt(r.dH)}${fmt(r.dZ)}${fmt(r.score).padStart(9)}${fmt(r.locX)}${fmt(r.locY)}${fmt(r.bcx)}${fmt(r.bcy)}  ${notes.join('; ')}`;
	};
	console.log(`${rows.length} placements compared (${missing} skipped: WMO file not extracted / not in listfile), ${new Set(rows.map(r => r.map)).size} maps`);
	console.log('Deltas = baked MODF.extents minus our computed box, Big units.\n');
	console.log(header);
	for (const r of rows.slice(0, opts.top)) console.log(line(r));
	const within = t => rows.filter(r => r.score <= t).length;
	console.log(`\nscore <= 1: ${within(1)}   <= 5: ${within(5)}   <= 25: ${within(25)}   <= 100: ${within(100)}   total: ${rows.length}`);

	if (opts.out) {
		fs.writeFileSync(opts.out, [header, ...rows.map(line)].join('\n') + '\n');
		console.log(`full report: ${opts.out}`);
	}
}

main();
