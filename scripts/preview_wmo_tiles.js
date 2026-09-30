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
// --dump-tiles-dir <dir> additionally (or instead of --out -- see printUsage)
// writes every individual baked WMO minimap tile out as its own PNG, at its
// real (possibly-cropped) native size, named "<FileDataID>.png" -- useful to
// eyeball each raw tile texture on its own, not just the composited overlay.
// FileDataID is resolved from the SAME community listfile pass already done
// to turn a MODF's nameId into a WMO path, just matched the other direction
// (local relative path -> ID) -- CASCConsole extracts files under exactly
// the listfile's own path/casing, so a plain string match is reliable.
//
// Usage:
//   node preview_wmo_tiles.js --work-dir <dir> --flavor <product> (--client-dir <path> | --online) (--out <out.png> | --dump-tiles-dir <dir>) [--with-adt-tiles] <MapDirectoryName>
const fs = require('fs');
const path = require('path');
const readline = require('readline');
const { PNG } = require('pngjs');
const { Blp, BLP_IMAGE_FORMAT } = require('@wowserhq/format');
const { flavorDir, listfilePath, ensureExtracted, envOr } = require('./extract');
const { getValidTiles } = require('./parse_wdt');

const escapeRegExp = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

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
// verbatim copy of gen_wmo_tiles.js's findModfPlacements, including its
// validTileKeys cross-check (a stray _obj0.adt in CASC for a tile the WDT's
// own MAIN/MAID chunk doesn't consider real terrain shouldn't be trusted --
// see .claude-docs/gotchas.md).
function findAdtPlacements(mapDir, validTileKeys) {
	const entries = [];
	const seen = new Set();
	for (const f of fs.readdirSync(mapDir)) {
		if (!f.endsWith('_obj0.adt')) continue;
		const m = f.match(/_(\d+)_(\d+)_obj0\.adt$/i);
		if (m) {
			const key = `${m[1].padStart(2, '0')}x${m[2].padStart(2, '0')}`;
			if (!validTileKeys.has(key)) {
				console.error(`  (ignoring ${f} -- not a real, obj0ADT-backed tile per this map's own WDT)`);
				continue;
			}
		}
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

// Forward: native content-rotated pixel (dxi,dyi) -> Big-space point, for a
// tile carrying {localX1, localY1, cosT, sinT, posX, posZ} (yaw pre-baked
// into cosT/sinT, 0/1 for a non-rotated placement). Derived by parameterizing
// gen_wmo_tiles.js's own per-corner formula continuously across the whole
// 256x256 cell instead of just its two corners, then inserting one more
// rotation (by the placement's real MODF yaw) between the fixed 90-degree
// baking rotation and the MODF-position translation -- yaw rotates the
// WHOLE placement as a rigid body, same as it rotates everything else MODF
// places.
function forwardBigPoint(t, dxi, dyi) {
	const rotLocalX = -(t.localY1 + (256 - dxi) / 2);
	const rotLocalY = t.localX1 + dyi / 2;
	const finalLocalX = rotLocalX * t.cosT - rotLocalY * t.sinT;
	const finalLocalY = rotLocalX * t.sinT + rotLocalY * t.cosT;
	const worldX = t.posX + finalLocalX, worldY = t.posZ + finalLocalY;
	return [MAP_ORIGIN - worldX, MAP_ORIGIN - worldY];
}

// Inverse of the above: Big-space point -> native content-rotated pixel
// (dxi,dyi), fractional (caller rounds/range-checks). Used to rasterize a
// yaw-rotated tile without leaving gaps (forward-mapping single source
// pixels into a rotated destination misses pixels at non-90-degree angles).
function inverseDxiDyi(t, bigX, bigY) {
	const worldX = MAP_ORIGIN - bigX, worldY = MAP_ORIGIN - bigY;
	const finalLocalX = worldX - t.posX, finalLocalY = worldY - t.posZ;
	// R^-1 = R^T for a rotation matrix.
	const rotLocalX = finalLocalX * t.cosT + finalLocalY * t.sinT;
	const rotLocalY = -finalLocalX * t.sinT + finalLocalY * t.cosT;
	const dxi = 256 + 2 * rotLocalX + 2 * t.localY1;
	const dyi = 2 * (rotLocalY - t.localX1);
	return [dxi, dyi];
}

// Big-space point for an arbitrary (rotLocalX, rotLocalY) pair -- the same
// rotate+translate+Big-convert tail as forwardBigPoint, factored out so real
// (possibly-cropped) tile corners can be computed directly, gen_wmo_tiles.js
// style, instead of only via the fixed-256-native-cell parameterization.
function toBigPoint(t, rotLocalX, rotLocalY) {
	const finalLocalX = rotLocalX * t.cosT - rotLocalY * t.sinT;
	const finalLocalY = rotLocalX * t.sinT + rotLocalY * t.cosT;
	const worldX = t.posX + finalLocalX, worldY = t.posZ + finalLocalY;
	return [MAP_ORIGIN - worldX, MAP_ORIGIN - worldY];
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
	const opts = {
		workDir: null, flavor: null, clientDir: null, online: false, clientLocale: 'enUS',
		out: null, dumpTilesDir: null, withAdtTiles: false, noOutlines: false, bg: [20, 20, 20], force: false, proxy: null,
	};
	const mapNames = [];
	for (let i = 0; i < argv.length; i++) {
		const a = argv[i];
		if (a === '--work-dir') opts.workDir = argv[++i];
		else if (a === '--flavor') opts.flavor = argv[++i];
		else if (a === '--client-dir') opts.clientDir = argv[++i];
		else if (a === '--online') opts.online = true;
		else if (a === '--client-locale') opts.clientLocale = argv[++i];
		else if (a === '--out') opts.out = argv[++i];
		else if (a === '--dump-tiles-dir') opts.dumpTilesDir = argv[++i];
		else if (a === '--with-adt-tiles') opts.withAdtTiles = true;
		else if (a === '--no-outlines') opts.noOutlines = true;
		else if (a === '--bg') opts.bg = argv[++i].split(',').map(Number);
		else if (a === '--force') opts.force = true;
		else if (a === '--proxy') opts.proxy = argv[++i];
		else if (a.startsWith('--')) throw new Error(`Unknown option: ${a}`);
		else mapNames.push(a);
	}
	return { opts, mapNames };
}

function printUsage() {
	console.error('Usage: node preview_wmo_tiles.js --work-dir <dir> --flavor <product> (--client-dir <path> | --online) (--out <out.png> | --dump-tiles-dir <dir>) [--with-adt-tiles] [--no-outlines] [--bg r,g,b] [--force] [--proxy <url>] <MapDirectoryName>');
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
	opts.workDir = envOr(opts.workDir, 'WORK_DIR');
	opts.clientDir = envOr(opts.clientDir, 'CLIENT_DIR');
	opts.flavor = envOr(opts.flavor, 'FLAVOR');
	opts.proxy = envOr(opts.proxy, 'PROXY');

	if (!opts.workDir || !opts.flavor || (!opts.out && !opts.dumpTilesDir) || mapNames.length !== 1) {
		printUsage();
		process.exit(1);
	}
	const flavorDirPath = flavorDir(opts.workDir, opts.flavor);
	const extractOpts = {
		workDir: opts.workDir, flavor: opts.flavor,
		clientDir: opts.clientDir, online: opts.online, clientLocale: opts.clientLocale,
		force: opts.force,
	};
	const mapName = mapNames[0];
	const mapDir = path.join(flavorDirPath, 'world', 'maps', mapName);
	const escapedMap = escapeRegExp(mapName);

	ensureExtracted({
		...extractOpts,
		// [^/]+, not \w+ -- see parse_wdt.js's identical fix (a map's
		// Directory can contain a space/apostrophe, e.g. "Stratholme Raid").
		pattern: `^world/maps/${escapedMap}/(${escapedMap}\\.wdt|[^/]+_obj0\\.adt)$`,
		checkPaths: [path.join('world', 'maps', mapName, `${mapName}.wdt`)],
	});
	if (opts.withAdtTiles) {
		ensureExtracted({
			...extractOpts,
			pattern: `^world/minimaps/${escapedMap}/map\\d+_\\d+\\.blp$`,
			checkPaths: [path.join('world', 'minimaps', mapName)],
		});
	}

	let placements = fs.existsSync(mapDir)
		? findAdtPlacements(mapDir, new Set(getValidTiles(path.join(mapDir, `${mapName}.wdt`), 'obj0ADT')))
		: [];
	let source = 'ADT MODF';
	if (placements.length === 0) {
		placements = findWdtPlacement(path.join(mapDir, `${mapName}.wdt`));
		source = 'WDT-level MODF (pure WMO map)';
	}
	if (placements.length === 0) {
		// Not fatal with --with-adt-tiles -- a map with no WMO minimap-tile
		// placement at all (ordinary open-world/battleground terrain, no
		// WMO overlay feature involved) can still be previewed from just
		// its real outdoor ADT minimap tiles below.
		if (opts.withAdtTiles) console.error(`${mapName}: no MODF placement found (neither per-ADT nor WDT-level) -- rendering outdoor ADT tiles only`);
		else {
			console.error(`${mapName}: no MODF placement found (neither per-ADT nor WDT-level)`);
			process.exit(1);
		}
	} else {
		console.log(`${mapName}: ${placements.length} placement(s) via ${source}`);
	}

	// Resolve each placement's nameId to a WMO path, one listfile pass -- also
	// builds the reverse (path -> FileDataID) map in the SAME pass when
	// --dump-tiles-dir is set, rather than reading the (large) listfile a
	// second time just to look up IDs the other direction.
	const wantedNameIds = new Set(placements.map(p => p.nameId));
	const idToPath = {};
	const pathToId = opts.dumpTilesDir ? {} : null;
	const rl = readline.createInterface({ input: fs.createReadStream(listfilePath(opts.workDir)) });
	for await (const line of rl) {
		const idx = line.indexOf(';');
		if (idx === -1) continue;
		const id = parseInt(line.slice(0, idx), 10);
		const p = line.slice(idx + 1).trim();
		if (wantedNameIds.has(id)) idToPath[id] = p;
		if (pathToId) pathToId[p] = id;
	}
	if (opts.dumpTilesDir) fs.mkdirSync(opts.dumpTilesDir, { recursive: true });

	const mapTiles = [];
	for (const p of placements) {
		const wmoPath = idToPath[p.nameId];
		if (!wmoPath) { console.error(`  (nameId ${p.nameId} not found in listfile, skipping)`); continue; }

		// Yaw (rot[1], same axis as position's own height component) is
		// supported; pitch/roll aren't (confirmed: every real placement
		// checked so far is yaw-only -- see scripts/README.md's Step 10).
		const pitchRollMag = Math.max(Math.abs(p.rot[0]), Math.abs(p.rot[2]));
		if (pitchRollMag > ROT_EPSILON) {
			console.error(`  (skipping ${wmoPath} -- real pitch/roll ${p.rot.map(x => x.toFixed(2))}, not supported)`);
			continue;
		}
		if (Math.abs(p.rot[1]) > ROT_EPSILON) console.log(`  ${wmoPath}: yaw ${p.rot[1].toFixed(2)} degrees`);

		const wmoDirRel = path.dirname(wmoPath);
		const wmoBase = path.basename(wmoPath, '.wmo');
		const minimapDirRel = wmoDirRel.replace(/^world[\\/]wmo/, 'world/minimaps/wmo');
		const wmoDir = path.join(flavorDirPath, wmoDirRel);
		const minimapDir = path.join(flavorDirPath, minimapDirRel);

		// Self-extract this WMO's group model files + its baked minimap tiles
		// -- the exact per-tile file list isn't known yet (that needs a local
		// directory listing, right below), so this uses the minimap dir's own
		// existence as a coarse "probably already extracted" cache-hit signal
		// rather than an exact per-file check (see gen_wmo_tiles.js for the
		// precise, listfile-driven version used by the main pipeline).
		ensureExtracted({
			...extractOpts,
			pattern: `^(${escapeRegExp(wmoDirRel)}/${escapeRegExp(wmoBase)}_\\d+\\.wmo|${escapeRegExp(minimapDirRel)}/${escapeRegExp(wmoBase)}_\\d+_\\d+_\\d+\\.blp)$`,
			checkPaths: [minimapDirRel],
		});
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

		// Negated: confirmed against Shadowfang Keep's real ADT terrain AND
		// in-game (rot[1]=68.5, matches at -68.5, not +68.5). The Y-flip
		// this local space already went through is a REFLECTION (negates
		// one axis, determinant -1); composed with the 90-degree baking
		// rotation (a pure rotation, determinant +1), the whole "rotLocal"
		// frame is a mirror image of the model's own true local space --
		// applying a rotation inside a mirrored frame reverses its sense,
		// so the placement's real yaw has to be negated to land correctly
		// once expressed in this already-mirrored coordinate system.
		const yawRad = -p.rot[1] * Math.PI / 180;
		const cosT = Math.cos(yawRad), sinT = Math.sin(yawRad);

		for (const t of tiles) {
			const box = groupBoxes[t.groupNum];
			if (!box) continue;
			const filePath = path.join(minimapDir, t.file);
			const raw = loadBlpImage(filePath); // loaded once, reused for painting below

			if (pathToId) {
				const relPath = path.join(minimapDirRel, t.file).replace(/\\/g, '/');
				const fileID = pathToId[relPath];
				if (fileID) {
					const tilePng = new PNG({ width: raw.width, height: raw.height });
					tilePng.data.set(raw.data);
					const outPath = path.join(opts.dumpTilesDir, `${fileID}.png`);
					fs.writeFileSync(outPath, PNG.sync.write(tilePng));
					console.log(`  dumped ${outPath} (${raw.width}x${raw.height})`);
				} else {
					console.error(`  (no listfile entry for ${relPath}, can't name a dump by FileDataID -- skipping)`);
				}
			}

			const localX1 = Math.min(box.min[0], box.max[0]) + t.blockX * TILE_UNITS;
			const localY1raw = Math.min(box.min[1], box.max[1]) + t.blockY * TILE_UNITS;
			// Rendering anchor -- deliberately UNCHANGED (full nominal 128-unit
			// box, gen_wmo_tiles.js's pre-crop-fix formula). forwardBigPoint/
			// inverseDxiDyi map the whole fixed 256x256 native cell (real
			// content left+bottom-anchored inside it by toNativeCell, alpha=0
			// elsewhere) to this same full box, so pixel painting is already
			// correct regardless of crop -- no stretch happens here, unlike
			// TerrainWorldMap.lua's tex:SetWidth/SetHeight, so this anchor must
			// stay full-size for the inverse-mapping lookup to stay valid.
			const localY1 = (trueGlobalMinY + trueGlobalMaxY) - localY1raw - TILE_UNITS;

			const tile = {
				groupNum: t.groupNum,
				filePath, raw,
				localX1, localY1, cosT, sinT, posX: p.pos[0], posZ: p.pos[2],
				height: p.pos[1] + (box.min[2] + box.max[2]) / 2,
			};

			// Real-content (possibly-cropped) box, gen_wmo_tiles.js style --
			// same two anchors (localX1, localY2) it keeps fixed, shrinking the
			// far edges to the real BLP size instead of always TILE_UNITS. Used
			// ONLY for the canvas extent, the outline, and the label -- i.e. the
			// debug-border ground truth -- not for pixel painting (see above).
			const localY2s = (trueGlobalMinY + trueGlobalMaxY) - localY1raw;
			const localX2s = localX1 + raw.width / PPU;
			const localY1s = localY2s - raw.height / PPU;
			tile.corners = [
				toBigPoint(tile, -localY1s, localX1),
				toBigPoint(tile, -localY2s, localX1),
				toBigPoint(tile, -localY2s, localX2s),
				toBigPoint(tile, -localY1s, localX2s),
			];
			tile.x1 = Math.max(...tile.corners.map(c => c[0]));
			tile.x2 = Math.min(...tile.corners.map(c => c[0]));
			tile.y1 = Math.max(...tile.corners.map(c => c[1]));
			tile.y2 = Math.min(...tile.corners.map(c => c[1]));
			mapTiles.push(tile);
		}
	}

	console.log(`${mapTiles.length} WMO tile(s) across ${new Set(mapTiles.map(t => t.groupNum)).size} group(s)`);

	const adtTiles = opts.withAdtTiles ? findAdtMinimapTiles(flavorDirPath, mapName) : [];
	if (opts.withAdtTiles) {
		if (adtTiles.length === 0) console.error(`  (--with-adt-tiles: no real ADT minimap tiles found for ${mapName})`);
		else console.log(`${adtTiles.length} real ADT minimap tiles found (backdrop)`);
	}

	if (mapTiles.length === 0 && adtTiles.length === 0) {
		console.error(`${mapName}: nothing left to render`);
		process.exit(1);
	}

	if (!opts.out) {
		// --dump-tiles-dir only, no composite requested -- the actual dump
		// writes already happened per-tile in the loop above.
		return;
	}

	const PAD = 32;
	const allBoxes = [...mapTiles, ...adtTiles];
	const minX = Math.min(...allBoxes.map(t => t.x2)), maxX = Math.max(...allBoxes.map(t => t.x1));
	const minY = Math.min(...allBoxes.map(t => t.y2)), maxY = Math.max(...allBoxes.map(t => t.y1));
	const W = Math.ceil((maxX - minX) * PPU) + PAD * 2;
	const H = Math.ceil((maxY - minY) * PPU) + PAD * 2;
	console.log(`canvas ${W}x${H}`);

	const [bgR, bgG, bgB] = opts.bg;
	const png = new PNG({ width: W, height: H });
	for (let i = 0; i < png.data.length; i += 4) { png.data[i] = bgR; png.data[i + 1] = bgG; png.data[i + 2] = bgB; png.data[i + 3] = 255; }

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
	function drawLine(x0, y0, x1, y1, r, g, b) {
		const steps = Math.max(1, Math.round(Math.max(Math.abs(x1 - x0), Math.abs(y1 - y0))));
		for (let i = 0; i <= steps; i++) {
			const t = i / steps;
			setPx(Math.round(x0 + (x1 - x0) * t), Math.round(y0 + (y1 - y0) * t), r, g, b);
		}
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
		const cell = toNativeCell(t.raw);

		// Pixel-space bounding rect of the tile's own (possibly rotated)
		// quad, from its 4 real corners -- iterate only this, not the whole
		// canvas.
		const pixCorners = t.corners.map(([bx, by]) => bigToPixel(bx, by));
		const left = Math.max(0, Math.floor(Math.min(...pixCorners.map(c => c[0]))));
		const right = Math.min(W - 1, Math.ceil(Math.max(...pixCorners.map(c => c[0]))));
		const top = Math.max(0, Math.floor(Math.min(...pixCorners.map(c => c[1]))));
		const bottom = Math.min(H - 1, Math.ceil(Math.max(...pixCorners.map(c => c[1]))));

		// Inverse mapping (canvas pixel -> native content-rotated pixel) --
		// required once yaw can be non-zero: forward-scattering single
		// source pixels into a rotated destination leaves gaps at any angle
		// that isn't a multiple of 90 degrees.
		for (let py = top; py <= bottom; py++) {
			for (let px = left; px <= right; px++) {
				const bigX = maxX - (px - PAD) / PPU, bigY = maxY - (py - PAD) / PPU;
				const [dxiF, dyiF] = inverseDxiDyi(t, bigX, bigY);
				if (dxiF < 0 || dxiF >= 256 || dyiF < 0 || dyiF >= 256) continue;
				// Matches TWM_WMOOverlay_EnsureTextures' content rotation
				// (SetTexCoord(0,1, 1,1, 0,0, 1,0)): native(sx,sy) <- (dyi, 255-dxi).
				// Both clamped on BOTH ends: dxiF/dyiF are checked < 256 above,
				// but e.g. dxiF=255.6 still rounds to 256, and 255-256=-1 --
				// an unclamped negative sy silently read as NaN alpha (NaN<=0
				// is false, so it wasn't skipped) and wrote a stray black
				// pixel, tracing a straight line (dxiF's own 255.5 boundary,
				// identical across every tile sharing this rotation) across
				// the whole canvas.
				const sx = Math.max(0, Math.min(255, Math.round(dyiF)));
				const sy = Math.max(0, Math.min(255, 255 - Math.round(dxiF)));
				const si = (sy * 256 + sx) * 4;
				const a = cell[si + 3] / 255;
				if (a <= 0) continue;
				const di = (py * W + px) * 4;
				png.data[di] = cell[si] * a + png.data[di] * (1 - a);
				png.data[di + 1] = cell[si + 1] * a + png.data[di + 1] * (1 - a);
				png.data[di + 2] = cell[si + 2] * a + png.data[di + 2] * (1 - a);
				png.data[di + 3] = 255;
			}
		}
	}

	// Thin per-group outline (the tile's real, possibly-rotated quad, not
	// its axis-aligned bounding box) + a number label at its first corner.
	// Skippable (--no-outlines) -- with dozens of overlapping groups (a real
	// dungeon interior, e.g. Shadowfang's 73), the outlines alone can hide
	// the actual content they're meant to help read.
	if (!opts.noOutlines) {
		for (const t of paintOrder) {
			const pixCorners = t.corners.map(([bx, by]) => bigToPixel(bx, by));
			const [cr, cg, cb] = groupColor(t.groupNum);
			for (let i = 0; i < 4; i++) {
				const [x0, y0] = pixCorners[i], [x1, y1] = pixCorners[(i + 1) % 4];
				drawLine(x0, y0, x1, y1, cr, cg, cb);
			}
			drawNumber(Math.round(pixCorners[0][0]) + 2, Math.round(pixCorners[0][1]) + 2, t.groupNum, 2, 255, 255, 0);
		}
	}

	fs.writeFileSync(opts.out, PNG.sync.write(png));
	console.log(`written: ${opts.out}`);
}

main();
