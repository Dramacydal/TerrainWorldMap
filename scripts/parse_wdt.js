// Standalone port of wow.export's WDTLoader.js MAIN/MAID parsing.
// Regenerates mapdata_tiles.lua (Twm_WDTValidTiles) -- a complete, ready-to-use
// replacement, covering as many continents as you pass in in one go.
//
// Usage:
//   node parse_wdt.js <out-file.lua> <path-to-.wdt> <ContinentName> [<path-to-.wdt> <ContinentName> ...]
//
// Example (regenerating the addon's actual mapdata_tiles.lua from all 3 continents):
//   node parse_wdt.js ../mapdata_tiles.lua azeroth.wdt Azeroth kalimdor.wdt Kalimdor expansion01.wdt Expansion01
//
// Which tile keys have real terrain (rootADT != 0), based on each WDT's own
// MAIN/MAID chunks.
//
// Axis mapping (derived from wow.export's MapViewerScreen.js world<->tile
// formulas + TerrainWorldMap's own Yatlas_Mini2Big_Coord): TerrainWorldMap's tile "col" is
// the WDT's tile Y index, TerrainWorldMap's tile "row" is the WDT's tile X index.
// i.e. TerrainWorldMap key "COLxROW" <-> WDT tile (x=ROW, y=COL).
// This was empirically verified (not just theorized) by matching a real
// bug screenshot pixel-for-pixel against this script's output -- see
// README.md's "Axis mapping" section for the full story. If you ever
// re-derive this from scratch, treat it as a hypothesis to be
// cross-checked against known reference tiles (see checkTiles below)
// before trusting the output wholesale.

const fs = require('fs');

const MAP_SIZE = 64;
const MAP_SIZE_SQ = MAP_SIZE * MAP_SIZE;

function chunkID(a, b, c, d) {
	// Matches wow.export's convention: chunk magic bytes read as a
	// little-endian uint32 straight off the file (no manual reversal).
	return (a.charCodeAt(0) << 24) | (b.charCodeAt(0) << 16) | (c.charCodeAt(0) << 8) | d.charCodeAt(0);
}

const ID_MAIN = chunkID('M', 'A', 'I', 'N');
const ID_MAID = chunkID('M', 'A', 'I', 'D');

function parseWDT(buf) {
	let offset = 0;
	const result = { tiles: null, entries: null };

	while (offset < buf.length) {
		const chunkMagic = buf.readUInt32LE(offset);
		const chunkSize = buf.readUInt32LE(offset + 4);
		const dataStart = offset + 8;
		const nextOffset = dataStart + chunkSize;

		if (chunkMagic === ID_MAIN) {
			const tiles = new Array(MAP_SIZE_SQ);
			let p = dataStart;
			for (let x = 0; x < MAP_SIZE; x++) {
				for (let y = 0; y < MAP_SIZE; y++) {
					tiles[(y * MAP_SIZE) + x] = buf.readUInt32LE(p);
					p += 8; // 4 bytes read + 4 bytes skipped (matches WDTLoader.js's data.move(4))
				}
			}
			result.tiles = tiles;
		} else if (chunkMagic === ID_MAID) {
			const entries = new Array(MAP_SIZE_SQ);
			let p = dataStart;
			for (let x = 0; x < MAP_SIZE; x++) {
				for (let y = 0; y < MAP_SIZE; y++) {
					entries[(y * MAP_SIZE) + x] = {
						rootADT: buf.readUInt32LE(p),
						obj0ADT: buf.readUInt32LE(p + 4),
						obj1ADT: buf.readUInt32LE(p + 8),
						tex0ADT: buf.readUInt32LE(p + 12),
						lodADT: buf.readUInt32LE(p + 16),
						mapTexture: buf.readUInt32LE(p + 20),
						mapTextureN: buf.readUInt32LE(p + 24),
						minimapTexture: buf.readUInt32LE(p + 28),
					};
					p += 32;
				}
			}
			result.entries = entries;
		}

		offset = nextOffset;
	}

	return result;
}

function getValidTiles(filePath) {
	const buf = fs.readFileSync(filePath);
	const wdt = parseWDT(buf);

	const hasMaid = !!wdt.entries;
	console.error(`  parsed ${filePath}: hasMAID=${hasMaid}, hasMAIN=${!!wdt.tiles}`);

	const validTiles = [];

	for (let x = 0; x < MAP_SIZE; x++) {
		for (let y = 0; y < MAP_SIZE; y++) {
			const idx = (y * MAP_SIZE) + x;

			let exists = false;
			if (hasMaid) {
				const entry = wdt.entries[idx];
				exists = !!(entry && entry.rootADT);
			} else if (wdt.tiles) {
				exists = !!wdt.tiles[idx];
			}

			if (exists) {
				// TerrainWorldMap col = WDT y, TerrainWorldMap row = WDT x (see header comment).
				const key = String(y).padStart(2, '0') + 'x' + String(x).padStart(2, '0');
				validTiles.push(key);
			}
		}
	}

	console.error(`  valid (rootADT-backed) tiles: ${validTiles.length} / ${MAP_SIZE_SQ}`);
	return validTiles;
}

// Known reference tiles to sanity-check per continent, from prior manual
// investigation -- if these stop matching, double check the axis mapping
// above before trusting a fresh run's output.
const sanityChecks = {
	Azeroth: { '43x39': false, '44x39': false, '41x39': true, '42x39': true, '41x40': true, '42x40': true },
	Expansion01: { '45x06': true },
};

function main() {
	const args = process.argv.slice(2);
	const outFile = args[0];
	const pairs = args.slice(1);

	if (!outFile || pairs.length < 2 || pairs.length % 2 !== 0) {
		console.error('Usage: node parse_wdt.js <out-file.lua> <path-to-.wdt> <ContinentName> [<path-to-.wdt> <ContinentName> ...]');
		process.exit(1);
	}

	let lua = "-- GENERATED FILE -- do not hand-edit, regenerate with scripts/parse_wdt.js\n"
		+ "-- and replace this file wholesale. See scripts/README.md for details.\n"
		+ "--\n"
		+ "-- Which map tiles (TerrainWorldMap grid-cell coords) have real terrain, extracted\n"
		+ "-- from this client's own world/maps/<continent>/<continent>.wdt files\n"
		+ "-- (MAIN/MAID chunks, rootADT field). This is ground truth: a tile is only\n"
		+ "-- ever real if the client actually ships terrain for it, regardless of\n"
		+ "-- what the (possibly orphaned) minimap preview texture or C_Map zone data\n"
		+ "-- might otherwise suggest.\n"
		+ "Twm_WDTValidTiles = {}\n";

	for (let i = 0; i < pairs.length; i += 2) {
		const filePath = pairs[i];
		const contName = pairs[i + 1];

		console.error(`${contName}:`);
		const validTiles = getValidTiles(filePath);

		lua += `\nTwm_WDTValidTiles["${contName}"] = {\n`;
		for (const key of validTiles)
			lua += `    ["${key}"] = true,\n`;
		lua += '}\n';

		const checks = sanityChecks[contName];
		if (checks) {
			for (const [key, expected] of Object.entries(checks)) {
				const found = validTiles.includes(key);
				const ok = found === expected;
				console.error(`  sanity check: tile ${key} -> ${found ? 'VALID' : 'not valid'} (expected ${expected ? 'VALID' : 'not valid'}) ${ok ? 'OK' : '*** MISMATCH ***'}`);
			}
		}
	}

	fs.writeFileSync(outFile, lua);
	console.error(`\nWritten: ${outFile}`);
}

main();
