-- GENERATED FILE -- do not hand-edit, regenerate with scripts/parse_wdt.js
-- and replace this file wholesale. See scripts/README.md for details.
--
-- Which map tiles (TerrainWorldMap grid-cell coords) have real terrain, extracted
-- from this client's own world/maps/<continent>/<continent>.wdt files
-- (MAIN/MAID chunks, rootADT field). This is ground truth: a tile is only
-- ever real if the client actually ships terrain for it, regardless of
-- what the (possibly orphaned) minimap preview texture or C_Map zone data
-- might otherwise suggest. Value is `true` if no ADT areaID could be
-- resolved for that tile (see the extracted world/maps ADT dir), otherwise the tile's own
-- majority-vote AreaID (a real, truthy number) -- resolve to a display
-- name via Twm_areadb[id]. Twm_WDTValidTiles itself is declared once,
-- centrally, in mapdata_zones.lua -- this file (and its sibling
-- mapdata_tiles_<kind>.lua split files) only assigns its own keys.

Twm_WDTValidTiles["PVPZone01"] = {
    ["30x29"] = 2597,
    ["31x29"] = 2597,
    ["32x29"] = 2597,
    ["33x29"] = 2597,
    ["34x29"] = 2597,
    ["30x30"] = 2597,
    ["31x30"] = 2597,
    ["32x30"] = 2597,
    ["33x30"] = 2597,
    ["34x30"] = 2597,
    ["30x31"] = 2597,
    ["31x31"] = 2597,
    ["32x31"] = 2597,
    ["33x31"] = 2597,
    ["34x31"] = 2597,
    ["30x32"] = 2597,
    ["31x32"] = 2597,
    ["32x32"] = 2597,
    ["33x32"] = 2597,
    ["34x32"] = 2597,
    ["30x33"] = 2597,
    ["31x33"] = 2597,
    ["32x33"] = 2597,
    ["33x33"] = 2597,
    ["34x33"] = 2597,
    ["30x34"] = 2597,
    ["31x34"] = 2597,
    ["32x34"] = 2597,
    ["33x34"] = 2597,
    ["34x34"] = 2597,
    ["30x35"] = 2597,
    ["31x35"] = 2597,
    ["32x35"] = 2597,
    ["33x35"] = 2597,
    ["34x35"] = 2597,
}

Twm_WDTValidTiles["PVPZone03"] = {
    ["27x27"] = true,
    ["28x27"] = true,
    ["29x27"] = true,
    ["30x27"] = true,
    ["27x28"] = true,
    ["28x28"] = 3277,
    ["29x28"] = 3277,
    ["30x28"] = 3277,
    ["27x29"] = true,
    ["28x29"] = 3277,
    ["29x29"] = 3277,
    ["30x29"] = 3277,
    ["27x30"] = true,
    ["28x30"] = 3277,
    ["29x30"] = 3277,
    ["30x30"] = 3277,
}

Twm_WDTValidTiles["PVPZone04"] = {
    ["28x28"] = 3358,
    ["29x28"] = 3358,
    ["30x28"] = 3358,
    ["31x28"] = 3358,
    ["28x29"] = 3358,
    ["29x29"] = 3358,
    ["30x29"] = 3358,
    ["31x29"] = 3358,
    ["28x30"] = 3358,
    ["29x30"] = 3358,
    ["30x30"] = 3358,
    ["31x30"] = 3358,
    ["28x31"] = 3358,
    ["29x31"] = 3358,
    ["30x31"] = 3358,
    ["31x31"] = 3358,
}

Twm_WDTValidTiles["2997"] = {
    ["26x30"] = 16606,
    ["27x30"] = 16606,
    ["28x30"] = 16606,
    ["29x30"] = 16606,
    ["30x30"] = 16606,
    ["26x31"] = 16606,
    ["27x31"] = 16606,
    ["28x31"] = 16606,
    ["29x31"] = 16606,
    ["30x31"] = 16606,
    ["26x32"] = 16606,
    ["27x32"] = 16606,
    ["28x32"] = 16606,
    ["29x32"] = 16606,
    ["30x32"] = 16606,
    ["26x33"] = 16606,
    ["27x33"] = 16606,
    ["28x33"] = 16606,
    ["29x33"] = 16606,
    ["30x33"] = 16606,
    ["26x34"] = 16606,
    ["27x34"] = 16606,
    ["28x34"] = 16606,
    ["29x34"] = 16606,
    ["30x34"] = 16606,
}

