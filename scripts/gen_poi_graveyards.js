// Regenerates Data_<Flavor>/mapdata_poi_graveyards.lua's Twm_poi_graveyards
// from Wowhead's own "Spirit Healer" NPC page -- no DBC/ADT source has
// graveyard locations. See README.md for usage.
//
// Wowhead's NPC page (e.g. https://www.wowhead.com/mop-classic/npc=6491/spirit-healer)
// embeds a `var g_mapperData = {...}` JS object directly in the page HTML
// (no JS execution needed -- plain `curl` gets it) shaped like:
//   {"<AreaID>": [{"count": N, "coords": [[x, y], ...], "uiMapId": M, "uiMapName": "..."}]}
// -- keyed by AreaTable's own AreaID (NOT uiMapId; uiMapId is only carried
// along as a label), with coords as 0-100 zone-relative percentages, same
// convention as this addon's other percent-to-Big conversions (see
// sets/players.lua's TWM_Big2Mini_Coord call site):
//   bigX = x1 - (x/100) * (x1 - x2)
//   bigY = y1 - (y/100) * (y1 - y2)
// where {x1, x2, y1, y2} is Twm_mapareas["<Continent>"][AreaID].
//
// Because the key is already a stable AreaID, no uiMapId join is needed at
// all -- each AreaID is looked up directly against every continent in
// --mapareas-file.
//
// Wowhead serves a separately-scoped snapshot of this same NPC per game
// version domain, matching each flavor's own zone geometry (confirmed:
// classic-era = 42 zones/169 coords covering only Vanilla content; tbc =
// 55 zones/251 coords adding Outland; mop-classic = 98 zones/681 coords
// covering the current post-Cataclysm world) -- fetch the domain matching
// the target flavor, not a mismatched one.
//
// An AreaID from the page with no matching continent/box in --mapareas-file
// (e.g. a zone from a later expansion this flavor doesn't have) is silently
// skipped; skip count is printed to stderr.
//
// Wowhead's spawn list sometimes has several near-identical points for the
// same physical graveyard (confirmed: TBC's Terokkar Forest has 3 points
// within a couple yards of each other, plus another pair elsewhere in the
// same zone) -- almost certainly the same spirit healer sampled at slightly
// different wander positions, not distinct graveyards. These are merged
// (by centroid) into one point per AreaID, using the same "same spot"
// distance rule this addon already uses for Twm_poi_areas sub-area/POI
// dedup (see gen_poi_areas.js's original spec: points within DEDUP_DISTANCE
// yards of each other count as one).

const fs = require('fs');

const DEDUP_DISTANCE = 15; // yards

// {AreaID: [{x, y}, ...]} from a saved Wowhead NPC page's embedded
// `g_mapperData` object.
function parseWowheadMapperData(html) {
	const marker = 'var g_mapperData = ';
	const start = html.indexOf(marker);
	if (start === -1) throw new Error('g_mapperData not found -- is this a saved Wowhead NPC page?');
	const end = html.indexOf(';\n', start + marker.length);
	const data = JSON.parse(html.slice(start + marker.length, end));

	const spawns = {};
	for (const [areaID, entries] of Object.entries(data))
		spawns[areaID] = entries[0].coords.map(([x, y]) => ({ x, y }));
	return spawns;
}

// {contName: {areaID: [x1, x2, y1, y2]}} for every continent declared in a
// mapdata_continents.lua via Twm_mapareas["<Continent>"] = {...}.
function extractAllMapareasBoxes(luaText) {
	const boxesByContinent = {};
	const contRe = /Twm_mapareas\["([^"]+)"\]\s*=\s*\{/g;
	let cm;
	while ((cm = contRe.exec(luaText))) {
		const contName = cm[1];
		const start = cm.index;
		const end = luaText.indexOf('\n}', start);
		const block = luaText.slice(start, end === -1 ? undefined : end);

		const boxes = {};
		const re = /\[(\d+)\]\s*=\s*\{([^}]+)\}/g;
		let m;
		while ((m = re.exec(block)))
			boxes[m[1]] = m[2].split(',').map(s => parseFloat(s));
		boxesByContinent[contName] = boxes;
	}
	return boxesByContinent;
}

function percentToBig(x, y, box) {
	const [x1, x2, y1, y2] = box;
	return {
		bigX: x1 - (x / 100) * (x1 - x2),
		bigY: y1 - (y / 100) * (y1 - y2),
	};
}

