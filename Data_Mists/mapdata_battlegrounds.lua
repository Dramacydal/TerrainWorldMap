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
    ["PVPZone01"] = 91,    --Alterac Valley
    ["PVPZone03"] = 92,    --Warsong Gulch
    ["PVPZone04"] = 93,    --Arathi Basin
    ["NetherstormBG"] = 112,    --Eye of the Storm
    ["NorthrendBG"] = 128,    --Strand of the Ancients
    ["IsleofConquest"] = 169,    --Isle of Conquest
    ["CataclysmCTF"] = 206,    --Twin Peaks
    ["STV_Mine_BG"] = 423,    --Silvershard Mines
    ["Gilneas_BG_2"] = 275,    --The Battle for Gilneas
    ["EyeoftheStorm2.0"] = 397,    --Rated Eye of the Storm
    ["ValleyOfPower"] = 417,    --Temple of Kotmogu
    ["GoldRushBG"] = 519,    --Deepwind Gorge
    ["WintergraspEpic"] = 2104,    --Wintergrasp
    ["2755"] = 244,    --Battle for Tol Barad
}

TWM_BATTLEGROUNDS = {
    [C_Map.GetMapInfo(Twm_BattlegroundMapID["PVPZone01"]).name] = {"PVPZone01"},
    [C_Map.GetMapInfo(Twm_BattlegroundMapID["PVPZone03"]).name] = {"PVPZone03"},
    [C_Map.GetMapInfo(Twm_BattlegroundMapID["PVPZone04"]).name] = {"PVPZone04"},
    [C_Map.GetMapInfo(Twm_BattlegroundMapID["NetherstormBG"]).name] = {"NetherstormBG"},
    [C_Map.GetMapInfo(Twm_BattlegroundMapID["NorthrendBG"]).name] = {"NorthrendBG"},
    [C_Map.GetMapInfo(Twm_BattlegroundMapID["IsleofConquest"]).name] = {"IsleofConquest"},
    [C_Map.GetMapInfo(Twm_BattlegroundMapID["CataclysmCTF"]).name] = {"CataclysmCTF"},
    [C_Map.GetMapInfo(Twm_BattlegroundMapID["STV_Mine_BG"]).name] = {"STV_Mine_BG"},
    [C_Map.GetMapInfo(Twm_BattlegroundMapID["Gilneas_BG_2"]).name] = {"Gilneas_BG_2"},
    [C_Map.GetMapInfo(Twm_BattlegroundMapID["EyeoftheStorm2.0"]).name] = {"EyeoftheStorm2.0"},
    [C_Map.GetMapInfo(Twm_BattlegroundMapID["ValleyOfPower"]).name] = {"ValleyOfPower"},
    [C_Map.GetMapInfo(Twm_BattlegroundMapID["GoldRushBG"]).name] = {"GoldRushBG"},
    [C_Map.GetMapInfo(Twm_BattlegroundMapID["WintergraspEpic"]).name] = {"WintergraspEpic"},
    [C_Map.GetMapInfo(Twm_BattlegroundMapID["2755"]).name] = {"2755"},
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
Twm_mapareas["NetherstormBG"] = {
    [0] = {2660.4165039062, 389.58331298828, 2918.75, 1404.1666259766},    --EyeoftheStorm
}
Twm_mapareas["NorthrendBG"] = {
    [0] = {787.5, -956.24993896484, 1883.3332519531, 720.83331298828},    --StrandoftheAncients
}
Twm_mapareas["IsleofConquest"] = {
    [0] = {525, -2125, 1708.3332519531, -58.33333206177},    --IsleofConquest
}
Twm_mapareas["CataclysmCTF"] = {
    [0] = {931.24993896484, -283.33331298828, 2266.6665039062, 1456.25},    --TwinPeaks
}
Twm_mapareas["STV_Mine_BG"] = {
    [0] = {715.25299072266, -200.25300598145, 1035.9201660156, 425.58285522461},    --SilvershardMines
}
Twm_mapareas["Gilneas_BG_2"] = {
    [0] = {1745.8332519531, 443.74996948242, 1604.1666259766, 735.41662597656},    --TheBattleforGilneas
}
Twm_mapareas["EyeoftheStorm2.0"] = {
    [0] = {2660.4165039062, 389.58331298828, 2918.75, 1404.1666259766},    --RatedEyeoftheStorm
}
Twm_mapareas["ValleyOfPower"] = {
    [0] = {1743.75, 904.1669921875, 2083.3330078125, 1522.9169921875},    --TempleofKotmogu
}
Twm_mapareas["GoldRushBG"] = {
    [0] = {1068.75, -14.583984375, 189.583984375, -533.333984375},    --DeepwindGorge
}
Twm_mapareas["WintergraspEpic"] = {
    [0] = {4329.169921875, 1354.1700439453, 5716.669921875, 3733.330078125},    --Wintergrasp
}
Twm_mapareas["2755"] = {
    [0] = {2010.4200439453, -4.16666984558, -560.4169921875, -1904.1700439453},    --BattleforTolBarad
}
