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

Twm_WDTValidTiles["Shadowfang"] = {
    ["25x30"] = 209,
    ["26x30"] = 209,
    ["27x30"] = 209,
    ["28x30"] = 209,
    ["29x30"] = 209,
    ["25x31"] = 209,
    ["26x31"] = 209,
    ["27x31"] = 209,
    ["28x31"] = 209,
    ["29x31"] = 209,
    ["25x32"] = 209,
    ["26x32"] = 209,
    ["27x32"] = 209,
    ["28x32"] = 209,
    ["29x32"] = 209,
    ["25x33"] = 209,
    ["26x33"] = 209,
    ["27x33"] = 209,
    ["28x33"] = 209,
    ["29x33"] = 209,
    ["25x34"] = 209,
    ["26x34"] = 209,
    ["27x34"] = 209,
    ["28x34"] = 209,
    ["29x34"] = 209,
}

Twm_WDTValidTiles["StormwindJail"] = {
}

Twm_WDTValidTiles["DeadminesInstance"] = {
    ["30x30"] = 1581,
    ["31x30"] = 1581,
    ["32x30"] = 1581,
    ["33x30"] = 1581,
    ["34x30"] = 1581,
    ["35x30"] = 1581,
    ["30x31"] = 1581,
    ["31x31"] = 1581,
    ["32x31"] = 1581,
    ["33x31"] = 1581,
    ["34x31"] = 1581,
    ["35x31"] = 1581,
    ["30x32"] = 1581,
    ["31x32"] = 1581,
    ["32x32"] = 1581,
    ["33x32"] = 1581,
    ["34x32"] = 1581,
    ["35x32"] = 1581,
    ["30x33"] = 1581,
    ["31x33"] = 1581,
    ["32x33"] = 1581,
    ["33x33"] = 1581,
    ["34x33"] = 1581,
    ["35x33"] = 1581,
    ["30x34"] = true,
    ["31x34"] = true,
    ["32x34"] = 1581,
    ["33x34"] = 1581,
    ["34x34"] = 1581,
    ["35x34"] = 1581,
    ["30x35"] = true,
    ["31x35"] = true,
    ["32x35"] = 1581,
    ["33x35"] = 1581,
    ["34x35"] = 1581,
    ["35x35"] = 1581,
}

Twm_WDTValidTiles["WailingCaverns"] = {
}

Twm_WDTValidTiles["RazorfenKraulInstance"] = {
    ["27x27"] = 491,
    ["28x27"] = 491,
    ["29x27"] = 491,
    ["27x28"] = 491,
    ["28x28"] = 491,
    ["29x28"] = 491,
}

Twm_WDTValidTiles["Blackfathom"] = {
}

Twm_WDTValidTiles["Uldaman"] = {
}

Twm_WDTValidTiles["GnomeragonInstance"] = {
}

Twm_WDTValidTiles["SunkenTemple"] = {
}

Twm_WDTValidTiles["RazorfenDowns"] = {
    ["27x26"] = 722,
    ["28x26"] = 722,
    ["29x26"] = 722,
    ["30x26"] = 722,
    ["31x26"] = 722,
    ["32x26"] = 722,
    ["27x27"] = 722,
    ["28x27"] = 722,
    ["29x27"] = 722,
    ["30x27"] = 722,
    ["31x27"] = 722,
    ["32x27"] = 722,
    ["27x28"] = 722,
    ["28x28"] = 722,
    ["29x28"] = 722,
    ["30x28"] = 722,
    ["31x28"] = 722,
    ["32x28"] = 722,
    ["27x29"] = 722,
    ["28x29"] = 722,
    ["29x29"] = 722,
    ["30x29"] = 722,
    ["31x29"] = 722,
    ["32x29"] = 722,
}

Twm_WDTValidTiles["MonasteryInstances"] = {
    ["28x27"] = 796,
    ["29x27"] = 796,
    ["30x27"] = 796,
    ["31x27"] = 796,
    ["32x27"] = 796,
    ["33x27"] = 796,
    ["28x28"] = 796,
    ["29x28"] = 796,
    ["30x28"] = 796,
    ["31x28"] = 796,
    ["32x28"] = 796,
    ["33x28"] = 796,
    ["28x29"] = 796,
    ["29x29"] = 796,
    ["30x29"] = 796,
    ["31x29"] = 796,
    ["32x29"] = 796,
    ["33x29"] = 796,
    ["28x30"] = 796,
    ["29x30"] = 796,
    ["30x30"] = 796,
    ["31x30"] = 796,
    ["32x30"] = 796,
    ["33x30"] = 796,
    ["28x31"] = 796,
    ["29x31"] = 796,
    ["30x31"] = 796,
    ["31x31"] = 796,
    ["32x31"] = 796,
    ["33x31"] = 796,
    ["28x32"] = 796,
    ["29x32"] = 796,
    ["30x32"] = 796,
    ["31x32"] = 796,
    ["32x32"] = 796,
    ["33x32"] = 796,
}

