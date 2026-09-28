// Regenerates Data_<Flavor>/mapdata_wmo_tiles.lua (Twm_WMOTiles) --
// minimap tile placement data for maps whose real terrain has no baked
// minimap art of its own (confirmed on Mists' Dalaran Sewers Arena: real
// WDT/ADT tiles exist, but zero "world/minimaps/<map>/*.blp" files do),
// while a WMO structure actually placed there DOES have its own baked
// minimap art (world/minimaps/wmo/.../<name>_<group>_<blockX>_<blockY>.blp,
// via the same per-WMO-group minimap system as WMO dungeon interiors --
// see .claude-docs/gotchas.md's "Dungeon/interior minimap tiles" section).
// Currently only ever run against arena maps (see "Generated so far" in
// scripts/README.md) -- generalized (naming, no arena-specific hardcodes)
// so dungeons/raids can reuse this same script later; that extraction
// scope itself (e.g. handling a WDT-level MODF for pure-WMO instances,
// see gotchas.md's "Detecting a pure WMO dungeon" entry) is NOT yet
// implemented, only the naming/generality groundwork is done for now.
//
// SCOPE: only WMO placements with zero rotation (MODF.rotation all three
// components ~0) are supported -- model->world for those is a plain
// translation, no rotation matrix needed. A placement with real rotation
// (confirmed to exist on other arenas, e.g. Ruins of Lordaeron, Tol'Viron
// Arena -- yaw-only, i.e. only the rotation's middle component is ever
// nonzero in every real case checked, never pitch/roll) is skipped with a
// warning; the yaw transform isn't implemented yet since there's no way to
// visually validate it against real anything (no rotated WMO's placement
// has been visually confirmed correct in this addon's own history).
//
// Coordinate derivation (verified against this map's own already-computed
// Twm_mapareas box, itself from valid-tile extent -- see gen_arenas.js):
//   MODF.position is (X, height, Y) -- height is the middle component (a
//   small value, confirmed: e.g. Dalaran Sewers' own placement has
//   position=(16278.01, 6.17, 15765.27), and 6.17 is obviously not a
//   ground-plane coordinate for content sized in the thousands).
//   World.X = MODF.position[0] + local.X, World.Y = MODF.position[2] + local.Y
//   (rotation=0, so no rotation matrix -- direct add of two same-physical-axis
//   values, each read from its own struct's own axis order -- see below).
//   Big-X = MAP_ORIGIN - World.X, Big-Y = MAP_ORIGIN - World.Y -- NO
//   world-axis cross-swap here, unlike gen_mapareas.js's own
//   "Big-X = world-Y, Big-Y = world-X" convention (that convention is
//   calibrated for a different raw source's own X/Y labeling; MODF's
//   (X, height, Y) slots already line up directly with Big-X/Big-Y once
//   read correctly). Confirmed empirically against two independent maps
//   (Dalaran Sewers Arena, Orgrimmar Arena): only the direct, no-swap mapping lands
//   each computed WMO tile inside its own hosting ADT tile's own Big box
//   (that box computed completely independently, via
//   TWM_Mini2Big_Coord's col/row formula on the ADT filename) -- the
//   cross-swap version put every tile in the transposed quadrant instead,
//   which is what an earlier version of this script did (visually
//   reported in-game as looking rotated).
//
// A WMO group's own local bounding box (MOGP chunk, its own file) sets the
// origin for that group's tile grid: local.X = bbox.minX + blockX*128,
// local.Y = bbox.minY + blockY*128 (128 model-units per 256px tile at
// PPU=2 -- same fixed pixels-per-unit constant as WMO dungeon interiors).
// IMPORTANT: MOGP's bbox is a plain C3Vector, (X, Y, Z=height) -- a
// DIFFERENT axis order than MODF.position/rotation's own (X, height, Y).
// bbox index 1 is the true horizontal Y axis; index 2 is height. Confirmed
// against Dalaran Sewers' own two WMO groups: only index 1's span (~147/~157
// model units, >128) is consistent with those groups actually needing 2
// blocks along Y (blockY 0 and 1 both present in the real tile list) --
// index 2's span (~77/~38, <128) would only ever need 1 block, contradicting
// the real data. An earlier version of this script read index 2 for local.Y
// (copying MODF's axis order onto MOGP by mistake) -- this produced tiles
// that still landed inside the map's own Twm_mapareas box (too coarse a
// check to catch a per-group axis mixup) but visibly misplaced in-game.
// Nominal (non-cropped) tile size is used for every block regardless of
// whether the real baked content is smaller -- the BLP's own alpha channel
// already handles that (see the alpha-aware compositing note in
// gotchas.md), so there's no need to read exact crop dimensions here.