-- FileDataID for each tile's own minimap BLP (both the regular and, if
-- present, noLiquid variant), resolved from a community listfile at
-- generation time (--listfile). Only baked in for a flavor where loading
-- by plain "World\Minimaps\..." path string doesn't work at all (WoW:
-- Forever/Camelot, confirmed by testing SetTexture with a raw path vs the
-- equivalent numeric FileDataID -- see .claude-docs/gotchas.md).
-- TWM_GetTileTexture (TerrainWorldMap.lua) prefers this table when present,
-- falling back to the old path string otherwise -- every other flavor is
-- untouched. Keyed by the same filename TWM_GetTileFileName returns.
-- Declared once, centrally, in mapdata_zones.lua -- see Twm_WDTValidTiles above.

Twm_TileFileID["2997"] = {
    ["map26_30"] = 7252061,
    ["map27_30"] = 7253363,
    ["map28_30"] = 7253369,
    ["map29_30"] = 7253375,
    ["map30_30"] = 7253381,
    ["map26_31"] = 7253387,
    ["map27_31"] = 7253393,
    ["map28_31"] = 7253399,
    ["map29_31"] = 7253405,
    ["map30_31"] = 7253411,
    ["map26_32"] = 7253417,
    ["map27_32"] = 7253423,
    ["map28_32"] = 7253429,
    ["map29_32"] = 7253435,
    ["map30_32"] = 7253441,
    ["map26_33"] = 7253447,
    ["map27_33"] = 7253453,
    ["map28_33"] = 7253459,
    ["map29_33"] = 7253465,
    ["map30_33"] = 7253471,
    ["map26_34"] = 7253477,
    ["map27_34"] = 7253483,
    ["map28_34"] = 7253489,
    ["map29_34"] = 7253495,
    ["map30_34"] = 7253501,
}

Twm_TileFileID["PVPZone01"] = {
    ["map30_29"] = 209426,
    ["map31_29"] = 209433,
    ["map32_29"] = 209440,
    ["map33_29"] = 209447,
    ["map34_29"] = 209454,
    ["map30_30"] = 209427,
    ["map31_30"] = 209434,
    ["map32_30"] = 209441,
    ["map33_30"] = 209448,
    ["map34_30"] = 209455,
    ["map30_31"] = 209428,
    ["map31_31"] = 209435,
    ["map32_31"] = 209442,
    ["map33_31"] = 209449,
    ["map34_31"] = 209456,
    ["map30_32"] = 209429,
    ["map31_32"] = 209436,
    ["map32_32"] = 209443,
    ["map33_32"] = 209450,
    ["map34_32"] = 209457,
    ["map30_33"] = 209430,
    ["map31_33"] = 209437,
    ["map32_33"] = 209444,
    ["map33_33"] = 209451,
    ["map34_33"] = 209458,
    ["map30_34"] = 209431,
    ["map31_34"] = 209438,
    ["map32_34"] = 209445,
    ["map33_34"] = 209452,
    ["map34_34"] = 209459,
    ["map30_35"] = 209432,
    ["map31_35"] = 209439,
    ["map32_35"] = 209446,
    ["map33_35"] = 209453,
    ["map34_35"] = 209460,
}

Twm_TileFileID["PVPZone03"] = {
    ["map27_27"] = 209491,
    ["map28_27"] = 209495,
    ["map29_27"] = 209499,
    ["map30_27"] = 209503,
    ["map27_28"] = 209492,
    ["map28_28"] = 209496,
    ["map29_28"] = 209500,
    ["map30_28"] = 209504,
    ["map27_29"] = 209493,
    ["map28_29"] = 209497,
    ["map29_29"] = 209501,
    ["map30_29"] = 209505,
    ["map27_30"] = 209494,
    ["map28_30"] = 209498,
    ["map29_30"] = 209502,
    ["map30_30"] = 209506,
}

Twm_TileFileID["PVPZone04"] = {
    ["map28_28"] = 209507,
    ["map29_28"] = 209511,
    ["map30_28"] = 209515,
    ["map31_28"] = 209519,
    ["map28_29"] = 209508,
    ["map29_29"] = 209512,
    ["map30_29"] = 209516,
    ["map31_29"] = 209520,
    ["map28_30"] = 209509,
    ["map29_30"] = 209513,
    ["map30_30"] = 209517,
    ["map31_30"] = 209521,
    ["map28_31"] = 209510,
    ["map29_31"] = 209514,
    ["map30_31"] = 209518,
    ["map31_31"] = 209522,
}
