// Zone-box helpers shared by gen_arenas.js and gen_instance_maps.js: a map's
// extent read back from an already-generated tiles file.

// {col, row} min/max across every key in Twm_WDTValidTiles["<name>"] of an
// already-generated mapdata_tiles_<kind>.lua -- same "COLxROW" keys parse_wdt.js
// itself writes. null when the map has no valid ADT tile.
function tileBoundsFor(tilesLua, name) {
	const marker = `Twm_WDTValidTiles["${name}"] = {`;
	const start = tilesLua.indexOf(marker);
	if (start === -1) return null;
	const end = tilesLua.indexOf('\n}', start);
	const block = tilesLua.slice(start, end === -1 ? undefined : end);

	let colMin = Infinity, colMax = -Infinity, rowMin = Infinity, rowMax = -Infinity;
	const re = /\["(\d+)x(\d+)"\]/g;
	let m, count = 0;
	while ((m = re.exec(block))) {
		const col = parseInt(m[1], 10), row = parseInt(m[2], 10);
		colMin = Math.min(colMin, col); colMax = Math.max(colMax, col);
		rowMin = Math.min(rowMin, row); rowMax = Math.max(rowMax, row);
		count++;
	}
	if (count === 0) return null;
	return { colMin, colMax, rowMin, rowMax, count };
}

// {x1,x2,y1,y2} union of every tile's own real 4 corners (the trailing 8
// fields of gen_wmo_tiles.js's 15-field tuple, already-computed Big
// coordinates -- see that script's header) for Twm_WMOTiles["<name>"] in an
// already-generated mapdata_wmo_tiles_<kind>.lua. For a map with no valid ADT
// tile (a pure-WMO map, or one listed in skip_lists.js's skipAdtTiles).
// Preferred over re-deriving a box from the WMO's own MOHD bounding box via a
// separately reasoned placement formula (gen_instance_maps.js's
// boxFromWdtGlobalPlacement): reading the real corners already used to
// RENDER the tiles guarantees the box matches what is on screen, by
// construction, regardless of which formula is or isn't right.
function wmoTileBoundsFor(wmoTilesLua, name) {
	const marker = `Twm_WMOTiles["${name}"] = {`;
	const start = wmoTilesLua.indexOf(marker);
	if (start === -1) return null;
	const end = wmoTilesLua.indexOf('\n}', start);
	const block = wmoTilesLua.slice(start, end === -1 ? undefined : end);

	let x1 = -Infinity, x2 = Infinity, y1 = -Infinity, y2 = Infinity;
	let count = 0;
	const re = /\{(-?[0-9.eE+-]+(?:,\s*-?[0-9.eE+-]+){14})\}/g;
	let m;
	while ((m = re.exec(block))) {
		const nums = m[1].split(',').map(s => parseFloat(s));
		const [c1x, c1y, c2x, c2y, c3x, c3y, c4x, c4y] = nums.slice(7, 15);
		x1 = Math.max(x1, c1x, c2x, c3x, c4x);
		x2 = Math.min(x2, c1x, c2x, c3x, c4x);
		y1 = Math.max(y1, c1y, c2y, c3y, c4y);
		y2 = Math.min(y2, c1y, c2y, c3y, c4y);
		count++;
	}
	if (count === 0) return null;
	return { x1, x2, y1, y2, count };
}

module.exports = { tileBoundsFor, wmoTileBoundsFor };
