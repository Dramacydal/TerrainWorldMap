// Offline diagnostic: composites a map's baked WMO minimap tiles into one
// PNG, colored+labeled per WMO group, so a new gen_wmo_tiles.js candidate
// map (or a math change to the shared formula) can be sanity-checked by eye
// before touching the addon's shipped Lua data. Not loaded by the addon.
//
// Reuses gen_wmo_tiles.js's own placement math verbatim (Y-flip via
// trueGlobalMinY/trueGlobalMaxY, the fixed 90-degree local-coordinate
// rotation, MODF-position translation, Big-coordinate conversion -- see
// that file's header for the full derivation) plus one placement source it
// doesn't have yet: a WDT-level MODF ("pure WMO dungeon" -- MPHD.flags & 0x1,
// see .claude-docs/gotchas.md's "Detecting a pure WMO dungeon" entry), used
// whenever a map has no per-ADT MODF entries at all (e.g. Stockade).
//
// Rendering detail NOT present in gen_wmo_tiles.js (which never touches
// pixel data -- it only writes {fileID, box} for TerrainWorldMap.lua's own
// tex:SetTexture/SetWidth/SetHeight to stretch at render time): a WMO-group
// minimap BLP is cropped by Blizzard to its real content size, not always
// 256x256 (confirmed: Stockade's 26 groups range from 64x64 to 256x256).
// Placed left+bottom-anchored inside the nominal 256x256 block cell (see
// wow.export's src/js/wmo-minimap.js, composite_tile) before this script's
// own 90-degree content rotation.
//
// --with-adt-tiles composites the map's own real, baked OUTDOOR minimap
// tiles (world/minimaps/<map>/map<col>_<row>.blp) underneath the WMO layer
// -- ground truth for a map that has both (e.g. Orgrimmar Arena, Shadowfang
// Keep), the same offline technique this session used for Orgrimmar's own
// Y-anchor bugfix (see .claude-docs/gotchas.md's "WMO-tile world position").
//
// Usage:
//   node preview_wmo_tiles.js --flavor-dir <dir> --listfile <community-listfile.csv> --out <out.png> [--with-adt-tiles] <MapDirectoryName>
const fs = require('fs');
const path = require('path');
const readline = require('readline');
const { PNG } = require('pngjs');
const { Blp, BLP_IMAGE_FORMAT } = require('@wowserhq/format');

function chunkID(a, b, c, d) { return (a.charCodeAt(0) << 24) | (b.charCodeAt(0) << 16) | (c.charCodeAt(0) << 8) | d.charCodeAt(0); }
const ID_MPHD = chunkID('M', 'P', 'H', 'D');
const ID_MODF = chunkID('M', 'O', 'D', 'F');
const ID_MOGP = chunkID('M', 'O', 'G', 'P');

const MINI2BIG = 1600 / 3; // 533.3333.., matches TerrainWorldMap.lua's MINI2BIGX/Y
const MAP_ORIGIN = 32 * MINI2BIG;
const PPU = 2;
const TILE_UNITS = 256 / PPU; // 128
const ROT_EPSILON = 0.05; // degrees, same tolerance as gen_wmo_tiles.js

// Every MODF entry in a map's own _obj0.adt files, deduped by nameId --
// verbatim copy of gen_wmo_tiles.js's findModfPlacements.
function findAdtPlacements(mapDir) {
	const entries = [];
	const seen = new Set();
	for (const f of fs.readdirSync(mapDir)) {
		if (!f.endsWith('_obj0.adt')) continue;
		const buf = fs.readFileSync(path.join(mapDir, f));
		let offset = 0;
		while (offset + 8 <= buf.length) {
			const magic = buf.readUInt32LE(offset);
			const size = buf.readUInt32LE(offset + 4);
			const dataStart = offset + 8;
			if (magic === ID_MODF) {
				const count = size / 64;
				for (let i = 0; i < count; i++) {
					const b = dataStart + i * 64;
					const nameId = buf.readUInt32LE(b);
					if (seen.has(nameId)) continue;
					seen.add(nameId);
					entries.push({
						nameId,
						pos: [buf.readFloatLE(b + 8), buf.readFloatLE(b + 12), buf.readFloatLE(b + 16)],
						rot: [buf.readFloatLE(b + 20), buf.readFloatLE(b + 24), buf.readFloatLE(b + 28)],
					});
				}
			}
			offset = dataStart + size;
		}
	}
	return entries;
}

