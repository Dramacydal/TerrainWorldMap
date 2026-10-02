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
