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

Twm_WDTValidTiles["PVPZone05"] = {
    ["25x23"] = 3698,
    ["26x23"] = 3698,
    ["27x23"] = 3698,
    ["25x24"] = 3698,
    ["26x24"] = 3698,
    ["27x24"] = 3698,
    ["25x25"] = 3698,
    ["26x25"] = 3698,
    ["27x25"] = 3698,
}

Twm_WDTValidTiles["bladesedgearena"] = {
    ["30x19"] = 3702,
    ["31x19"] = 3702,
    ["32x19"] = 3702,
    ["30x20"] = 3702,
    ["31x20"] = 3702,
    ["32x20"] = 3702,
    ["30x21"] = 3702,
    ["31x21"] = 3702,
    ["32x21"] = 3702,
}

Twm_WDTValidTiles["PVPLordaeron"] = {
    ["26x27"] = true,
    ["27x27"] = true,
    ["28x27"] = true,
    ["29x27"] = true,
    ["30x27"] = true,
    ["26x28"] = true,
    ["27x28"] = 3968,
    ["28x28"] = 3968,
    ["29x28"] = 3968,
    ["30x28"] = true,
    ["26x29"] = true,
    ["27x29"] = 3968,
    ["28x29"] = 3968,
    ["29x29"] = 3968,
    ["30x29"] = true,
    ["26x30"] = true,
    ["27x30"] = 3968,
    ["28x30"] = 3968,
    ["29x30"] = 3968,
    ["30x30"] = true,
    ["26x31"] = true,
    ["27x31"] = true,
    ["28x31"] = true,
    ["29x31"] = true,
    ["30x31"] = true,
}
