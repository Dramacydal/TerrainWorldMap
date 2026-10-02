// Regenerates Data_<Flavor>/mapdata_wmo_tiles_<kind>.lua (Twm_WMOTiles) --
// minimap tile placement data for maps whose real terrain has no baked
// minimap art of its own (confirmed on Mists' Dalaran Sewers Arena: real
// WDT/ADT tiles exist, but zero "world/minimaps/<map>/*.blp" files do),
// while a WMO structure actually placed there DOES have its own baked
// minimap art (world/minimaps/wmo/.../<name>_<group>_<blockX>_<blockY>.blp,
// via the same per-WMO-group minimap system as WMO dungeon interiors --
// see .claude-docs/gotchas.md's "Dungeon/interior minimap tiles" section).
// Generalized (naming, no arena-specific hardcodes) so dungeons/raids can
// reuse this same script -- including a WDT-level MODF fallback for
// pure-WMO instances (most classic 5-mans/raids have no real ADT terrain
// at all, see findWdtPlacement's own header and gotchas.md's "Detecting a
// pure WMO dungeon" entry), ported from preview_wmo_tiles.js once dungeons
// actually needed it (confirmed missing: Ragefire Chasm and Onyxia's Lair
// both silently produced zero tiles despite having real baked minimap art,
// because only the per-ADT MODF scan existed here before).
//
// Which tiles belong to a placement is resolved via the `WMOMinimapTexture`
// DB2 table (ID, GroupNum, BlockX, BlockY, FileDataID, WMOID) -- NOT by
// pattern-matching tile filenames in the community listfile (an earlier,
// now-replaced approach). `WMOID` here is NOT a FileDataID -- it's a
// separate internal identifier stored in the WMO root file's own `MOHD`
// chunk (a uint32 at offset 32, right after `ambColor` and right before the
// bounding box -- see readWmoId), confirmed by direct comparison against a
// real placement (Razorfen Downs: MOHD offset 32 = 1356, and every one of
// its 32 real tiles in WMOMinimapTexture.csv carries WMOID=1356). Switched
// to this after the filename-based approach shipped 20 "ghost" tiles for
// Razorfen Downs (group 010) that the community listfile still lists (a
// stale entry from some other build) but this build's own CASC archive and
// its own WMOMinimapTexture table both agree don't exist -- confirmed via
// two independent extraction attempts (including a full wildcard sweep of
// the WMO's whole minimap directory) finding zero matching files. The DB2
// table is generated fresh per build, so it can't carry that kind of
// cross-build staleness the way the aggregate listfile can -- if Blizzard's
// own client trusts this table for the SAME feature (and evidently does,
// since nobody's reported broken native-minimap tiles from it), it's the
// right source of truth here too.
//
// SCOPE: yaw (MODF.rotation[1]) is supported; pitch/roll aren't -- every
// real placement checked so far (a broad sample: arenas, Shadowfang Keep,
// ~20 WDT-only dungeons/raids) is yaw-only, never pitch/roll, so a
// placement with real pitch/roll is skipped with a warning rather than
// guessed at.
//
// Since a tile is no longer necessarily axis-aligned once yaw is nonzero,
// each tile tuple is a center+size+angle one, plus the real corners:
// {fileID, cx, cy, width, height, yawDeg, z, c1x,c1y, c2x,c2y, c3x,c3y,
// c4x,c4y} -- see the output writer below and TerrainWorldMap.lua's
// TWM_WMOOverlay_Update (Texture:SetPoint/SetRotation for the tile itself,
// Line-based debug border from the corners) for the reader side.
// width/height/z keep the same meaning as before (z is the world-height
// value the cutoff slider reads), just shifted by one field for yawDeg.
// The 4 corners are redundant with cx/cy/width/height/yawDeg -- kept
// anyway so the debug border can draw the tile's true outline directly
// instead of re-deriving it from those in Lua a second time.
//
// Twm_WMOTiles["<name>"] itself is an array of GROUPS, not a flat tile
// array (WMO tile group management -- lets the addon show a per-group
// checkbox list, TerrainWorldMap.lua's TWM_EnsureWMOGroupCheckboxes):
// {group_id, group_name, tiles = {<tile tuple>, ...}}, sorted by (wmoId,
// GroupNum) ascending. group_id is "<wmoId>-<GroupNum>" (a string) -- NOT
// just WMOMinimapTexture.csv's own GroupNum by itself, because a map can
// have more than one WMO placed on it (e.g. PVPLordaeron: the actual arena
// building plus an unrelated second building), and each placement numbers
// its own groups from 0 independently -- grouping by GroupNum alone
// silently merged different placements' same-numbered groups into one,
// scrambling names and tiles together. wmoId (WMOMinimapTexture.csv's own
// WMOID, already resolved per placement below) is unique per real placed
// building, so prefixing it makes group_id unique per real physical group
// on the whole map. group_name is read from the root WMO file's own MOGN/
// MOGI chunks (readWmoGroupNames below), falling back to a plain
// "Group <GroupNum>" for a group with no real name (MOGI's own nameOffset
// -1).
//
// yawDeg is written out as -MODF.rotation[1] -- the SAME value already used
// (as radians) to rotate local coordinates in the position formula below,
// not a separately re-derived angle. Justified by tracing that formula's
// own downstream effect on the screen, algebraically, instead of counting
// reflections by eye (an earlier pass at this comment did that and got it
// wrong): position ultimately becomes a screen anchor offset via
// `mini = Big/(-MINI2BIGX) + 32` (TWM_Big2Mini_Coord, a uniform scale --
// same factor both axes) then `screenX = (mini_x-Lx)*z, screenY = (Ly-mini_y)*z`
// (TWM_WMOOverlay_Update) -- carrying a local-space point (rlx,rly) through
// both, screenX ends up proportional to +finalLocalX but screenY to
// -finalLocalY (the two per-axis constants end up with opposite sign,
// unlike X). Since finalLocalX = rlx*cosT-rly*sinT, finalLocalY =
// rlx*sinT+rly*cosT (this same file's rotation step, T = -MODF.rotation[1]
// in radians), that sign flip on Y alone turns the standard
// counterclockwise rotation matrix into a CLOCKWISE one once expressed in
// (screenX,screenY) -- i.e. this pipeline already draws the position
// clockwise for positive T, so Texture:SetRotation needs that identical T
// to keep the drawn CONTENT turning the same way, assuming SetRotation's
// own positive-radians convention is also "clockwise on screen" (the usual
// one, but not yet confirmed for this client specifically).
//
// NOT yet live-tested (this addon doesn't have a dungeon/raid dropdown
// category yet to view Shadowfang through) -- Tol'Viron Arena (already
// dropdown-selectable, real yaw, real decorative WMOs) is the nearest live
// test available; flip the sign in the output writer below (one line) if
// its WMO layer looks mirrored/backwards in-game.
//
// Coordinate derivation (verified against this map's own already-computed
// Twm_mapareas box, itself from valid-tile extent -- see gen_arenas.js):
//   MODF.position is (X, height, Y) -- height is the middle component (a
//   small value, confirmed: e.g. Dalaran Sewers' own placement has
//   position=(16278.01, 6.17, 15765.27), and 6.17 is obviously not a
//   ground-plane coordinate for content sized in the thousands).
//   World.X = anchor.X + local.X, World.Y = anchor.Y + local.Y (rotated by
//   this placement's own yaw first -- see rotateOnly below).
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
//   `anchor` is raw MODF.position. The model's local Y is mirrored about
//   local 0 before the yaw rotation (see the per-placement loop).
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
// A WMO-group minimap BLP is cropped by Blizzard to its real content size,
// not always 256x256 (confirmed: sizes as small as 32x32 exist, e.g.
// Tol'Viron Arena's pirate-ship bridge). This script used to assume nominal
// (non-cropped) tile size for every block regardless of the real file size,
// reasoning the BLP's own alpha channel would handle the difference --
// WRONG: alpha only controls transparency, not scale. TerrainWorldMap.lua's
// tex:SetWidth/SetHeight STRETCHES whatever the real file is to fill the
// given box, so sizing that box to the nominal 128-unit block regardless of
// a smaller real file distorts/smears the content (confirmed live: Tol'Viron
// Arena's bridge, every tile 32-64px on a side, looked exactly like this).
// Real per-tile width/height (read from each BLP's own header below) fixes
// this -- see the per-tile loop's own comment for the corner-math change
// this implies.

