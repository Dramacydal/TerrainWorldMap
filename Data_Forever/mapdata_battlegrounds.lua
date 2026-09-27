-- GENERATED FILE -- do not hand-edit, regenerate with scripts/gen_battlegrounds.js
-- and replace this file wholesale. See scripts/README.md for details.
--
-- Battleground zone boxes + their own position-tracking UiMapIDs, kept
-- deliberately separate from Twm_ContinentMapID/TWM_MAPS (see this
-- script's header). Twm_mapareas is the same generic per-map-name box
-- registry gen_mapareas.js's continents already populate -- adding
-- battleground keys to it isn't the same thing as mixing into the
-- continent-list tables.

Twm_BattlegroundMapID = {
    ["PVPZone01"] = 1459,    --Alterac Valley
    ["PVPZone03"] = 1460,    --Warsong Gulch
    ["PVPZone04"] = 1461,    --Arathi Basin
    ["2997"] = 2524,    --Darkspear Islands
}

TWM_BATTLEGROUNDS = {
    [C_Map.GetMapInfo(Twm_BattlegroundMapID["PVPZone01"]).name] = {"PVPZone01"},
    [C_Map.GetMapInfo(Twm_BattlegroundMapID["PVPZone03"]).name] = {"PVPZone03"},
    [C_Map.GetMapInfo(Twm_BattlegroundMapID["PVPZone04"]).name] = {"PVPZone04"},
    [C_Map.GetMapInfo(Twm_BattlegroundMapID["2997"]).name] = {"2997"},
}

Twm_mapareas["PVPZone01"] = {
    [0] = {1781.2498779297, -2456.25, 1085.4166259766, -1739.5832519531},    --AlteracValley
}
Twm_mapareas["PVPZone03"] = {
    [0] = {2041.6666259766, 895.83331298828, 1627.0832519531, 862.49993896484},    --WarsongGulch
}
Twm_mapareas["PVPZone04"] = {
    [0] = {1858.3332519531, 102.08332824707, 1508.3332519531, 337.5},    --ArathiBasin
}
Twm_mapareas["2997"] = {
    [0] = {2918.75, 993.75, 447.916015625, -835.416015625},    --DarkspearIslands
}
