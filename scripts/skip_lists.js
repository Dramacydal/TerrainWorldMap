// Manual, hand-maintained per-flavor overrides for maps found bad only by
// eyeballing the addon in-game -- no automated check catches any of these,
// they're discovered one at a time during test viewing and added here as
// they turn up. Every list starts empty; grow incrementally.
//
// Keyed by product code (see README.md's "Product codes" table:
// wow_classic_era/wow_anniversary/wow_classic/wow_classic_beta) -> array of
// Map.csv `ID` values (not Directory names -- the numeric ID is what's
// visible directly in Map.csv/Wowhead without having to re-derive the exact
// Directory casing every time). Add a trailing comment with the map's name
// for readability; nothing reads the comment, it's for humans editing this
// file only.
//
// Four independent knobs, not one -- a map/tile can need any combination:
// - skipMaps: excluded from generation entirely -- no dropdown entry, no
//   Twm_mapareas box, nothing. Checked in exactly one place:
//   gen_candidates.js's own findContinents/findBattlegrounds/findArenas/
//   findCandidates calls (candidates/<kind>.json never lists a skipped map
//   at all) -- every other script reads that JSON (--candidates <kind>)
//   instead of re-deriving its own candidate list, so this is the only
//   place skipMaps needs applying. NOT checked again for an explicit
//   --maps <a,b,c> override -- that's a deliberate manual/debug bypass, and
//   silently dropping a hand-listed map would defeat its entire point. For
//   a map that's broken in some way beyond just one tile layer, or a
//   junk/test row Map.csv's own filters don't already catch.
// - skipAdtTiles: the map still gets its own dropdown entry/Twm_mapareas box,
//   but parse_wdt.js forces its ADT tile-validity data empty -- read by
//   TWM_MapHasTerrain (TerrainWorldMap.lua) and gen_instance_maps.js's own
//   box derivation as "no real terrain", same shape as a genuine pure-WMO
//   map -- because the ADT tile validity parse_wdt.js would otherwise
//   report for it doesn't correspond to real, in-place terrain (found via
//   test viewing: ADT tiles rendering somewhere they don't belong).
// - skipWmoTiles: the map still gets its own dropdown entry/Twm_mapareas box,
//   but gen_wmo_tiles.js skips writing its Twm_WMOTiles entry entirely --
//   even if it finds a real MODF placement with baked minimap tiles, because
//   that placement doesn't belong on this map's own overlay (e.g. a
//   decorative fragment WMO rendering somewhere nonsensical).
// - skipTileFileDataId: NOT keyed by map at all -- a single baked minimap
//   texture (by its own FileDataID) that should never render, no matter
//   which system references it (an ordinary ADT continent tile via
//   parse_wdt.js, OR a WMO minimap tile via gen_wmo_tiles.js -- the same
//   FileDataID can turn up reused in either place). For a specific known-bad
//   texture (e.g. a leftover Blizzard placeholder) rather than a whole map's
//   worth of tiles being wrong.

const skipMaps = {
	// CashTest (Directory "TEST_01", MapID 29) -- an ancient Blizzard dev
	// test map, InstanceType=1 so it slips through the dungeon candidate
	// filter (see .claude-docs/gotchas.md's "junk/test Map.csv rows" note).
	// Confirmed (2026-09-30) present with this same ID on Vanilla/TBC/Forever;
	// the row doesn't exist at all in Mists' own Map.csv (removed by then) --
	// don't add it there, it's simply not a candidate to begin with.
	// User confirmed in-game: shows neither ADT nor WMO tiles, nothing to see.
	//
	// test (Directory "test", MapID 13, "Test Dungeon") -- same class of
	// junk row, InstanceType=1, no real WDT shipped at all (confirmed:
	// ENOENT extracting world/maps/test/test.wdt). Present with this same ID
	// on Vanilla/TBC/Forever, absent from Mists' own Map.csv.
	wow_classic_era: [
		'29', // CashTest
		'13', // Test Dungeon
	],
	wow_anniversary: [
		'29', // CashTest
		'13', // Test Dungeon
	],
	wow_classic: [
	],
	wow_classic_beta: [
		'29', // CashTest
		'13', // Test Dungeon
	],
};

const skipAdtTiles = {
	wow_classic_era: [
	],
	wow_anniversary: [
	],
	wow_classic: [
	],
	wow_classic_beta: [
	],
};

const skipWmoTiles = {
	wow_classic_era: [
	],
	wow_anniversary: [
	],
	wow_classic: [
	],
	wow_classic_beta: [
	],
};

const skipTileFileDataId = {
	wow_classic_era: [
	],
	// Razorfen Downs group 1 (WMOID 1356) blockX=1 column -- confirmed
	// independently via wow.export (separate tool, same underlying data)
	// producing the same bad tiles, so this is real bad source data, not a
	// bug in this pipeline's own math.
	wow_anniversary: [
		'528239', '528240', '528241', '528242', // RazorfenDowns group 1, blockX=1 column
	],
	wow_classic: [
	],
	wow_classic_beta: [
	],
};

// mapID is a string (Map.csv's own ID column comes through as a string from
// csv-parse, same as everywhere else in this codebase -- never coerce to
// Number, it would just have to be coerced back to compare against more ID
// strings elsewhere).
function isSkipped(list, flavor, mapID) {
	return !!(mapID && list[flavor] && list[flavor].includes(mapID));
}

module.exports = { skipMaps, skipAdtTiles, skipWmoTiles, skipTileFileDataId, isSkipped };