// A pure-WMO map (Stockade etc.) places its one global WMO via a WDT-level
// MODF instead -- guarded by MPHD.flags & 0x1 (wdt_uses_global_map_obj).
function findWdtPlacement(wdtPath) {
	if (!fs.existsSync(wdtPath)) return [];
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
	if (!(flags & 0x1) || !modf) return [];
	return [modf];
}

// MOGP chunk's own local bounding box (offset 12 within its data: flags(4)
// then bbox min C3Vector(12) + max C3Vector(12)).
function groupBoundingBox(groupFilePath) {
	const buf = fs.readFileSync(groupFilePath);
	let offset = 0;
	while (offset + 8 <= buf.length) {
		const magic = buf.readUInt32LE(offset);
		const size = buf.readUInt32LE(offset + 4);
		const dataStart = offset + 8;
		if (magic === ID_MOGP) {
			return {
				min: [buf.readFloatLE(dataStart + 12), buf.readFloatLE(dataStart + 16), buf.readFloatLE(dataStart + 20)],
				max: [buf.readFloatLE(dataStart + 24), buf.readFloatLE(dataStart + 28), buf.readFloatLE(dataStart + 32)],
			};
		}
		offset = dataStart + size;
	}
	return null;
}

// Real outdoor ADT minimap tiles, `world/minimaps/<map>/map<col>_<row>.blp`
// -- ground truth to composite the WMO tiles against, when a map has both
// (e.g. Orgrimmar Arena, Shadowfang Keep). Box per tile via the same
// col/row -> Big-coordinate mapping as TWM_Mini2Big_Coord (TerrainWorldMap.lua):
// Big = MAP_ORIGIN - index*MINI2BIG, one MINI2BIG step per tile.
function findAdtMinimapTiles(flavorDir, mapName) {
	const dir = path.join(flavorDir, 'world', 'minimaps', mapName);
	if (!fs.existsSync(dir)) return [];
	return fs.readdirSync(dir).flatMap(f => {
		const m = f.match(/^map(\d+)_(\d+)\.blp$/i);
		if (!m) return [];
		const col = parseInt(m[1], 10), row = parseInt(m[2], 10);
		return [{
			filePath: path.join(dir, f),
			x1: MAP_ORIGIN - col * MINI2BIG, x2: MAP_ORIGIN - (col + 1) * MINI2BIG,
			y1: MAP_ORIGIN - row * MINI2BIG, y2: MAP_ORIGIN - (row + 1) * MINI2BIG,
		}];
	});
}

function loadBlpImage(fp) {
	const buf = fs.readFileSync(fp);
	const blp = new Blp();
	blp.load(buf);
	const img = blp.getImage(0, BLP_IMAGE_FORMAT.IMAGE_ABGR8888);
	return { data: img.data, width: blp.width, height: blp.height };
}

// Left+bottom-anchors the real (possibly smaller-than-256) image inside a
// virtual 256x256 native-orientation cell (alpha=0 elsewhere).
function toNativeCell(img) {
	const cell = new Uint8Array(256 * 256 * 4);
	const offsetY = 256 - img.height;
	for (let y = 0; y < img.height; y++) {
		for (let x = 0; x < img.width; x++) {
			const si = (y * img.width + x) * 4;
			const di = ((y + offsetY) * 256 + x) * 4;
			cell[di] = img.data[si]; cell[di + 1] = img.data[si + 1];
			cell[di + 2] = img.data[si + 2]; cell[di + 3] = img.data[si + 3];
		}
	}
	return cell;
}

function groupColor(g) {
	const hue = (g * 47) % 360;
	const h = hue / 60, x = 1 - Math.abs(h % 2 - 1);
	let r, gg, b;
	if (h < 1) [r, gg, b] = [1, x, 0]; else if (h < 2) [r, gg, b] = [x, 1, 0];
	else if (h < 3) [r, gg, b] = [0, 1, x]; else if (h < 4) [r, gg, b] = [0, x, 1];
	else if (h < 5) [r, gg, b] = [x, 0, 1]; else[r, gg, b] = [1, 0, x];
	return [Math.round(r * 255), Math.round(gg * 255), Math.round(b * 255)];
}