Twm_WDTValidTiles["TanarisInstance"] = {
    ["29x27"] = true,
    ["30x27"] = true,
    ["31x27"] = true,
    ["29x28"] = 1176,
    ["30x28"] = 1176,
    ["31x28"] = 1176,
    ["29x29"] = 1176,
    ["30x29"] = 1176,
    ["31x29"] = 1176,
    ["29x30"] = 1176,
    ["30x30"] = 1176,
    ["31x30"] = 1176,
    ["29x31"] = 1176,
    ["30x31"] = 1176,
    ["31x31"] = 1176,
    ["29x32"] = 1176,
    ["30x32"] = 1176,
    ["31x32"] = 1176,
    ["29x33"] = 1176,
    ["30x33"] = 1176,
    ["31x33"] = 1176,
}

Twm_WDTValidTiles["BlackRockSpire"] = {
}

Twm_WDTValidTiles["BlackrockDepths"] = {
}

Twm_WDTValidTiles["CavernsOfTime"] = {
    ["27x25"] = 2367,
    ["28x25"] = 2367,
    ["29x25"] = 2367,
    ["30x25"] = 2367,
    ["31x25"] = 2367,
    ["32x25"] = 2367,
    ["27x26"] = 2367,
    ["28x26"] = 2367,
    ["29x26"] = 2367,
    ["30x26"] = 2367,
    ["31x26"] = 2367,
    ["32x26"] = 2367,
    ["27x27"] = 2367,
    ["28x27"] = 2367,
    ["29x27"] = 2367,
    ["30x27"] = 2367,
    ["31x27"] = 2367,
    ["32x27"] = 2367,
    ["27x28"] = 2367,
    ["28x28"] = 2367,
    ["29x28"] = 2367,
    ["30x28"] = 2367,
    ["31x28"] = 2367,
    ["32x28"] = 2367,
    ["27x29"] = 2367,
    ["28x29"] = 2367,
    ["29x29"] = 2367,
    ["30x29"] = 2367,
    ["31x29"] = 2367,
    ["32x29"] = 2367,
    ["17x34"] = 2366,
    ["18x34"] = 2366,
    ["19x34"] = 2366,
    ["17x35"] = 2366,
    ["18x35"] = 2366,
    ["19x35"] = 2366,
    ["17x36"] = 2366,
    ["18x36"] = 2366,
    ["19x36"] = 2366,
}

Twm_WDTValidTiles["SchoolofNecromancy"] = {
    ["30x29"] = true,
    ["31x29"] = true,
    ["32x29"] = true,
    ["33x29"] = true,
    ["30x30"] = true,
    ["31x30"] = true,
    ["32x30"] = true,
    ["33x30"] = true,
    ["30x31"] = true,
    ["31x31"] = 2057,
    ["32x31"] = 2057,
    ["33x31"] = 2057,
    ["30x32"] = true,
    ["31x32"] = 2057,
    ["32x32"] = 2057,
    ["33x32"] = 2057,
}

Twm_WDTValidTiles["Stratholme"] = {
    ["36x24"] = 2017,
    ["37x24"] = 2017,
    ["38x24"] = 2017,
    ["39x24"] = 2017,
    ["40x24"] = 2017,
    ["36x25"] = 2017,
    ["37x25"] = 2017,
    ["38x25"] = 2017,
    ["39x25"] = 2017,
    ["40x25"] = 2017,
    ["36x26"] = 2017,
    ["37x26"] = 2017,
    ["38x26"] = 2017,
    ["39x26"] = 2017,
    ["40x26"] = 2017,
    ["36x27"] = 2017,
    ["37x27"] = 2017,
    ["38x27"] = 2017,
    ["39x27"] = 2017,
    ["40x27"] = 2017,
}

Twm_WDTValidTiles["Mauradon"] = {
}

Twm_WDTValidTiles["OrgrimmarInstance"] = {
}

Twm_WDTValidTiles["DireMaul"] = {
}

Twm_WDTValidTiles["HellfireMilitary"] = {
}

Twm_WDTValidTiles["HellfireDemon"] = {
}

Twm_WDTValidTiles["HellfireRampart"] = {
    ["24x30"] = true,
    ["25x30"] = true,
    ["26x30"] = true,
    ["27x30"] = true,
    ["28x30"] = true,
    ["29x30"] = true,
    ["30x30"] = true,
    ["31x30"] = true,
    ["32x30"] = true,
    ["24x31"] = true,
    ["25x31"] = true,
    ["26x31"] = true,
    ["27x31"] = true,
    ["28x31"] = true,
    ["29x31"] = true,
    ["30x31"] = true,
    ["31x31"] = true,
    ["32x31"] = true,
    ["24x32"] = true,
    ["25x32"] = true,
    ["26x32"] = true,
    ["27x32"] = true,
    ["28x32"] = true,
    ["29x32"] = true,
    ["30x32"] = true,
    ["31x32"] = true,
    ["32x32"] = true,
    ["24x33"] = true,
    ["25x33"] = true,
    ["26x33"] = true,
    ["27x33"] = true,
    ["28x33"] = 3562,
    ["29x33"] = 3562,
    ["30x33"] = true,
    ["31x33"] = true,
    ["32x33"] = true,
    ["24x34"] = true,
    ["25x34"] = true,
    ["26x34"] = true,
    ["27x34"] = true,
    ["28x34"] = 3562,
    ["29x34"] = 3562,
    ["30x34"] = true,
    ["31x34"] = true,
    ["32x34"] = true,
    ["24x35"] = true,
    ["25x35"] = true,
    ["26x35"] = true,
    ["27x35"] = true,
    ["28x35"] = true,
    ["29x35"] = true,
    ["30x35"] = true,
    ["31x35"] = true,
    ["32x35"] = true,
    ["24x36"] = true,
    ["25x36"] = true,
    ["26x36"] = true,
    ["27x36"] = true,
    ["28x36"] = true,
    ["29x36"] = true,
    ["30x36"] = true,
    ["31x36"] = true,
    ["32x36"] = true,
    ["24x37"] = true,
    ["25x37"] = true,
    ["26x37"] = true,
    ["27x37"] = true,
    ["28x37"] = true,
    ["29x37"] = true,
    ["30x37"] = true,
    ["31x37"] = true,
    ["32x37"] = true,
}

