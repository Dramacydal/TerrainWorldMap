// Builds Data_<Target>/mapdata_poi_instances.lua from another flavor's
// already generated one, for a flavor with no teleport table of its own
// (gen_poi_instances.js needs areatrigger_teleport.csv). See README.md.
//
// Kept from the source file: entries whose target is a map of the target
// flavor (same MapID for a dungeon/raid, same name for a continent) and,
// for an entry inside an instance map, whose own map exists there too
// (same directory and MapID). Coordinates are copied unchanged.

const fs = require('fs');
const path = require('path');

function parseArgs(argv) {
	const opts = { from: null, to: null, out: null };
	for (let i = 0; i < argv.length; i++) {
		const a = argv[i];
		if (a === '--from') opts.from = argv[++i];
		else if (a === '--to') opts.to = argv[++i];
		else if (a === '--out') opts.out = argv[++i];
		else throw new Error(`Unknown option: ${a}`);
	}
	return opts;
}

// {dir: mapID} from a flavor's mapdata_dungeons.lua + mapdata_raids.lua.
function loadInstances(dataDir) {
	const instances = {};
	for (const file of ['mapdata_dungeons.lua', 'mapdata_raids.lua']) {
		const text = fs.readFileSync(path.join(dataDir, file), 'utf8');
		for (const m of text.matchAll(/key = "([^"]+)",\s*mapID = "(\d+)"/g))
			instances[m[1]] = m[2];
	}
	return instances;
}

function loadContinentNames(dataDir) {
	const text = fs.readFileSync(path.join(dataDir, 'mapdata_continents.lua'), 'utf8');
	return new Set([...text.matchAll(/Twm_mapareas\["([^"]+)"\]\s*=\s*\{/g)].map(m => m[1]));
}

// [{name, lines: [entry line, ...]}] in file order, plus the text before the first section.
function parseSections(text) {
	const start = text.indexOf('Twm_instances = {');
	const sections = [];
	let cur = null;
	for (const line of text.slice(start).split(/\r?\n/).slice(1)) {
		const open = line.match(/^\s*\["([^"]+)"\] = \{\s*$/);
		if (open) cur = { name: open[1], lines: [] };
		else if (cur && /^\s*\{"/.test(line)) cur.lines.push(line);
		else if (cur && /^\s*\},?\s*$/.test(line)) { sections.push(cur); cur = null; }
	}
	return sections;
}

function main() {
	const opts = parseArgs(process.argv.slice(2));
	if (!opts.from || !opts.to || !opts.out) {
		console.error('Usage: node copy_poi_instances.js --from <source Data_ dir> --to <target Data_ dir> --out <out-file.lua>');
		process.exit(1);
	}

	const src = loadInstances(opts.from);
	const dst = loadInstances(opts.to);
	const continents = loadContinentNames(opts.to);
	const targetMapIDs = new Set(Object.values(dst));
	const present = dir => src[dir] !== undefined && src[dir] === dst[dir];

	const sections = parseSections(fs.readFileSync(path.join(opts.from, 'mapdata_poi_instances.lua'), 'utf8'));
	const kept = [];
	let keptEntries = 0, droppedEntries = 0;
	const droppedSections = new Set();
	for (const sec of sections) {
		if (sec.name in src && !present(sec.name)) {
			droppedSections.add(sec.name);
			droppedEntries += sec.lines.length;
			continue;
		}
		const lines = sec.lines.filter(line => {
			const f = line.match(/^\s*\{"(\w+)", (\d+), "[^"]*", [-\d.]+, [-\d.]+(?:, "([^"]+)", [-\d.]+, [-\d.]+)?\}/);
			if (!f) return false;
			const [, kind, mapID, targetDir] = f;
			return (kind === 'Exit' || targetMapIDs.has(mapID))
				&& (!targetDir || continents.has(targetDir) || present(targetDir));
		});
		droppedEntries += sec.lines.length - lines.length;
		keptEntries += lines.length;
		if (lines.length) kept.push({ name: sec.name, lines });
	}

	let out = '-- GENERATED FILE -- do not hand-edit, regenerate with scripts/copy_poi_instances.js\n'
		+ '-- and replace this file wholesale. See scripts/README.md for details.\n'
		+ '--\n'
		+ '-- Dungeon/raid entrance markers copied from another flavor\'s\n'
		+ '-- mapdata_poi_instances.lua (this flavor has no teleport table of its\n'
		+ '-- own); coordinates are unchanged.\n\n'
		+ 'Twm_instances = {\n';
	for (const sec of kept)
		out += `    ["${sec.name}"] = {\n${sec.lines.join('\n')}\n    },\n`;
	out += '}\n';
	fs.writeFileSync(opts.out, out);

	console.error(`${keptEntries} entries kept, ${droppedEntries} dropped; instance maps missing in the target:${[...droppedSections].join(', ') || '-'}`);
	console.error(`Written: ${opts.out}`);
}

main();