const fs = require('fs');
const path = require('path');
const readline = require('readline');
const { Blp } = require('@wowserhq/format');
const { flavorDir, listfilePath, ensureExtracted, ensureExtractedPaths, ensureExtractedFileDataIds, ensureDb2Csv, envOr, resolveMapKeys } = require('./extract');
const { skipWmoTiles, skipTileFileDataId, skipWmoGroups, checkedWmoAreasByMap, isSkipped, isWmoTileInCheckedArea } = require('./skip_lists');
const { getValidTiles } = require('./parse_wdt');

const escapeRegExp = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

// Real (possibly cropped) pixel dimensions straight from the BLP header --
// no full pixel decode needed, just width/height.
function blpDimensions(filePath) {
	const blp = new Blp();
	blp.load(fs.readFileSync(filePath));
	return { width: blp.width, height: blp.height };
}

function chunkID(a, b, c, d) { return (a.charCodeAt(0) << 24) | (b.charCodeAt(0) << 16) | (c.charCodeAt(0) << 8) | d.charCodeAt(0); }
const ID_MPHD = chunkID('M', 'P', 'H', 'D');
const ID_MODF = chunkID('M', 'O', 'D', 'F');
const ID_MOGP = chunkID('M', 'O', 'G', 'P');
const ID_MOHD = chunkID('M', 'O', 'H', 'D');
const ID_MOGN = chunkID('M', 'O', 'G', 'N');
const ID_MOGI = chunkID('M', 'O', 'G', 'I');

const MINI2BIG = 1600 / 3; // 533.3333..., matches TerrainWorldMap.lua's MINI2BIGX/Y
const MAP_ORIGIN = 32 * MINI2BIG; // 17066.666...
const PPU = 2; // pixels per world unit for WMO minimap tiles (fixed, not derived per-group)
const TILE_UNITS = 256 / PPU; // 128 model-units per 256px tile
const ROT_EPSILON = 0.05; // degrees -- MODF rotation floats aren't always exactly 0.0