Twm_WDTValidTiles["CoilfangPumping"] = {
}

Twm_WDTValidTiles["CoilfangMarsh"] = {
}

Twm_WDTValidTiles["CoilfangDraenei"] = {
}

Twm_WDTValidTiles["TempestKeepArcane"] = {
}

Twm_WDTValidTiles["TempestKeepAtrium"] = {
}

Twm_WDTValidTiles["TempestKeepFactory"] = {
}

Twm_WDTValidTiles["AuchindounShadow"] = {
}

Twm_WDTValidTiles["AuchindounDemon"] = {
}

Twm_WDTValidTiles["AuchindounEthereal"] = {
}

Twm_WDTValidTiles["AuchindounDraenei"] = {
}

Twm_WDTValidTiles["HillsbradPast"] = {
    ["27x25"] = 2367,
    ["28x25"] = 2367,
    ["29x25"] = 2367,
    ["30x25"] = 2367,
    ["31x25"] = 2367,
    ["32x25"] = 2367,
    ["27x26"] = 2367,
    ["28x26"] = 2367,
    ["29x26"] = 2367,
    ["30x26"] = 2367,
    ["31x26"] = 2367,
    ["32x26"] = 2367,
    ["27x27"] = 2367,
    ["28x27"] = 2367,
    ["29x27"] = 2367,
    ["30x27"] = 2367,
    ["31x27"] = 2367,
    ["32x27"] = 2367,
    ["27x28"] = 2367,
    ["28x28"] = 2367,
    ["29x28"] = 2367,
    ["30x28"] = 2367,
    ["31x28"] = 2367,
    ["32x28"] = 2367,
    ["27x29"] = 2367,
    ["28x29"] = 2367,
    ["29x29"] = 2367,
    ["30x29"] = 2367,
    ["31x29"] = 2367,
    ["32x29"] = 2367,
    ["27x30"] = 2367,
    ["28x30"] = 2367,
    ["29x30"] = 2367,
    ["30x30"] = 2367,
    ["31x30"] = 2367,
    ["32x30"] = 2367,
}

Twm_WDTValidTiles["Sunwell5ManFix"] = {
    ["27x27"] = true,
    ["28x27"] = true,
    ["29x27"] = true,
    ["30x27"] = true,
    ["31x27"] = true,
    ["32x27"] = true,
    ["33x27"] = true,
    ["27x28"] = true,
    ["28x28"] = true,
    ["29x28"] = true,
    ["30x28"] = true,
    ["31x28"] = true,
    ["32x28"] = true,
    ["33x28"] = true,
    ["27x29"] = true,
    ["28x29"] = true,
    ["29x29"] = true,
    ["30x29"] = true,
    ["31x29"] = true,
    ["32x29"] = true,
    ["33x29"] = true,
    ["34x29"] = true,
    ["35x29"] = true,
    ["36x29"] = true,
    ["27x30"] = true,
    ["28x30"] = true,
    ["29x30"] = true,
    ["30x30"] = true,
    ["31x30"] = 4131,
    ["32x30"] = 4131,
    ["33x30"] = true,
    ["34x30"] = true,
    ["35x30"] = true,
    ["36x30"] = true,
    ["27x31"] = true,
    ["28x31"] = true,
    ["29x31"] = true,
    ["30x31"] = true,
    ["31x31"] = 4131,
    ["32x31"] = 4131,
    ["33x31"] = true,
    ["34x31"] = true,
    ["35x31"] = true,
    ["36x31"] = true,
    ["27x32"] = true,
    ["28x32"] = true,
    ["29x32"] = true,
    ["30x32"] = true,
    ["31x32"] = 4131,
    ["32x32"] = 4131,
    ["33x32"] = true,
    ["34x32"] = true,
    ["35x32"] = true,
    ["36x32"] = true,
    ["27x33"] = true,
    ["28x33"] = true,
    ["29x33"] = true,
    ["30x33"] = true,
    ["31x33"] = true,
    ["32x33"] = true,
    ["33x33"] = true,
    ["34x33"] = true,
    ["35x33"] = true,
    ["36x33"] = true,
}