const fs = require('fs');
const path = require('path');
const readline = require('readline');

function chunkID(a, b, c, d) { return (a.charCodeAt(0) << 24) | (b.charCodeAt(0) << 16) | (c.charCodeAt(0) << 8) | d.charCodeAt(0); }
const ID_MODF = chunkID('M', 'O', 'D', 'F');
const ID_MOGP = chunkID('M', 'O', 'G', 'P');

const MINI2BIG = 1600 / 3; // 533.3333..., matches TerrainWorldMap.lua's MINI2BIGX/Y
const MAP_ORIGIN = 32 * MINI2BIG; // 17066.666...
const PPU = 2; // pixels per world unit for WMO minimap tiles (fixed, not derived per-group)
const TILE_UNITS = 256 / PPU; // 128 model-units per 256px tile
const ROT_EPSILON = 0.05; // degrees -- MODF rotation floats aren't always exactly 0.0

// Every MODF entry (deduped by nameId) across a map's own _obj0.adt files.
function findModfPlacements(mapDir) {
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

function parseArgs(argv) {
	const opts = { flavorDir: null, listfile: null, out: null };
	const mapNames = [];
	for (let i = 0; i < argv.length; i++) {
		const a = argv[i];
		if (a === '--flavor-dir') opts.flavorDir = argv[++i];
		else if (a === '--listfile') opts.listfile = argv[++i];
		else if (a === '--out') opts.out = argv[++i];
		else if (a.startsWith('--')) throw new Error(`Unknown option: ${a}`);
		else mapNames.push(a);
	}
	return { opts, mapNames };
}

function printUsage() {
	console.error('Usage: node gen_wmo_tiles.js --flavor-dir <dir with world/maps/<map>/*_obj0.adt and extracted world/wmo/... WMOs> --listfile <community-listfile.csv> --out <out-file.lua> <MapDirectoryName> [<MapDirectoryName> ...]');
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

	if (!opts.flavorDir || !opts.listfile || !opts.out || mapNames.length === 0) {
		printUsage();
		process.exit(1);
	}

	// Gather every candidate MODF nameId across all requested maps first,
	// so the (large) listfile only needs one streaming pass.
	//
	// Deliberately NOT gated on whether the map's own outdoor terrain
	// already has real baked minimap tiles -- a map can have both (e.g.
	// Orgrimmar Arena: outdoor tiles extract fine on their own AND its WMO
	// has its own baked group tiles too) and both are wanted: the outdoor
	// tiles are the always-shown base map, the WMO tiles are what the
	// height-cutoff slider (TerrainWorldMap.lua) actually has to peel
	// through to isolate one real building level, since a flattened
	// top-down outdoor tile can't distinguish levels the way separate WMO
	// group tiles can. (An earlier version of this script skipped
	// generating WMO tiles whenever outdoor art already existed, treating
	// the two as redundant -- wrong; reverted.)
	const placementsByMap = {};
	const wantedNameIds = new Set();
	for (const mapName of mapNames) {
		const mapDir = path.join(opts.flavorDir, 'world', 'maps', mapName);
		if (!fs.existsSync(mapDir)) {
			console.error(`WARNING: ${mapName} -- no world/maps/${mapName} dir in --flavor-dir, skipping`);
			placementsByMap[mapName] = [];
			continue;
		}
		const placements = findModfPlacements(mapDir);
		placementsByMap[mapName] = placements;
		for (const p of placements) wantedNameIds.add(p.nameId);
	}

	// Single streaming pass: resolve wanted WMO nameIds to paths, and collect
	// every world/minimaps/wmo/ tile path (grouped by its stem, i.e. the
	// path with the trailing _NNN_XX_YY.blp stripped).
	const idToPath = {};
	const tilesByStem = {}; // stem -> [{groupNum, blockX, blockY, fileID}]
	const rl = readline.createInterface({ input: fs.createReadStream(opts.listfile) });
	for await (const line of rl) {
		const idx = line.indexOf(';');
		if (idx === -1) continue;
		const id = parseInt(line.slice(0, idx), 10);
		const p = line.slice(idx + 1).trim();
		if (wantedNameIds.has(id)) idToPath[id] = p;
		if (p.startsWith('world/minimaps/wmo/')) {
			const m = p.match(/^(.*)_(\d+)_(\d+)_(\d+)\.blp$/);
			if (m) {
				const [, stem, groupNum, blockX, blockY] = m;
				(tilesByStem[stem] = tilesByStem[stem] || []).push({ groupNum: parseInt(groupNum, 10), blockX: parseInt(blockX, 10), blockY: parseInt(blockY, 10), fileID: id });
			}
		}
	}

	let fullOutput = "-- GENERATED FILE -- do not hand-edit, regenerate with scripts/gen_wmo_tiles.js\n"
		+ "-- and replace this file wholesale. See scripts/README.md for details.\n"
		+ "--\n"
		+ "-- Minimap tiles for the WMO structure actually placed on a map whose\n"
		+ "-- own outdoor terrain has no baked minimap art (see this script's own\n"
		+ "-- header for the full explanation and the coordinate derivation).\n"
		+ "-- {fileID, x1, x2, y1, y2, height} per tile, x1/y1 = max, x2/y2 = min\n"
		+ "-- (same box convention as Twm_mapareas). height is MODF.position[1]\n"
		+ "-- (the placement's own world height) PLUS that specific tile's own\n"
		+ "-- WMO GROUP's height-axis center -- a single WMO placement can have\n"
		+ "-- groups at meaningfully different real heights (e.g. a raised\n"
		+ "-- walkway/balcony vs. the main floor below it), so height is tracked\n"
		+ "-- per group, not just per placement. x1/x2/y1/y2 already include a\n"
		+ "-- fixed 90-degree clockwise rotation (applied to LOCAL coordinates,\n"
		+ "-- before they ever become a world/Big position -- see the per-tile\n"
		+ "-- loop below) that corrects for a real property of Blizzard's own\n"
		+ "-- WMO-minimap-tile baking convention (see gotchas.md) -- the\n"
		+ "-- rendering side (TerrainWorldMap.lua) does NOT need to apply any\n"
		+ "-- extra rotation of its own, only the matching texture-content\n"
		+ "-- rotation (TWM_WMOOverlay_EnsureTextures' SetTexCoord). Entries are\n"
		+ "-- emitted in ascending height order (lowest first) so the addon's\n"
		+ "-- own draw order stacks higher tiles visually on top, and so the\n"
		+ "-- height-cutoff slider (TerrainWorldMap.lua) has a stable order to\n"
		+ "-- hide from the top down.\n\n"
		+ "Twm_WMOTiles = {\n";

	for (const mapName of mapNames) {
		// Placements are pre-sorted by their own height too, purely so
		// groupBoxes below is computed in a predictable order across
		// multiple placements -- the actual output order
		// guarantee comes from the mapTiles.sort() by (per-group) height
		// after the collection loop, below.
		const placements = [...placementsByMap[mapName]].sort((a, b) => a.pos[1] - b.pos[1]);
		const mapTiles = [];

		for (const p of placements) {
			const wmoPath = idToPath[p.nameId];
			if (!wmoPath) continue; // not a real WMO (e.g. an M2 doodad -- MDDF, not MODF, shouldn't happen, but be safe)

			const stem = wmoPath.replace(/\.wmo$/i, '').replace('world/wmo/', 'world/minimaps/wmo/');
			const tiles = tilesByStem[stem];
			if (!tiles || tiles.length === 0) continue; // no minimap art baked for this WMO at all

			const rotMag = Math.max(...p.rot.map(Math.abs));
			if (rotMag > ROT_EPSILON) {
				console.error(`  (skipping ${mapName}'s ${wmoPath} -- has minimap tiles but a real rotation (${p.rot.map(x => x.toFixed(2))}), not supported yet)`);
				continue;
			}

			// One group file per distinct groupNum referenced by its tiles.
			const groupNums = [...new Set(tiles.map(t => t.groupNum))];
			const groupBoxes = {};
			for (const g of groupNums) {
				const groupPath = path.join(opts.flavorDir, wmoPath.replace(/\.wmo$/i, `_${String(g).padStart(3, '0')}.wmo`));
				if (!fs.existsSync(groupPath)) {
					console.error(`  (skipping ${mapName}'s ${wmoPath} group ${g} -- ${groupPath} not extracted)`);
					continue;
				}
				groupBoxes[g] = groupBoundingBox(groupPath);
			}

			// MOGP's bbox is a plain C3Vector (X,Y,Z=height) -- unlike
			// MODF.position/rotation, which store (X,height,Y). box[1] is
			// NOT height (box[2] is), it's the real horizontal Y axis.
			// box[0] pairs directly with blockX, box[1] with blockY -- no
			// swap between them (confirmed against wow.export's own
			// src/js/wmo-minimap.js, fetched from its live GitHub source).
			//
			// wow.export's compute_minimap_layout() DOES flip Y
			// (`canvas_y = (max_y-256) - absY`) when compositing tiles into
			// an output PNG image -- this addon needs the same flip (this
			// is the step that decides which tile's pixels end up adjacent
			// to which on screen; its own separate build_world_meta(), used
			// for a JSON sidecar's whole-image corner metadata only, does
			// NOT flip and is not the right thing to copy here -- confirmed
			// live: porting build_world_meta's formula verbatim rotated the
			// overlay correctly but broke tile-to-tile adjacency).
			// Applied per-tile (there's no literal canvas here -- each tile
			// is its own Texture) using ONE max shared across every group of
			// this placement, computed in a first pass below -- a per-GROUP
			// max (tried, reverted) numerically happens to look identical
			// (both groups' block counts can coincide) but silently shifts
			// different groups' content by different absolute amounts,
			// since each group's own max is anchored to that group's own
			// bbox min. A rotation/flip must share one pivot across
			// everything it's applied to, or relative alignment between
			// groups breaks (confirmed both in an earlier rotation attempt
			// and in this flip).
			const rawTiles = tiles.map(t => {
				const box = groupBoxes[t.groupNum];
				if (!box) return null;
				const localX1 = Math.min(box.min[0], box.max[0]) + t.blockX * TILE_UNITS;
				const localY1raw = Math.min(box.min[1], box.max[1]) + t.blockY * TILE_UNITS;
				return { t, box, localX1, localY1raw };
			}).filter(Boolean);
			if (rawTiles.length === 0) continue;

			// wow.export's own real compute_minimap_layout() computes a
			// Y-flip using `max_y = max(absY + 256)` -- i.e. the largest
			// BLOCK-quantized edge, not the group's own true (continuous)
			// bounding-box edge. That's fine for wow.export's own purpose
			// (arranging blocks on a canvas, and its own build_world_meta
			// world-position sidecar inherits the same quantization, so it
			// never has to matter to them) -- but a group's real geometry
			// need not exactly fill a whole number of 128-unit blocks (e.g.
			// Orgrimmar's own group spans 241.6 units of real Y but reads
			// as 2 full blocks = 256 units, a 14.4-unit slack), so blindly
			// reusing the block-quantized max re-anchors the WHOLE result
			// with that same slack baked in as a constant absolute error.
			// This addon, unlike wow.export, HAS independent ground truth
			// to check against for one arena (Orgrimmar also has real
			// ADT-baked outdoor minimap tiles for the same building) -- a
			// pixel-for-pixel comparison against that confirmed this exact
			// slack as a real, measurable offset (Orgrimmar's WMO overlay
			// sat consistently ~14 units off from its own real minimap
			// tile, unoccluded-edge-measured across 5 rows). Fixed by
			// reflecting around the group geometry's OWN true combined
			// range instead of the block-quantized one: `trueGlobalMinY`/
			// `trueGlobalMaxY` are the min/max of every GROUP's own real
			// bbox Y bounds used by this placement (not per-tile, not
			// block-quantized). This is still ONE shared reference for the
			// whole placement (never per-group -- a per-group reference is
			// the earlier, already-reverted mistake, see gotchas.md), so it
			// cannot change any already-verified relative arrangement
			// (Dalaran's own ~21.575-unit group-to-group offset is
			// unaffected by construction, confirmed numerically before
			// shipping this).
			const trueGlobalMinY = Math.min(...Object.values(groupBoxes).map(b => Math.min(b.min[1], b.max[1])));
			const trueGlobalMaxY = Math.max(...Object.values(groupBoxes).map(b => Math.max(b.min[1], b.max[1])));

			for (const { t, box, localX1, localY1raw } of rawTiles) {
				const localX2 = localX1 + TILE_UNITS;
				const localY1 = (trueGlobalMinY + trueGlobalMaxY) - localY1raw - TILE_UNITS;
				const localY2 = localY1 + TILE_UNITS;

				// Blizzard's own WMO-group minimap baking pipeline has a
				// fixed, non-arbitrary 90-degree rotation relative to world
				// axes (see gotchas.md -- already established for the
				// separate, unshipped dungeon-interior minimap feature;
				// arenas use the exact same tile-baking system). Rather
				// than compute this placement's tiles in the wrong
				// orientation and rotate the RESULT 90 degrees clockwise
				// around the placement's own anchor at render time (tried
				// first, worked, but is an extra runtime step for
				// something that's really just a property of "local"
				// itself), apply the equivalent rotation directly to the
				// local coordinates here, before they ever become a world/
				// Big position: `(localX,localY) -> (-localY,localX)`.
				// This is provably identical to "rotate the Big-coordinate
				// result around the anchor" (both Big->local and
				// Big->mini are pure component-wise negate-scale-offset --
				// see TWM_Big2Mini_Coord -- so orientation/handedness
				// carries through unchanged from local-space all the way
				// to mini/screen-space; verified independently via a
				// concrete numeric example: a point 10 units in +local.X
				// lands 10 units below the anchor on screen after this
				// substitution, i.e. "3 o'clock" -> "6 o'clock", genuinely
				// clockwise). The rendering side (TerrainWorldMap.lua)
				// needs NO extra rotation step at all now -- it just
				// reads Big coordinates the same direct way it always
				// has. The texture CONTENT still needs its own 90-degree
				// rotation (TWM_WMOOverlay_EnsureTextures' SetTexCoord) --
				// that's a separate concern (what each tile's own pixels
				// show), unaffected by this.
				const rotLocalX1 = -localY1, rotLocalX2 = -localY2;
				const rotLocalY1 = localX1, rotLocalY2 = localX2;

				const worldXa = p.pos[0] + rotLocalX1, worldXb = p.pos[0] + rotLocalX2;
				const worldYa = p.pos[2] + rotLocalY1, worldYb = p.pos[2] + rotLocalY2;

				const bigXa = MAP_ORIGIN - worldXa, bigXb = MAP_ORIGIN - worldXb;
				const bigYa = MAP_ORIGIN - worldYa, bigYb = MAP_ORIGIN - worldYb;

				// Per-GROUP height, not just the placement's own MODF.position[1]
				// -- a single WMO placement can have groups at meaningfully
				// different real heights (e.g. a raised walkway/balcony group
				// vs. the main floor group below it; confirmed on Dalaran
				// Sewers' own two groups: box[2] -- MOGP's real height axis,
				// see the axis-order note above -- ranges [-24.17,53.05] for
				// group 0 vs [52.998,91.53] for group 1, i.e. group 1 sits
				// almost entirely above group 0, not just beside it). Using
				// only the placement's own height would flatten this into one
				// value and defeat the height-cutoff slider's purpose for
				// exactly the arenas that actually have multiple levels.
				const groupHeightCenter = (box.min[2] + box.max[2]) / 2;
				mapTiles.push({
					fileID: t.fileID,
					x1: Math.max(bigXa, bigXb), x2: Math.min(bigXa, bigXb),
					y1: Math.max(bigYa, bigYb), y2: Math.min(bigYa, bigYb),
					height: p.pos[1] + groupHeightCenter,
				});
			}
		}

		console.error(`${mapName}: ${mapTiles.length} WMO minimap tiles placed`);
		if (mapTiles.length === 0) continue;

		// Sort by height ascending -- necessary (not just the placement-level
		// pre-sort above) now that height is per-group: a single placement's
		// groups can themselves span the whole height range.
		mapTiles.sort((a, b) => a.height - b.height);

		fullOutput += `    ["${mapName}"] = {\n`;
		for (const t of mapTiles)
			fullOutput += `        {${t.fileID}, ${t.x1}, ${t.x2}, ${t.y1}, ${t.y2}, ${t.height}},\n`;
		fullOutput += '    },\n';
	}
	fullOutput += '}\n';

	fs.writeFileSync(opts.out, fullOutput);
	console.error(`\nWritten: ${opts.out}`);
}

main();