// Every MODF entry (deduped by uniqueId -- one placement spanning several ADT tiles repeats; distinct placements of the same WMO don't) across a map's own _obj0.adt files --
// only the ones the WDT's own MAIN/MAID chunk actually declares as real,
// obj0ADT-backed tiles (validTileKeys, from parse_wdt.js's getValidTiles(),
// 'obj0ADT' field -- a tile can have real terrain with no object placements
// at all, so this is deliberately NOT the same 'rootADT' check
// Twm_WDTValidTiles itself uses).
// CASC/the community listfile can contain a stray _obj0.adt for a tile the
// client itself doesn't consider real terrain (same class of staleness as
// the WMOMinimapTexture ghost-tile fix above, see .claude-docs/gotchas.md)
// -- trusting "this file exists and got extracted" alone isn't enough.
function findModfPlacements(mapDir, validTileKeys) {
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
					const uniqueId = buf.readUInt32LE(b + 4);
					if (seen.has(uniqueId)) continue;
					seen.add(uniqueId);
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

// A "pure WMO" map (no real ADT terrain at all -- most classic 5-man
// dungeons/raids, e.g. Ragefire Chasm, Onyxia's Lair) places its one global
// WMO via a WDT-level MODF instead of any per-ADT one, guarded by
// MPHD.flags & 0x1 (wdt_uses_global_map_obj) -- see .claude-docs/
// gotchas.md's "Detecting a pure WMO dungeon" entry. Ported from
// preview_wmo_tiles.js's own findWdtPlacement (validated there first,
// offline, before landing here) -- this was the one gap the header comment
// already flagged as "not yet implemented" when yaw support landed.
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

// The WMO root file's own internal WMOID (MOHD chunk, offset 32 -- right
// after nTextures/nGroups/nPortals/nLights/nDoodadNames/nDoodadDefs/
// nDoodadSets (4 bytes each, offsets 0-24) and ambColor (4 bytes, offset 28),
// right before the bounding box (offset 36/48, already read elsewhere) --
// see this file's header for how this offset was confirmed, not assumed).
// This is the join key WMOMinimapTexture.csv's own `WMOID` column uses --
// unrelated to any FileDataID.
function readWmoId(rootWmoPath) {
	const buf = fs.readFileSync(rootWmoPath);
	let offset = 0;
	while (offset + 8 <= buf.length) {
		const magic = buf.readUInt32LE(offset);
		const size = buf.readUInt32LE(offset + 4);
		const dataStart = offset + 8;
		if (magic === ID_MOHD) return buf.readUInt32LE(dataStart + 32);
		offset = dataStart + size;
	}
	return null;
}

function readCString(buf, offset) {
	let end = offset;
	while (end < buf.length && buf[end] !== 0) end++;
	return buf.toString('utf8', offset, end);
}

// MOGI (root WMO file, nGroups x 32-byte entries: flags(4) + bbox min/max
// C3Vector(12+12) + nameOffset int32(4)) gives each group's own offset into
// MOGN (root file, a blob of null-terminated strings -- same convention as
// MOTX's texture-path blob), or -1 if that group genuinely has no name.
// Group index here is 0-based and matches WMOMinimapTexture.csv's own
// GroupNum column directly (confirmed empirically against a real extracted
// root file: pvp_lordaeron_arena.wmo's 5 MOGI entries resolved to "Arena"/
// "InteriorStatues"/"InteriorStatuesTop" plus 2 unnamed (-1) groups).
// Returns Map<groupIndex, name|null>, empty if this WMO has no MOGI at all.
function readWmoGroupNames(rootWmoPath) {
	const buf = fs.readFileSync(rootWmoPath);
	let offset = 0;
	let mogn = null, mogi = null;
	while (offset + 8 <= buf.length) {
		const magic = buf.readUInt32LE(offset);
		const size = buf.readUInt32LE(offset + 4);
		const dataStart = offset + 8;
		if (magic === ID_MOGN) mogn = buf.slice(dataStart, dataStart + size);
		else if (magic === ID_MOGI) mogi = buf.slice(dataStart, dataStart + size);
		offset = dataStart + size;
	}
	const names = new Map();
	if (!mogi) return names;
	const count = Math.floor(mogi.length / 32);
	for (let i = 0; i < count; i++) {
		const nameOffset = mogi.readInt32LE(i * 32 + 28);
		names.set(i, (mogn && nameOffset >= 0 && nameOffset < mogn.length) ? readCString(mogn, nameOffset) : null);
	}
	return names;
}

// WMOMinimapTexture.csv -> Map<WMOID (string), [{groupNum, blockX, blockY,
// fileID}]>. Authoritative source for which baked minimap tiles belong to a
// given WMO -- see this file's header for why this replaced filename
// pattern-matching against the community listfile.
function loadWmoMinimapTexture(csvPath) {
	const { parseCsvFile } = require('./csv');
	const rows = parseCsvFile(csvPath);
	const byWmoId = new Map();
	for (const r of rows) {
		const list = byWmoId.get(r.WMOID) || [];
		list.push({
			groupNum: parseInt(r.GroupNum, 10),
			blockX: parseInt(r.BlockX, 10),
			blockY: parseInt(r.BlockY, 10),
			fileID: parseInt(r.FileDataID, 10),
		});
		byWmoId.set(r.WMOID, list);
	}
	return byWmoId;
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
	const opts = {
		workDir: null, flavor: null, clientDir: null, online: false, clientLocale: 'enUS',
		out: null, force: false, proxy: null, maps: null, candidatesKind: null,
	};
	for (let i = 0; i < argv.length; i++) {
		const a = argv[i];
		if (a === '--work-dir') opts.workDir = argv[++i];
		else if (a === '--flavor') opts.flavor = argv[++i];
		else if (a === '--client-dir') opts.clientDir = argv[++i];
		else if (a === '--online') opts.online = true;
		else if (a === '--client-locale') opts.clientLocale = argv[++i];
		else if (a === '--out') opts.out = argv[++i];
		else if (a === '--force') opts.force = true;
		else if (a === '--proxy') opts.proxy = argv[++i];
		else if (a === '--maps') opts.maps = argv[++i];
		else if (a === '--candidates') opts.candidatesKind = argv[++i];
		else throw new Error(`Unknown option: ${a}`);
	}
	return opts;
}

function printUsage() {
	console.error('Usage: node gen_wmo_tiles.js --work-dir <dir> --flavor <product> (--client-dir <path> | --online) --out <out-file.lua> (--candidates <dungeons|raids|arenas> | --maps <Name1,Name2,...>) [--force] [--proxy <url>]');
	console.error('  --candidates reads <work-dir>/<flavor>/candidates/<kind>.json (scripts/gen_candidates.js, run that first) --');
	console.error('  continents/battlegrounds never have any baked WMO tiles, only dungeons/raids/arenas do, so those are the');
	console.error('  only 3 valid kinds here. --maps is an explicit comma-separated override for ad-hoc/manual use.');
	console.error('  Self-extracts (via CASCConsole) each map\'s obj0 ADTs/WDT, then -- once MODF placements are');
	console.error('  resolved against the community listfile and each root WMO\'s own WMOID against WMOMinimapTexture.csv --');
	console.error('  exactly the WMO group/minimap files they need.');
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

	if (!opts.workDir || !opts.flavor || !opts.out) {
		printUsage();
		process.exit(1);
	}
	let mapNames;
	try {
		mapNames = resolveMapKeys({ maps: opts.maps, candidatesKind: opts.candidatesKind, workDir: opts.workDir, flavor: opts.flavor });
	} catch (e) {
		console.error(e.message);
		printUsage();
		process.exit(1);
	}
	if (mapNames.length === 0) {
		console.error(`No maps to process (candidates/${opts.candidatesKind}.json is empty) -- nothing to do.`);
		process.exit(0);
	}

	const flavorDirPath = flavorDir(opts.workDir, opts.flavor);
	const extractOpts = {
		workDir: opts.workDir, flavor: opts.flavor,
		clientDir: opts.clientDir, online: opts.online, clientLocale: opts.clientLocale,
		force: opts.force,
	};
	// See the per-tile loop below (rawTiles) for where this is actually
	// checked -- a fileID-level skip, independent of skipMaps/skipWmoTiles
	// above (those drop a whole map; this drops one bad baked tile texture
	// wherever it's referenced).
	const skipTileIdSet = new Set(skipTileFileDataId[opts.flavor] || []);
	const skipGroupIdSet = new Set(skipWmoGroups[opts.flavor] || []);

	// skip_lists.js is keyed by Map.csv `ID`, not Directory name -- only load
	// Map.csv (an extra download/parse this script otherwise never needs) when
	// this flavor's own skipWmoTiles actually has something to check against.
	// skipWmoTiles' net effect (no Twm_WMOTiles entry for it) is identical to
	// never having been asked for it at all. skipMaps itself is NOT checked
	// here (or in parse_wdt.js) at all -- with --candidates, a skipped map is
	// already absent from candidates/<kind>.json (gen_candidates.js applies
	// skipMaps once, when building it), so re-checking here would only ever
	// be dead code; with --maps, an explicitly hand-listed map is exactly a
	// debug/manual override, and silently dropping it anyway would defeat
	// that override's entire point -- skipMaps is a "never a real candidate"
	// list, not a "never process no matter what" one.
	if ((skipWmoTiles[opts.flavor] || []).length > 0) {
		const { parseCsvFile, findCsv } = require('./csv');
		ensureDb2Csv({ ...extractOpts, table: 'Map', proxy: opts.proxy });
		const directoryToID = {};
		for (const r of parseCsvFile(findCsv(flavorDirPath, 'Map.')))
			directoryToID[r.Directory] = r.ID;

		mapNames = mapNames.filter(m => {
			const mapID = directoryToID[m];
			if (isSkipped(skipWmoTiles, opts.flavor, mapID)) {
				console.error(`${m}: skipping WMO tiles (skip_lists.js's skipWmoTiles)`);
				return false;
			}
			return true;
		});
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
	// Phase 1: self-extract every requested map's obj0 ADTs (per-tile MODF
	// source) and its own WDT (for the pure-WMO WDT-level MODF fallback) in
	// ONE combined CASCConsole call, not one call per map -- each launch
	// pays its own ~20s CASC/listfile startup cost regardless of how little
	// it has to extract (confirmed: this exact per-item pattern already had
	// to be batched out of parse_wdt.js/gen_instance_maps.js after real
	// multi-map runs hung for many minutes on nothing but that overhead).
	if (mapNames.length > 0) {
		// Cache-hit check is deliberately NOT "does the map's .wdt exist" --
		// parse_wdt.js (run earlier in the normal pipeline order) already
		// extracts WDT+root-ADT without ever touching obj0 files, so a WDT
		// already being present proves nothing about obj0 (confirmed: this
		// silently skipped obj0 extraction entirely for every map that had
		// already been through parse_wdt.js, producing 0 WMO tiles for maps
		// that genuinely have real placements). Check for at least one real
		// obj0 file per map instead -- exact obj0 filenames aren't knowable
		// in advance (tile-position-dependent), so this is a directory scan,
		// not a fixed checkPaths list; ensureExtracted's own array-of-exact-
		// paths check can't express that, so its cache check is bypassed
		// (checkPaths: []) and this replaces it.
		//
		// A pure-WMO map (Ragefire Chasm, Onyxia's Lair, most classic 5-mans
		// -- see findWdtPlacement's header) genuinely has ZERO obj0 files by
		// design, not because it's un-extracted -- the plain "any obj0 file
		// present" scan below can't tell those apart, so it flagged every
		// pure-WMO map as needing extraction forever, which made `.some()`
		// return true for basically any real map list (dungeons/raids are
		// mostly pure-WMO) and forced a full re-extraction on EVERY run
		// regardless of --force. Fixed: once a map's own WDT is present,
		// check MPHD's global-WMO flag first (via findWdtPlacement, already
		// used below for the real placement lookup) -- a genuine pure-WMO
		// map short-circuits to "cache hit" without ever looking for obj0
		// files at all.
		const needsExtraction = mapNames.some(m => {
			const dir = path.join(flavorDirPath, 'world', 'maps', m);
			const wdtPath = path.join(dir, `${m}.wdt`);
			if (!fs.existsSync(wdtPath)) return true;
			if (findWdtPlacement(wdtPath).length > 0) return false;
			return !fs.readdirSync(dir).some(f => /_obj0\.adt$/i.test(f));
		});
		if (needsExtraction || extractOpts.force) {
			const escapedNames = mapNames.map(escapeRegExp);
			const contAlt = escapedNames.join('|');
			// obj0 filenames embed the map's own directory stem as a literal
			// prefix (e.g. "stratholme raid_37_24_obj0.adt", "zul'gurub_33_52_
			// obj0.adt") -- \w excludes space/apostrophe/etc, so a map whose
			// Directory has either (Stratholme Raid, Zul'gurub -- confirmed,
			// not hypothetical) never matched this pattern at all, its obj0
			// extraction silently found nothing every single time, and
			// needsExtraction above stayed permanently true for any map list
			// containing one -- forcing a full re-extraction on every run
			// regardless of --force. [^/]+ (only excludes the path
			// separator, matching the .wdt alternative's own convention)
			// instead of \w+ fixes this for any punctuation, not just these
			// two known cases.
			ensureExtracted({
				...extractOpts,
				pattern: `^world/maps/(${contAlt})/([^/]+\\.wdt|[^/]+_obj0\\.adt)$`,
				checkPaths: [],
			});
		} else {
			console.error('  already extracted (obj0 present for every requested map), skipping (use --force to re-extract)');
		}
	}

	for (const mapName of mapNames) {
		const mapDir = path.join(flavorDirPath, 'world', 'maps', mapName);
		if (!fs.existsSync(mapDir)) {
			console.error(`WARNING: ${mapName} -- no world/maps/${mapName} dir after extraction (map name not found in this flavor), skipping`);
			placementsByMap[mapName] = [];
			continue;
		}
		const validTileKeys = new Set(getValidTiles(path.join(mapDir, `${mapName}.wdt`), 'obj0ADT'));
		let placements = findModfPlacements(mapDir, validTileKeys);
		if (placements.length === 0) {
			// No per-ADT MODF at all -- try the WDT-level global placement
			// (pure-WMO map, no real ADT terrain) before giving up.
			placements = findWdtPlacement(path.join(mapDir, `${mapName}.wdt`));
		}
		placementsByMap[mapName] = placements;
		for (const p of placements) wantedNameIds.add(p.nameId);
	}

	// Pass 1: resolve wanted WMO nameIds to their root .wmo paths (one
	// listfile stream).
	const idToPath = {};
	{
		const rl = readline.createInterface({ input: fs.createReadStream(listfilePath(opts.workDir)) });
		for await (const line of rl) {
			const idx = line.indexOf(';');
			if (idx === -1) continue;
			const id = parseInt(line.slice(0, idx), 10);
			if (wantedNameIds.has(id)) idToPath[id] = line.slice(idx + 1).trim();
		}
	}

	// Phase 1.5: batch-extract every wanted root .wmo file -- needed now to
	// read each one's own internal WMOID (MOHD chunk, see readWmoId), the
	// join key into WMOMinimapTexture.csv below. Previously this script
	// never touched root files at all (only gen_instance_maps.js's pure-WMO
	// box fallback did); reading WMOID is the reason that changed.
	const wantedWmoPaths = [...new Set(Object.values(idToPath))];
	if (wantedWmoPaths.length > 0) ensureExtractedPaths({ ...extractOpts, paths: wantedWmoPaths });

	const wmoIdByNameId = {};
	const groupNamesByNameId = {};
	for (const [nameId, wmoPath] of Object.entries(idToPath)) {
		const localPath = path.join(flavorDirPath, wmoPath);
		if (!fs.existsSync(localPath)) continue;
		wmoIdByNameId[nameId] = readWmoId(localPath);
		groupNamesByNameId[nameId] = readWmoGroupNames(localPath);
	}

	// WMOMinimapTexture.csv: the authoritative {groupNum, blockX, blockY,
	// fileID} list per WMOID -- see this file's header for why this
	// replaced filename pattern-matching against the community listfile.
	ensureDb2Csv({ ...extractOpts, table: 'WMOMinimapTexture', proxy: opts.proxy });
	const { findCsv } = require('./csv');
	const tilesByWmoId = loadWmoMinimapTexture(findCsv(flavorDirPath, 'WMOMinimapTexture.'));

	// Pass 2: resolve every wanted tile's own FileDataID to its listfile
	// name, if it has one -- only to know where CASCConsole puts the file
	// after extracting it by FileDataID (named files at their own path,
	// unnamed ones at unknown/FILEDATA_<id>, see tileLocalRel below).
	// Gathered only now that WMOMinimapTexture has narrowed this down to
	// exactly the fileIDs actually referenced by a placement in this run.
	const wantedFileIds = new Set();
	for (const wmoId of Object.values(wmoIdByNameId)) {
		if (wmoId == null) continue;
		for (const t of tilesByWmoId.get(String(wmoId)) || []) wantedFileIds.add(t.fileID);
	}
	const fileIdToPath = {};
	if (wantedFileIds.size > 0) {
		const rl = readline.createInterface({ input: fs.createReadStream(listfilePath(opts.workDir)) });
		for await (const line of rl) {
			const idx = line.indexOf(';');
			if (idx === -1) continue;
			const id = parseInt(line.slice(0, idx), 10);
			if (wantedFileIds.has(id)) fileIdToPath[id] = line.slice(idx + 1).trim();
		}
	}

	// Where a tile's BLP ends up locally. The tile is requested by FileDataID
	// (the ID comes straight from WMOMinimapTexture), so it does not matter
	// whether the community listfile has a name for it yet -- a brand new
	// build's tiles usually have none.
	const tileLocalRel = (fileID) => fileIdToPath[fileID] || `unknown/FILEDATA_${fileID}`;

	// Phase 2: now that every placement's real tile list is known (from the
	// DB2 table, not a directory/filename scan), self-extract exactly the
	// group model files (by path) + minimap BLPs (by FileDataID) those tiles
	// actually need.
	const neededPaths = new Set();
	const neededTileFiles = new Map();
	for (const mapName of mapNames) {
		for (const p of placementsByMap[mapName] || []) {
			const wmoPath = idToPath[p.nameId];
			const wmoId = wmoIdByNameId[p.nameId];
			if (!wmoPath || wmoId == null) continue;
			const tiles = tilesByWmoId.get(String(wmoId));
			if (!tiles || tiles.length === 0) continue;
			for (const g of new Set(tiles.map(t => t.groupNum)))
				neededPaths.add(wmoPath.replace(/\.wmo$/i, `_${String(g).padStart(3, '0')}.wmo`));
			for (const t of tiles) {
				if (skipTileIdSet.has(String(t.fileID))) continue;
				neededTileFiles.set(t.fileID, { id: t.fileID, rel: tileLocalRel(t.fileID) });
			}
		}
	}
	if (neededTileFiles.size > 0) {
		ensureExtractedFileDataIds({ ...extractOpts, files: [...neededTileFiles.values()] });
	}
	if (neededPaths.size > 0) {
		const pathList = [...neededPaths];
		// ensureExtractedPaths, not ensureExtracted with a hand-built
		// alternation -- a handful of large dungeons/raids at once can need
		// hundreds of individual group/tile paths, and one combined regex
		// over all of them blows past Windows' ~32767-char command-line cap
		// (confirmed: ENAMETOOLONG at 160000+ chars on a real TBC dungeon
		// batch). This chunks into as many CASCConsole calls as needed.
		ensureExtractedPaths({ ...extractOpts, paths: pathList });
	}

	let fullOutput = "-- GENERATED FILE -- do not hand-edit, regenerate with scripts/gen_wmo_tiles.js\n"
		+ "-- and replace this file wholesale. See scripts/README.md for details.\n"
		+ "--\n"
		+ "-- Minimap tiles for the WMO structure actually placed on a map whose\n"
		+ "-- own outdoor terrain has no baked minimap art (see this script's own\n"
		+ "-- header for the full explanation and the coordinate derivation).\n"
		+ "-- {fileID, cx, cy, width, height, yawDeg, z} per tile -- cx/cy is the\n"
		+ "-- tile's own center (Big coordinates), width/height its real size\n"
		+ "-- (Big-coordinate units, i.e. already through the fixed 90-degree\n"
		+ "-- baking rotation below), yawDeg the angle TerrainWorldMap.lua feeds\n"
		+ "-- straight to Texture:SetRotation (already sign-corrected for this\n"
		+ "-- addon's own coordinate conventions -- see this file's header), and\n"
		+ "-- z is MODF.position[1] (the placement's own world height) PLUS that\n"
		+ "-- specific tile's own WMO GROUP's height-axis center -- a single WMO\n"
		+ "-- placement can have groups at meaningfully different real heights\n"
		+ "-- (e.g. a raised walkway/balcony vs. the main floor below it), so z\n"
		+ "-- is tracked per group, not just per placement. Was a plain\n"
		+ "-- axis-aligned {fileID, x1, x2, y1, y2, height} box before yaw support\n"
		+ "-- -- a rotated tile isn't axis-aligned, so center+size+angle replaced\n"
		+ "-- it; TerrainWorldMap.lua's TWM_WMOOverlay_Update reads this shape.\n"
		+ "-- Tiles within each group are emitted in ascending z order for\n"
		+ "-- readability, but the addon's own draw order/height-cutoff filtering\n"
		+ "-- is recomputed at runtime across every group's tiles combined (which\n"
		+ "-- ones are even visible depends on live per-group checkbox state) --\n"
		+ "-- see TWM_WMOOverlay_Update. Trailing {c1x,c1y, c2x,c2y, c3x,c3y,\n"
		+ "-- c4x,c4y} (8 more fields, Big coordinates) are the tile's own real 4\n"
		+ "-- corners, redundant with cx/cy/width/height/yawDeg but computed\n"
		+ "-- directly (not re-derived from those) -- TWM_DebugTiles draws the\n"
		+ "-- outline from these via Line, point-to-point, not by re-rotating\n"
		+ "-- anything in Lua a second time.\n"
		+ "-- Twm_WMOTiles itself is declared once, centrally, in mapdata_zones.lua\n"
		+ "-- (this file, and its dungeons/raids/arenas siblings, only assign their\n"
		+ "-- own Twm_WMOTiles[\"<name>\"] key) -- see Twm_WDTValidTiles there for why.\n\n";

	// checkedWmoAreasByMap (skip_lists.js) is an opt-in per-map allowlist --
	// only load Map.csv for the Directory->ID lookup it needs when this
	// flavor's own list actually has at least one map worth checking.
	let directoryToIDForAreas = null;
	if (Object.keys(checkedWmoAreasByMap[opts.flavor] || {}).length > 0) {
		const { parseCsvFile, findCsv } = require('./csv');
		ensureDb2Csv({ ...extractOpts, table: 'Map', proxy: opts.proxy });
		directoryToIDForAreas = {};
		for (const r of parseCsvFile(findCsv(flavorDirPath, 'Map.')))
			directoryToIDForAreas[r.Directory] = r.ID;
	}

	for (const mapName of mapNames) {
		const mapID = directoryToIDForAreas && directoryToIDForAreas[mapName];

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

			const wmoId = wmoIdByNameId[p.nameId];
			if (wmoId == null) {
				console.error(`  (skipping ${mapName}'s ${wmoPath} -- couldn't read its own WMOID from MOHD, not extracted locally?)`);
				continue;
			}
			const tiles = tilesByWmoId.get(String(wmoId));
			if (!tiles || tiles.length === 0) continue; // no minimap art baked for this WMO at all

			const pitchRollMag = Math.max(Math.abs(p.rot[0]), Math.abs(p.rot[2]));
			if (pitchRollMag > ROT_EPSILON) {
				console.error(`  (skipping ${mapName}'s ${wmoPath} -- has minimap tiles but a real pitch/roll (${p.rot.map(x => x.toFixed(2))}), not supported)`);
				continue;
			}
			const yawRad = -p.rot[1] * Math.PI / 180;
			const cosT = Math.cos(yawRad), sinT = Math.sin(yawRad);
			// rotateOnly: the rotation-only half of the placement transform
			// (fixed 90-degree baking step + this placement's own real yaw),
			// with NO translation added -- i.e. where a local point ends up
			// in Big-space if this placement's own anchor (MODF.position)
			// were sitting at Big (0,0). Big = MAP_ORIGIN - World and
			// World = pos + finalLocal are both linear in `pos`, so
			// subtracting them out like this is exact, not an approximation
			// -- confirmed: toBig(x,y) - toBig(0,0) == rotateOnly(x,y) for
			// any x,y,pos (this is just algebra, not a new assumption).
			function rotateOnly(rotLocalX, rotLocalY) {
				const finalLocalX = rotLocalX * cosT - rotLocalY * sinT;
				const finalLocalY = rotLocalX * sinT + rotLocalY * cosT;
				return [-finalLocalX, -finalLocalY];
			}
			// Anchor = raw MODF.position. MODF.extents agrees with it for real
			// placements: extents center = pos + R*(bboxCx, -bboxCy), i.e. the
			// model's local Y is mirrored about local 0 (see
			// audit_wmo_extents.js, 875/951 within 1 unit).
			const anchorBigX = MAP_ORIGIN - p.pos[0];
			const anchorBigY = MAP_ORIGIN - p.pos[2];
			const anchorHeight = p.pos[1];
			function toBig(rotLocalX, rotLocalY) {
				const off = rotateOnly(rotLocalX, rotLocalY);
				return [anchorBigX + off[0], anchorBigY + off[1]];
			}

			// One group file per distinct groupNum referenced by its tiles.
			const groupNums = [...new Set(tiles.map(t => t.groupNum))];
			const groupBoxes = {};
			for (const g of groupNums) {
				const groupPath = path.join(flavorDirPath, wmoPath.replace(/\.wmo$/i, `_${String(g).padStart(3, '0')}.wmo`));
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

			for (const { t, box, localX1, localY1raw } of rawTiles) {
				// A bad/misplaced baked tile texture (e.g. a leftover
				// placeholder), hand-listed in skip_lists.js's
				// skipTileFileDataId -- shouldn't render no matter which
				// system references that same FileDataID (see parse_wdt.js
				// for the ADT-side half of this same filter).
				if (skipTileIdSet.has(String(t.fileID))) continue;
				if (skipGroupIdSet.has(`${wmoId}-${t.groupNum}`)) continue;

				// Real crop size (see this file's header) replaces the
				// nominal TILE_UNITS for THIS tile's own span. X: localX1 is
				// the near edge, so just add the real width. Y: same, localY1raw
				// is the near edge and the far edge is the real height away.
				// No BLP in the client (listed in WMOMinimapTexture/listfile
				// but absent from the build) => nothing to draw: skip.
				const blpPath = path.join(flavorDirPath, tileLocalRel(t.fileID));
				if (!fs.existsSync(blpPath)) {
					console.error(`  (warning: ${mapName}'s tile FileDataID ${t.fileID} not in client -- skipped)`);
					continue;
				}
				const dim = blpDimensions(blpPath);
				const realW = dim.width, realH = dim.height;

				const localX2 = localX1 + realW / PPU;
				const localYNear = localY1raw;
				const localYFar = localY1raw + realH / PPU;

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
				// clockwise). The texture CONTENT still needs its own
				// 90-degree rotation (TWM_WMOOverlay_EnsureTextures'
				// SetTexCoord) -- that's a separate concern (what each
				// tile's own pixels show), unaffected by this.
				//
				// Real yaw applies right after this fixed 90-degree step and
				// right before translating by MODF.position (toBig, defined
				// above) -- same slot the fixed step itself occupies, just
				// an additional rotation on top. Evaluated at all 4 corners
				// now, not 2 -- a yawed tile is no longer axis-aligned, so a
				// 2-corner diagonal can't describe it (see this file's
				// header for the tuple shape + sign).
				const c1 = toBig(localYFar, localX1);
				const c2 = toBig(localYNear, localX1);
				const c3 = toBig(localYNear, localX2);
				const c4 = toBig(localYFar, localX2);

				// checkedWmoAreasByMap (skip_lists.js) -- an opt-in per-map
				// allowlist: when this map has one, a tile only survives if
				// its own axis-aligned bbox (from these same 4 real corners)
				// is fully inside at least one listed area. No entry for this
				// map at all (the overwhelmingly common case) is a no-op.
				const cornerXs = [c1[0], c2[0], c3[0], c4[0]], cornerYs = [c1[1], c2[1], c3[1], c4[1]];
				const tileBox = {
					xmin: Math.min(...cornerXs), xmax: Math.max(...cornerXs),
					ymin: Math.min(...cornerYs), ymax: Math.max(...cornerYs),
				};
				if (mapID && !isWmoTileInCheckedArea(opts.flavor, mapID, tileBox)) continue;

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
				// The group's LOWEST Z (min of both bbox corners), not its centre: this is
				// also wow.export's own draw-order key (wmo-minimap.js,
				// zOrder = min(boundingBox1.z, boundingBox2.z)), and the
				// addon stacks groups in ascending order of it.
				const groupHeightKey = Math.min(box.min[2], box.max[2]);
				const groupNames = groupNamesByNameId[p.nameId];
				mapTiles.push({
					fileID: t.fileID,
					// groupNum alone (the WMO's own local group index) is NOT
					// unique across a map with more than one WMO placement --
					// two unrelated buildings both number their own groups
					// from 0 (confirmed: PVPLordaeron places both the actual
					// arena WMO -- 5 real groups, Arena/InteriorStatues/... --
					// and a second, unrelated building -- 11 more groups --
					// whose group 0-4 collided with the arena's own and
					// silently overwrote its names/tiles when grouped by
					// groupNum alone). wmoId (WMOMinimapTexture.WMOID, already
					// resolved above) is unique per real placed building, so
					// prefixing it makes group_id unique per real physical
					// group on the whole map.
					wmoId,
					groupNum: t.groupNum,
					groupId: `${wmoId}-${t.groupNum}`,
					groupName: (groupNames && groupNames.get(t.groupNum)) || `Group ${t.groupNum}`,
					cx: (c1[0] + c2[0] + c3[0] + c4[0]) / 4,
					cy: (c1[1] + c2[1] + c3[1] + c4[1]) / 4,
					width: Math.hypot(c4[0] - c1[0], c4[1] - c1[1]),
					height: Math.hypot(c2[0] - c1[0], c2[1] - c1[1]),
					yawDeg: -p.rot[1],
					z: anchorHeight + groupHeightKey,
					// The real 4 corners too (Big coordinates), so
					// TerrainWorldMap.lua's debug border can draw the tile's
					// TRUE rotated outline directly (Line, point-to-point) --
					// not re-derive it from cx/cy/width/height/yawDeg a
					// second time via a rotation formula that could disagree
					// (this whole feature exists because that kind of
					// re-derivation went wrong once already; don't repeat
					// it for the one thing meant to check it).
					corners: [c1, c2, c3, c4],
				});
			}
		}

		console.error(`${mapName}: ${mapTiles.length} WMO minimap tiles placed`);
		if (mapTiles.length === 0) continue;

		// Sort by height ascending within each group -- cosmetic/readability
		// only now (TerrainWorldMap.lua recomputes the true cross-group draw
		// order at runtime, since which tiles are even visible depends on
		// live per-group checkbox state -- see TWM_WMOOverlay_Update).
		mapTiles.sort((a, b) => a.z - b.z);

		// Grouped by groupId (see its own header comment above for why it's
		// "<wmoId>-<groupNum>", not just groupNum), one Twm_WMOTiles["<name>"]
		// block per map, each group's own {group_id, group_name, tiles}
		// sub-table -- see this file's header for the shape and why (WMO
		// tile group management, TerrainWorldMap.lua). Sorted by (wmoId,
		// groupNum) ascending here -- numerically, not a string sort of the
		// compound group_id itself (which would put "10-0" before "2-0") --
		// so the addon's own group checkbox list needs no runtime sort.
		const byGroup = new Map();
		for (const t of mapTiles) {
			if (!byGroup.has(t.groupId)) byGroup.set(t.groupId, { groupName: t.groupName, wmoId: t.wmoId, groupNum: t.groupNum, tiles: [] });
			byGroup.get(t.groupId).tiles.push(t);
		}
		const groupIds = [...byGroup.keys()].sort((a, b) => {
			const ga = byGroup.get(a), gb = byGroup.get(b);
			return (ga.wmoId - gb.wmoId) || (ga.groupNum - gb.groupNum);
		});

		fullOutput += `Twm_WMOTiles["${mapName}"] = {\n`;
		for (const groupId of groupIds) {
			const group = byGroup.get(groupId);
			const groupName = group.groupName.replace(/\\/g, '\\\\').replace(/"/g, '\\"');
			fullOutput += `    {\n`;
			fullOutput += `        group_id = "${groupId}",\n`;
			fullOutput += `        group_name = "${groupName}",\n`;
			fullOutput += `        tiles = {\n`;
			for (const t of group.tiles) {
				const corners = t.corners.map(c => `${c[0]}, ${c[1]}`).join(', ');
				fullOutput += `            {${t.fileID}, ${t.cx}, ${t.cy}, ${t.width}, ${t.height}, ${t.yawDeg}, ${t.z}, ${corners}},\n`;
			}
			fullOutput += `        },\n`;
			fullOutput += `    },\n`;
		}
		fullOutput += '}\n';
	}

	fs.writeFileSync(opts.out, fullOutput);
	console.error(`\nWritten: ${opts.out}`);
}

main();
