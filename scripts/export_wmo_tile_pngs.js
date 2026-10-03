#!/usr/bin/env node
// Dumps every baked WMO minimap tile referenced by the shipped Twm_WMOTiles
// data (Data_*/mapdata_wmo_tiles_*.lua, all flavors or --flavors) to
// <out>/<FileDataID>.png (RGBA, alpha kept as in the BLP), for inspection.
//
// Usage:
//   node export_wmo_tile_pngs.js --work-dir <dir> --out <dir> [--data-dir <addon-root>] [--flavors wow_classic_era,wow_anniversary,...] [--maps DireMaul,...]
//
// The BLPs must already be extracted (gen_wmo_tiles.js did that): a named
// file sits at its listfile path under <work-dir>/<flavor>/, an unnamed one
// at unknown/FILEDATA_<id>. Tiles whose BLP is missing are reported, not
// fetched. A FileDataID present in several flavors is written once (first
// flavor that has the file).
const fs = require('fs');
const path = require('path');
const readline = require('readline');
const { PNG } = require('pngjs');
const { Blp, BLP_IMAGE_FORMAT } = require('@wowserhq/format');
const { flavorDir, listfilePath, envOr } = require('./extract');

const FLAVOR_DATA_DIR = {
	wow_classic_era: 'Data_Vanilla',
	wow_anniversary: 'Data_TBC',
	wow_classic: 'Data_Mists',
	wow_classic_beta: 'Data_Forever',
};

function parseArgs(argv) {
	const o = {};
	for (let i = 2; i < argv.length; i++) {
		if (argv[i].startsWith('--')) o[argv[i].slice(2)] = argv[++i];
	}
	return o;
}

// First number of every tile tuple: `{<fileDataID>, cx, cy, ...}` (15 numbers),
// of the maps in `mapNames` (null = all maps of the file).
function tileFileIds(luaPath, mapNames) {
	const ids = new Set();
	const text = fs.readFileSync(luaPath, 'utf8');
	const blocks = text.split(/^Twm_WMOTiles\["/m).slice(1);
	for (const block of blocks) {
		const name = block.slice(0, block.indexOf('"'));
		if (mapNames && !mapNames.includes(name)) continue;
		for (const m of block.matchAll(/^\s*\{(\d+),\s*(?:-?[\d.e+-]+,\s*){13}-?[\d.e+-]+\},?\s*$/gm)) ids.add(Number(m[1]));
	}
	return ids;
}

async function loadListfile(file, wanted) {
	const paths = new Map();
	const rl = readline.createInterface({ input: fs.createReadStream(file) });
	for await (const line of rl) {
		const i = line.indexOf(';');
		if (i < 0) continue;
		const id = Number(line.slice(0, i));
		if (wanted.has(id)) paths.set(id, line.slice(i + 1).trim());
	}
	return paths;
}

function writePng(blpFile, outFile) {
	const blp = new Blp();
	blp.load(fs.readFileSync(blpFile));
	const img = blp.getImage(0, BLP_IMAGE_FORMAT.IMAGE_ABGR8888);
	const png = new PNG({ width: blp.width, height: blp.height });
	png.data.set(img.data);
	fs.writeFileSync(outFile, PNG.sync.write(png));
}

(async () => {
	const opts = parseArgs(process.argv);
	const workDir = envOr(opts['work-dir'], 'WORK_DIR');
	const outDir = opts.out;
	if (!workDir || !outDir) {
		console.error('usage: node export_wmo_tile_pngs.js --work-dir <dir> --out <dir> [--data-dir <addon-root>] [--flavors a,b]');
		process.exit(1);
	}
	const addonRoot = opts['data-dir'] || path.join(__dirname, '..');
	const flavors = opts.flavors ? opts.flavors.split(',') : Object.keys(FLAVOR_DATA_DIR);
	const mapNames = opts.maps ? opts.maps.split(',') : null;
	fs.mkdirSync(outDir, { recursive: true });

	const idsByFlavor = {};
	const all = new Set();
	for (const flavor of flavors) {
		const dir = path.join(addonRoot, FLAVOR_DATA_DIR[flavor]);
		const ids = new Set();
		for (const kind of ['dungeons', 'raids', 'arenas']) {
			const f = path.join(dir, `mapdata_wmo_tiles_${kind}.lua`);
			if (fs.existsSync(f)) for (const id of tileFileIds(f, mapNames)) ids.add(id);
		}
		idsByFlavor[flavor] = ids;
		for (const id of ids) all.add(id);
		console.error(`${flavor}: ${ids.size} distinct tile FileDataIDs`);
	}

	const paths = await loadListfile(listfilePath(workDir), all);
	const done = new Set();
	const missing = [];
	for (const flavor of flavors) {
		for (const id of idsByFlavor[flavor]) {
			if (done.has(id)) continue;
			const rel = paths.get(id) || `unknown/FILEDATA_${id}`;
			const file = path.join(flavorDir(workDir, flavor), rel);
			if (!fs.existsSync(file)) continue;
			writePng(file, path.join(outDir, `${id}.png`));
			done.add(id);
		}
	}
	for (const id of all) if (!done.has(id)) missing.push(id);
	console.error(`written ${done.size} PNG(s) to ${outDir}`);
	if (missing.length) console.error(`no extracted BLP for ${missing.length} FileDataID(s): ${missing.slice(0, 20).join(', ')}${missing.length > 20 ? ', ...' : ''}`);
})().catch(e => { console.error(e); process.exit(1); });
