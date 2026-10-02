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

Twm_WDTValidTiles["2995"] = {
    ["33x20"] = true,
    ["34x20"] = true,
    ["35x20"] = true,
    ["36x20"] = true,
    ["37x20"] = true,
    ["38x20"] = true,
    ["39x20"] = true,
    ["33x21"] = true,
    ["34x21"] = true,
    ["35x21"] = true,
    ["36x21"] = true,
    ["37x21"] = true,
    ["38x21"] = true,
    ["39x21"] = true,
    ["33x22"] = true,
    ["34x22"] = true,
    ["35x22"] = true,
    ["36x22"] = true,
    ["37x22"] = true,
    ["38x22"] = true,
    ["39x22"] = true,
    ["33x23"] = true,
    ["34x23"] = true,
    ["35x23"] = true,
    ["36x23"] = true,
    ["37x23"] = true,
    ["38x23"] = true,
    ["39x23"] = true,
    ["33x24"] = true,
    ["34x24"] = true,
    ["35x24"] = true,
    ["36x24"] = true,
    ["37x24"] = true,
    ["38x24"] = true,
    ["39x24"] = true,
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

Twm_TileFileID["2995"] = {
    ["map33_20"] = 7250251,
    ["map34_20"] = 7250257,
    ["map35_20"] = 7250263,
    ["map36_20"] = 7250269,
    ["map37_20"] = 7250275,
    ["map38_20"] = 7250281,
    ["map39_20"] = 7250287,
    ["map33_21"] = 7250293,
    ["map34_21"] = 7250299,
    ["map35_21"] = 7250305,
    ["map36_21"] = 7250311,
    ["map37_21"] = 7250317,
    ["map38_21"] = 7250323,
    ["map39_21"] = 7250329,
    ["map33_22"] = 7250335,
    ["map34_22"] = 7250341,
    ["map35_22"] = 7250347,
    ["map36_22"] = 7250353,
    ["map37_22"] = 7250359,
    ["map38_22"] = 7250365,
    ["map39_22"] = 7250371,
    ["map33_23"] = 7250377,
    ["map34_23"] = 7250383,
    ["map35_23"] = 7250389,
    ["map36_23"] = 7250395,
    ["map37_23"] = 7250401,
    ["map38_23"] = 7250407,
    ["map39_23"] = 7250413,
    ["map33_24"] = 7250419,
    ["map34_24"] = 7250425,
    ["map35_24"] = 7250431,
    ["map36_24"] = 7250437,
    ["map37_24"] = 7250443,
    ["map38_24"] = 7250449,
    ["map39_24"] = 7250455,
}
