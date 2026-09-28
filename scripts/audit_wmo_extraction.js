// One-off audit: for a map, list every real MODF placement, check via the
// community listfile (not local disk) whether it has any baked WMO
// minimap tiles at all, and if so, report exactly which local files
// (root/group .wmo + minimap .blp) are still missing. Not part of the
// regular pipeline -- a diagnostic used once to find extraction gaps
// across every arena/flavor.
const fs = require('fs');
const path = require('path');
const readline = require('readline');

function chunkID(a, b, c, d) { return (a.charCodeAt(0) << 24) | (b.charCodeAt(0) << 16) | (c.charCodeAt(0) << 8) | d.charCodeAt(0); }
const ID_MODF = chunkID('M', 'O', 'D', 'F');

function findModfPlacements(mapDir) {
	const entries = [];
	const seen = new Set();
	if (!fs.existsSync(mapDir)) return entries;
	for (const f of fs.readdirSync(mapDir)) {
		if (!f.endsWith('_obj0.adt')) continue;
		const buf = fs.readFileSync(path.join(mapDir, f));
		let offset = 0;
		while (offset + 8 <= buf.length) {
			const magic = buf.readUInt32LE(offset), size = buf.readUInt32LE(offset + 4);
			const dataStart = offset + 8;
			if (magic === ID_MODF) {
				const count = size / 64;
				for (let i = 0; i < count; i++) {
					const b = dataStart + i * 64;
					const nameId = buf.readUInt32LE(b);
					if (seen.has(nameId)) continue;
					seen.add(nameId);
					entries.push({ nameId, rot: [buf.readFloatLE(b + 20), buf.readFloatLE(b + 24), buf.readFloatLE(b + 28)] });
				}
			}
			offset = dataStart + size;
		}
	}
	return entries;
}

async function main() {
	const [, , flavorDir, listfilePath, ...mapNames] = process.argv;

	const idToPath = {};
	const tilesByStem = {}; // stem -> [{groupNum, blockX, blockY, fileID, listfilePath}]
	const rl = readline.createInterface({ input: fs.createReadStream(listfilePath) });
	for await (const line of rl) {
		const idx = line.indexOf(';');
		if (idx === -1) continue;
		const id = parseInt(line.slice(0, idx), 10);
		const p = line.slice(idx + 1).trim();
		idToPath[id] = p;
		if (p.startsWith('world/minimaps/wmo/')) {
			const m = p.match(/^(.*)_(\d+)_(\d+)_(\d+)\.blp$/);
			if (m) {
				const [, stem, groupNum, blockX, blockY] = m;
				(tilesByStem[stem] = tilesByStem[stem] || []).push({ groupNum: parseInt(groupNum, 10), blockX: parseInt(blockX, 10), blockY: parseInt(blockY, 10), fileID: id, listfilePath: p });
			}
		}
	}

	for (const mapName of mapNames) {
		const mapDir = path.join(flavorDir, 'world', 'maps', mapName);
		const placements = findModfPlacements(mapDir);
		const seenWmo = new Set();
		let anyTiles = false;
		for (const p of placements) {
			const wmoPath = idToPath[p.nameId];
			if (!wmoPath || seenWmo.has(wmoPath)) continue;
			seenWmo.add(wmoPath);
			const stem = wmoPath.replace(/\.wmo$/i, '').replace('world/wmo/', 'world/minimaps/wmo/');
			const tiles = tilesByStem[stem];
			if (!tiles || tiles.length === 0) continue;
			anyTiles = true;
			const groupNums = [...new Set(tiles.map(t => t.groupNum))];
			console.log(`${mapName}: ${wmoPath} -- yaw ${p.rot[1].toFixed(2)} deg, pitch/roll ${p.rot[0].toFixed(2)}/${p.rot[2].toFixed(2)}, ${tiles.length} tile(s) across groups [${groupNums.join(',')}]`);
			const wmoDir = path.join(flavorDir, path.dirname(wmoPath));
			const wmoBase = path.basename(wmoPath, '.wmo');
			const rootLocal = fs.existsSync(path.join(wmoDir, `${wmoBase}.wmo`));
			console.log(`  root .wmo extracted: ${rootLocal}`);
			for (const g of groupNums) {
				const gp = path.join(wmoDir, `${wmoBase}_${String(g).padStart(3, '0')}.wmo`);
				console.log(`  group ${g} extracted: ${fs.existsSync(gp)} (${gp})`);
			}
			const minimapDir = path.join(flavorDir, path.dirname(wmoPath).replace(/^world[\\/]wmo/, 'world/minimaps/wmo'));
			const tilesExtracted = tiles.filter(t => fs.existsSync(path.join(flavorDir, t.listfilePath))).length;
			console.log(`  minimap tiles extracted: ${tilesExtracted}/${tiles.length} (dir: ${minimapDir})`);
		}
		if (!anyTiles) console.log(`${mapName}: no placement with any baked WMO minimap tile at all`);
	}
}

main();
