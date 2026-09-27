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
const { parseCsvFile, findCsv } = require('./csv');

const DEDUP_DISTANCE = 15; // yards

// {areaID: box} for every Zone UiMapAssignment row (Type 3, or 6 on builds
// that use it -- see gen_mapareas.js), regardless of whether gen_mapareas.js
// exposed it as one of Twm_mapareas' own displayed-zone entries. A small
// starting-experience camp (Camp Narache, Gilneas City, ...) has its own
// real box here even when gen_mapareas.js excluded it from the zone
// dropdown for not being a top-level AreaTable entry -- Wowhead's graveyard
// coordinates for it are percentages of exactly that box, not its parent
// zone's (a parent-box fallback would place the point wrong, not just
// approximately).
function loadRawZoneBoxes(flavorDir) {
	const assignRows = parseCsvFile(findCsv(flavorDir, 'UiMapAssignment.'));
	const uiMapRows = parseCsvFile(findCsv(flavorDir, 'UiMap.'));
	const uiMapType = {};
	for (const r of uiMapRows) uiMapType[r.ID] = r.Type;

	const boxes = {};
	for (const r of assignRows) {
		if (r.AreaID === '0' || (uiMapType[r.UiMapID] !== '3' && uiMapType[r.UiMapID] !== '6'))
			continue;
		if (boxes[r.AreaID]) continue; // keep the first, same as gen_mapareas.js
		const R0 = parseFloat(r.Region_0), R1 = parseFloat(r.Region_1);
		const R3 = parseFloat(r.Region_3), R4 = parseFloat(r.Region_4);
		boxes[r.AreaID] = [R4, R1, R3, R0];
	}
	return boxes;
}

// AreaID -> ParentAreaID, straight from AreaTable -- walked to find which
// known continent/top-level zone a sub-area (not itself in --mapareas-file)
// ultimately belongs to, purely to decide which output section it goes in;
// its own box (loadRawZoneBoxes above) is what actually places the point.
function loadAreaParents(flavorDir) {
	const rows = parseCsvFile(findCsv(flavorDir, 'AreaTable.'));
	const parentOf = {};
	for (const r of rows) parentOf[r.ID] = r.ParentAreaID;
	return parentOf;
}

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
	const opts = { wowheadHtml: null, mapareasFile: null, out: null, flavorDir: null };
	for (let i = 0; i < argv.length; i++) {
		const a = argv[i];
		if (a === '--wowhead-html') opts.wowheadHtml = argv[++i];
		else if (a === '--mapareas-file') opts.mapareasFile = argv[++i];
		else if (a === '--out') opts.out = argv[++i];
		else if (a === '--flavor-dir') opts.flavorDir = argv[++i];
		else throw new Error(`Unknown option: ${a}`);
	}
	return opts;
}

function printUsage() {
	console.error('Usage: node gen_poi_graveyards.js --wowhead-html <saved Spirit Healer NPC page.html> --mapareas-file <target flavor mapdata_continents.lua> --out <out-file.lua> [--flavor-dir <dir with UiMapAssignment/UiMap/AreaTable.*.csv>]');
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

	// --flavor-dir lets a sub-area gen_mapareas.js excluded from the zone
	// dropdown (not a top-level AreaTable entry) still resolve: its own box
	// comes from raw UiMapAssignment (rawBoxByAreaID), and which output
	// section it belongs under comes from walking AreaTable's ParentAreaID
	// chain up to whichever ancestor IS in areaIndex.
	const rawBoxByAreaID = opts.flavorDir ? loadRawZoneBoxes(opts.flavorDir) : {};
	const parentOf = opts.flavorDir ? loadAreaParents(opts.flavorDir) : {};

	function resolveViaParentChain(areaID) {
		let id = areaID, guard = 0;
		while (guard < 10) {
			const parent = parentOf[id];
			if (!parent || parent === '0') return null;
			if (areaIndex[parent]) return { contName: areaIndex[parent].contName, box: rawBoxByAreaID[areaID] };
			id = parent;
			guard++;
		}
		return null;
	}

	const byContinent = {};
	let matched = 0, skipped = 0, mergedAway = 0, viaParentChain = 0;

	for (const [areaID, points] of Object.entries(spawns)) {
		let entry = areaIndex[areaID];
		if (!entry && rawBoxByAreaID[areaID]) {
			entry = resolveViaParentChain(areaID);
			if (entry) viaParentChain += points.length;
		}
		if (!entry) {
			skipped += points.length;
			continue;
		}

		const big = points.map(p => percentToBig(p.x, p.y, entry.box));
		const list = byContinent[entry.contName] || (byContinent[entry.contName] = []);
		list.push(...big);
	}

	// Dedup per continent, across every AreaID that landed there (a zone and
	// a sub-area of it, e.g. Gilneas/Gilneas City, can each contribute
	// points close enough to be the same physical graveyard) -- not per
	// AreaID, which would miss that case entirely.
	for (const contName of Object.keys(byContinent)) {
		const before = byContinent[contName].length;
		byContinent[contName] = dedupeByDistance(byContinent[contName]);
		mergedAway += before - byContinent[contName].length;
		matched += byContinent[contName].length;
	}

	console.error(`${matched} graveyards matched (${viaParentChain} via --flavor-dir's own AreaTable/UiMapAssignment for a sub-area not in --mapareas-file), ${skipped} skipped (AreaID unresolvable), ${mergedAway} merged as same-spot duplicates`);

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