const DIGITS = {
	0: ['111', '101', '101', '101', '111'], 1: ['010', '110', '010', '010', '111'],
	2: ['111', '001', '111', '100', '111'], 3: ['111', '001', '111', '001', '111'],
	4: ['101', '101', '111', '001', '001'], 5: ['111', '100', '111', '001', '111'],
	6: ['111', '100', '111', '101', '111'], 7: ['111', '001', '001', '001', '001'],
	8: ['111', '101', '111', '101', '111'], 9: ['111', '101', '111', '001', '111'],
};

function parseArgs(argv) {
	const opts = { flavorDir: null, listfile: null, out: null, withAdtTiles: false };
	const mapNames = [];
	for (let i = 0; i < argv.length; i++) {
		const a = argv[i];
		if (a === '--flavor-dir') opts.flavorDir = argv[++i];
		else if (a === '--listfile') opts.listfile = argv[++i];
		else if (a === '--out') opts.out = argv[++i];
		else if (a === '--with-adt-tiles') opts.withAdtTiles = true;
		else if (a.startsWith('--')) throw new Error(`Unknown option: ${a}`);
		else mapNames.push(a);
	}
	return { opts, mapNames };
}

function printUsage() {
	console.error('Usage: node preview_wmo_tiles.js --flavor-dir <dir> --listfile <community-listfile.csv> --out <out.png> [--with-adt-tiles] <MapDirectoryName>');
}