// Merges points within DEDUP_DISTANCE yards of each other into one point at
// their centroid. Transitive (single-link) via union-find, so a chain like
// A-B-C (A close to B, B close to C, but A not directly close to C) still
// collapses to one cluster regardless of array order -- a plain one-pass
// scan would miss that.
function dedupeByDistance(points) {
	const parent = points.map((_, i) => i);
	function find(i) {
		while (parent[i] !== i) i = parent[i];
		return i;
	}
	function union(a, b) {
		const ra = find(a), rb = find(b);
		if (ra !== rb) parent[ra] = rb;
	}

	for (let i = 0; i < points.length; i++)
		for (let j = i + 1; j < points.length; j++)
			if (Math.hypot(points[i].bigX - points[j].bigX, points[i].bigY - points[j].bigY) <= DEDUP_DISTANCE)
				union(i, j);

	const groups = {};
	for (let i = 0; i < points.length; i++) {
		const r = find(i);
		(groups[r] = groups[r] || []).push(points[i]);
	}

	return Object.values(groups).map(cluster => ({
		bigX: cluster.reduce((s, p) => s + p.bigX, 0) / cluster.length,
		bigY: cluster.reduce((s, p) => s + p.bigY, 0) / cluster.length,
	}));
}

function parseArgs(argv) {
	const opts = { wowheadHtml: null, mapareasFile: null, out: null };
	for (let i = 0; i < argv.length; i++) {
		const a = argv[i];
		if (a === '--wowhead-html') opts.wowheadHtml = argv[++i];
		else if (a === '--mapareas-file') opts.mapareasFile = argv[++i];
		else if (a === '--out') opts.out = argv[++i];
		else throw new Error(`Unknown option: ${a}`);
	}
	return opts;
}

function printUsage() {
	console.error('Usage: node gen_poi_graveyards.js --wowhead-html <saved Spirit Healer NPC page.html> --mapareas-file <target flavor mapdata_continents.lua> --out <out-file.lua>');
}

function main() {
	let opts;
	try {
		opts = parseArgs(process.argv.slice(2));
	} catch (e) {
		console.error(e.message);
		printUsage();
		process.exit(1);
	}

	if (!opts.wowheadHtml || !opts.mapareasFile || !opts.out) {
		printUsage();
		process.exit(1);
	}

	const html = fs.readFileSync(opts.wowheadHtml, 'utf8');
	const mapareasLua = fs.readFileSync(opts.mapareasFile, 'utf8');

	const spawns = parseWowheadMapperData(html);
	const boxesByContinent = extractAllMapareasBoxes(mapareasLua);

	// AreaID -> {continent, box}, merged across every continent in --mapareas-file.
	const areaIndex = {};
	for (const [contName, boxes] of Object.entries(boxesByContinent))
		for (const areaID of Object.keys(boxes))
			areaIndex[areaID] = { contName, box: boxes[areaID] };

	const byContinent = {};
	let matched = 0, skipped = 0, mergedAway = 0;

	for (const [areaID, points] of Object.entries(spawns)) {
		const entry = areaIndex[areaID];
		if (!entry) {
			skipped += points.length;
			continue;
		}

		const big = points.map(p => percentToBig(p.x, p.y, entry.box));
		const deduped = dedupeByDistance(big);
		mergedAway += big.length - deduped.length;

		const list = byContinent[entry.contName] || (byContinent[entry.contName] = []);
		list.push(...deduped);
		matched += deduped.length;
	}

	console.error(`${matched} graveyards matched, ${skipped} skipped (AreaID not in --mapareas-file), ${mergedAway} merged as same-spot duplicates`);

	let fullOutput = "-- GENERATED FILE -- do not hand-edit, regenerate with scripts/gen_poi_graveyards.js\n"
		+ "-- and replace this file wholesale. See scripts/README.md for details.\n"
		+ "--\n"
		+ "-- Graveyard (spirit healer) locations, borrowed from Wowhead's own\n"
		+ "-- \"Spirit Healer\" NPC page (no DBC source exists for these) and\n"
		+ "-- converted from its zone-relative percentages to this flavor's own Big\n"
		+ "-- coordinates via Twm_mapareas.\n\n"
		+ "Twm_poi_graveyards = {\n";

	for (const contName of Object.keys(byContinent).sort()) {
		fullOutput += `    ["${contName}"] = {\n`;
		for (const { bigX, bigY } of byContinent[contName])
			fullOutput += `        {${bigX.toFixed(2)}, ${bigY.toFixed(2)}},\n`;
		fullOutput += '    },\n';
	}
	fullOutput += '}\n';

	fs.writeFileSync(opts.out, fullOutput);
	console.error(`Written: ${opts.out}`);
}

main();