async function main() {
	let opts, mapNames;
	try {
		({ opts, mapNames } = parseArgs(process.argv.slice(2)));
	} catch (e) {
		console.error(e.message);
		printUsage();
		process.exit(1);
	}
	if (!opts.flavorDir || !opts.listfile || !opts.out || mapNames.length !== 1) {
		printUsage();
		process.exit(1);
	}
	const mapName = mapNames[0];
	const mapDir = path.join(opts.flavorDir, 'world', 'maps', mapName);

	let placements = fs.existsSync(mapDir) ? findAdtPlacements(mapDir) : [];
	let source = 'ADT MODF';
	if (placements.length === 0) {
		placements = findWdtPlacement(path.join(mapDir, `${mapName}.wdt`));
		source = 'WDT-level MODF (pure WMO map)';
	}
	if (placements.length === 0) {
		console.error(`${mapName}: no MODF placement found (neither per-ADT nor WDT-level)`);
		process.exit(1);
	}
	console.log(`${mapName}: ${placements.length} placement(s) via ${source}`);

	// Resolve each placement's nameId to a WMO path, one listfile pass.
	const wantedNameIds = new Set(placements.map(p => p.nameId));
	const idToPath = {};
	const rl = readline.createInterface({ input: fs.createReadStream(opts.listfile) });
	for await (const line of rl) {
		const idx = line.indexOf(';');
		if (idx === -1) continue;
		const id = parseInt(line.slice(0, idx), 10);
		if (wantedNameIds.has(id)) idToPath[id] = line.slice(idx + 1).trim();
	}

	const mapTiles = [];
	for (const p of placements) {
		const wmoPath = idToPath[p.nameId];
		if (!wmoPath) { console.error(`  (nameId ${p.nameId} not found in listfile, skipping)`); continue; }

		const rotMag = Math.max(...p.rot.map(Math.abs));
		if (rotMag > ROT_EPSILON) {
			console.error(`  (skipping ${wmoPath} -- real rotation ${p.rot.map(x => x.toFixed(2))}, not supported yet)`);
			continue;
		}

		const wmoDir = path.join(opts.flavorDir, path.dirname(wmoPath));
		const wmoBase = path.basename(wmoPath, '.wmo');
		const minimapDir = path.join(opts.flavorDir, path.dirname(wmoPath).replace(/^world[\\/]wmo/, 'world/minimaps/wmo'));
		if (!fs.existsSync(minimapDir)) { console.error(`  (no minimap dir for ${wmoPath}: ${minimapDir})`); continue; }

		const tileFiles = fs.readdirSync(minimapDir).filter(f => f.startsWith(wmoBase + '_'));
		const tiles = tileFiles.map(f => {
			const m = f.match(/^.*_(\d+)_(\d+)_(\d+)\.blp$/);
			return m && { groupNum: parseInt(m[1], 10), blockX: parseInt(m[2], 10), blockY: parseInt(m[3], 10), file: f };
		}).filter(Boolean);
		if (tiles.length === 0) { console.error(`  (no baked minimap tiles for ${wmoPath})`); continue; }

		const groupNums = [...new Set(tiles.map(t => t.groupNum))];
		const groupBoxes = {};
		for (const g of groupNums) {
			const gp = path.join(wmoDir, `${wmoBase}_${String(g).padStart(3, '0')}.wmo`);
			if (!fs.existsSync(gp)) { console.error(`  (group ${g} file missing: ${gp})`); continue; }
			groupBoxes[g] = groupBoundingBox(gp);
		}

		const trueGlobalMinY = Math.min(...Object.values(groupBoxes).map(b => Math.min(b.min[1], b.max[1])));
		const trueGlobalMaxY = Math.max(...Object.values(groupBoxes).map(b => Math.max(b.min[1], b.max[1])));

		for (const t of tiles) {
			const box = groupBoxes[t.groupNum];
			if (!box) continue;
			const localX1 = Math.min(box.min[0], box.max[0]) + t.blockX * TILE_UNITS;
			const localX2 = localX1 + TILE_UNITS;
			const localY1raw = Math.min(box.min[1], box.max[1]) + t.blockY * TILE_UNITS;
			const localY1 = (trueGlobalMinY + trueGlobalMaxY) - localY1raw - TILE_UNITS;
			const localY2 = localY1 + TILE_UNITS;

			const rotLocalX1 = -localY1, rotLocalX2 = -localY2;
			const rotLocalY1 = localX1, rotLocalY2 = localX2;

			const worldXa = p.pos[0] + rotLocalX1, worldXb = p.pos[0] + rotLocalX2;
			const worldYa = p.pos[2] + rotLocalY1, worldYb = p.pos[2] + rotLocalY2;

			const bigXa = MAP_ORIGIN - worldXa, bigXb = MAP_ORIGIN - worldXb;
			const bigYa = MAP_ORIGIN - worldYa, bigYb = MAP_ORIGIN - worldYb;

			mapTiles.push({
				groupNum: t.groupNum,
				filePath: path.join(minimapDir, t.file),
				x1: Math.max(bigXa, bigXb), x2: Math.min(bigXa, bigXb),
				y1: Math.max(bigYa, bigYb), y2: Math.min(bigYa, bigYb),
				height: p.pos[1] + (box.min[2] + box.max[2]) / 2,
			});
		}
	}

	if (mapTiles.length === 0) {
		console.error(`${mapName}: nothing left to render`);
		process.exit(1);
	}
	console.log(`${mapTiles.length} tiles across ${new Set(mapTiles.map(t => t.groupNum)).size} groups`);

	const adtTiles = opts.withAdtTiles ? findAdtMinimapTiles(opts.flavorDir, mapName) : [];
	if (opts.withAdtTiles) {
		if (adtTiles.length === 0) console.error(`  (--with-adt-tiles: no real ADT minimap tiles found for ${mapName})`);
		else console.log(`${adtTiles.length} real ADT minimap tiles found (backdrop)`);
	}

	const PAD = 32;
	const allBoxes = [...mapTiles, ...adtTiles];
	const minX = Math.min(...allBoxes.map(t => t.x2)), maxX = Math.max(...allBoxes.map(t => t.x1));
	const minY = Math.min(...allBoxes.map(t => t.y2)), maxY = Math.max(...allBoxes.map(t => t.y1));
	const W = Math.ceil((maxX - minX) * PPU) + PAD * 2;
	const H = Math.ceil((maxY - minY) * PPU) + PAD * 2;
	console.log(`canvas ${W}x${H}`);

	const png = new PNG({ width: W, height: H });
	for (let i = 0; i < png.data.length; i += 4) { png.data[i] = 20; png.data[i + 1] = 20; png.data[i + 2] = 20; png.data[i + 3] = 255; }

	function bigToPixel(bx, by) {
		return [(maxX - bx) * PPU + PAD, (maxY - by) * PPU + PAD];
	}
	function setPx(x, y, r, g, b) {
		if (x < 0 || x >= W || y < 0 || y >= H) return;
		const di = (y * W + x) * 4;
		png.data[di] = r; png.data[di + 1] = g; png.data[di + 2] = b; png.data[di + 3] = 255;
	}
	function drawDigit(x0, y0, digit, scale, r, g, b) {
		const rows = DIGITS[digit];
		for (let ry = 0; ry < 5; ry++) for (let rx = 0; rx < 3; rx++) {
			if (rows[ry][rx] !== '1') continue;
			for (let sy = 0; sy < scale; sy++) for (let sx = 0; sx < scale; sx++) setPx(x0 + rx * scale + sx, y0 + ry * scale + sy, r, g, b);
		}
	}
	function drawNumber(x0, y0, n, scale, r, g, b) {
		const s = String(n);
		for (let i = 0; i < s.length; i++) drawDigit(x0 + i * (3 * scale + scale), y0, parseInt(s[i], 10), scale, r, g, b);
	}

	// Real ADT terrain first, as a backdrop -- no rotation, no alpha (opaque
	// ground), nearest-neighbor scaled from its native 512x512 (PPU ~0.96)
	// to this canvas's PPU=2 box.
	for (const t of adtTiles) {
		const raw = loadBlpImage(t.filePath);
		const [px0, py0] = bigToPixel(t.x1, t.y1);
		const [px1, py1] = bigToPixel(t.x2, t.y2);
		const left = Math.round(px0), top = Math.round(py0);
		const boxW = Math.round(px1) - left, boxH = Math.round(py1) - top;
		for (let dy = 0; dy < boxH; dy++) for (let dx = 0; dx < boxW; dx++) {
			const sx = Math.min(raw.width - 1, Math.floor(dx / boxW * raw.width));
			const sy = Math.min(raw.height - 1, Math.floor(dy / boxH * raw.height));
			const si = (sy * raw.width + sx) * 4;
			const dxi = left + dx, dyi = top + dy;
			if (dxi < 0 || dxi >= W || dyi < 0 || dyi >= H) continue;
			const di = (dyi * W + dxi) * 4;
			png.data[di] = raw.data[si]; png.data[di + 1] = raw.data[si + 1];
			png.data[di + 2] = raw.data[si + 2]; png.data[di + 3] = 255;
		}
	}

	// Paint lower-height groups first, higher ones on top -- matches the
	// live addon's own draw order (SetDrawLayer keyed off height rank).
	const paintOrder = [...mapTiles].sort((a, b) => a.height - b.height);

	for (const t of paintOrder) {
		const raw = loadBlpImage(t.filePath);
		const cell = toNativeCell(raw);
		t.rawW = raw.width; t.rawH = raw.height;

		// bigToPixel is monotonically decreasing in (bx,by), and x1/y1 are
		// each corner's own MAX big-coordinate -- so this is already the
		// pixel-space top-left corner, no min() needed.
		const [left0, top0] = bigToPixel(t.x1, t.y1);
		const left = Math.round(left0), top = Math.round(top0);

		// 90-degree CW content rotation (matches TWM_WMOOverlay_EnsureTextures'
		// SetTexCoord(0,1, 1,1, 0,0, 1,0)) against the assembled native cell.
		for (let dyi = 0; dyi < 256; dyi++) for (let dxi = 0; dxi < 256; dxi++) {
			const sx = dyi, sy = 255 - dxi;
			const si = (sy * 256 + sx) * 4;
			const a = cell[si + 3] / 255;
			if (a <= 0) continue;
			const dx = left + dxi, dy = top + dyi;
			if (dx < 0 || dx >= W || dy < 0 || dy >= H) continue;
			const di = (dy * W + dx) * 4;
			png.data[di] = cell[si] * a + png.data[di] * (1 - a);
			png.data[di + 1] = cell[si + 1] * a + png.data[di + 1] * (1 - a);
			png.data[di + 2] = cell[si + 2] * a + png.data[di + 2] * (1 - a);
			png.data[di + 3] = 255;
		}
	}

	// Thin per-group outline (real image footprint, top-left anchored) + a
	// number label -- the rotation swaps which raw dimension becomes the
	// canvas width vs height (see toNativeCell's left+bottom anchor: tracing
	// dest(dxi,dyi) <- native(dyi, 255-dxi) shows canvas width = rawH,
	// canvas height = rawW).
	for (const t of paintOrder) {
		const [px0, py0] = bigToPixel(t.x1, t.y1);
		const left = Math.round(px0), top = Math.round(py0);
		const right = left + t.rawH - 1, bottom = top + t.rawW - 1;
		const [cr, cg, cb] = groupColor(t.groupNum);
		for (let x = left; x <= right; x++) { setPx(x, top, cr, cg, cb); setPx(x, bottom, cr, cg, cb); }
		for (let y = top; y <= bottom; y++) { setPx(left, y, cr, cg, cb); setPx(right, y, cr, cg, cb); }
		drawNumber(left + 2, top + 2, t.groupNum, 2, 255, 255, 0);
	}

	fs.writeFileSync(opts.out, PNG.sync.write(png));
	console.log(`written: ${opts.out}`);
}

main();
