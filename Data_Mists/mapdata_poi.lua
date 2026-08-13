-- Mists-flavor data (loaded on top of the generic mapdata_poi.lua).
-- uiMapIDs for the top-level continents (Data_Mists/UiMapAssignment.5.5.4.69155.csv,
-- see scripts/gen_mapareas.js's findContinents()). "HawaiiMainLand" is
-- Blizzard's own internal Map.csv Directory name for Pandaria (dev
-- codename) -- matches the key gen_mapareas.js wrote into
-- Data_Mists/mapdata_continents.lua.
--
-- Deephome/LostIsles/Gilneas2/MaelstromZone/TolBarad/MoguIslandDailyArea are
-- standalone single-or-few-zone "island" maps (own MapID, own real WDT --
-- see gen_mapareas.js's findContinents()). Where a map has more than one
-- child uiMapID, picks the "main" one (e.g. LostIsles over its Kezan
-- sub-zone, TolBarad over its Peninsula sub-zone) -- what a caller sees on
-- C_Map.GetMapInfo(uiMapID).name when standing there. Unlike
-- mapdata_continents.lua, this file is hand-maintained, not generated.
Twm_ContinentMapID = {
    ["Kalimdor"] = 12,
    ["Azeroth"] = 13,          -- Eastern Kingdoms
    ["Expansion01"] = 1467,    -- Outland
    ["Northrend"] = 113,
    ["HawaiiMainLand"] = 424,  -- Pandaria
    ["Deephome"] = 207,               -- Deepholm
    ["LostIsles"] = 174,               -- The Lost Isles (Kezan is a sub-zone)
    ["Gilneas2"] = 202,                -- Gilneas City
    ["MaelstromZone"] = 276,           -- The Maelstrom (Deathwing fight)
    ["TolBarad"] = 244,                -- Tol Barad (Peninsula is a sub-zone)
    ["MoguIslandDailyArea"] = 504,     -- Isle of Thunder
};

-- TerrainWorldMap map mapping
-- Display_Name - Actual Map Folder Name
-- Display name is resolved live via C_Map.GetMapInfo so it always matches
-- this client's own locale/era instead of a stale scraped translation.
TWM_MAPS = {
    [C_Map.GetMapInfo(Twm_ContinentMapID["Azeroth"]).name] = {"Azeroth"},
    [C_Map.GetMapInfo(Twm_ContinentMapID["Kalimdor"]).name] = {"Kalimdor"},
    [C_Map.GetMapInfo(Twm_ContinentMapID["Expansion01"]).name] = {"Expansion01"},
    [C_Map.GetMapInfo(Twm_ContinentMapID["Northrend"]).name] = {"Northrend"},
    [C_Map.GetMapInfo(Twm_ContinentMapID["HawaiiMainLand"]).name] = {"HawaiiMainLand"},
    [C_Map.GetMapInfo(Twm_ContinentMapID["Deephome"]).name] = {"Deephome"},
    [C_Map.GetMapInfo(Twm_ContinentMapID["LostIsles"]).name] = {"LostIsles"},
    [C_Map.GetMapInfo(Twm_ContinentMapID["Gilneas2"]).name] = {"Gilneas2"},
    [C_Map.GetMapInfo(Twm_ContinentMapID["MaelstromZone"]).name] = {"MaelstromZone"},
    [C_Map.GetMapInfo(Twm_ContinentMapID["TolBarad"]).name] = {"TolBarad"},
    [C_Map.GetMapInfo(Twm_ContinentMapID["MoguIslandDailyArea"]).name] = {"MoguIslandDailyArea"},
};

-- Instances (entrances) -- only the pre-TBC Kalimdor/Azeroth dungeons are
-- filled in (reused verbatim from Data_TBC, same world-space coordinates).
-- TODO: no Northrend/Outland/Pandaria dungeon entrances hand-collected yet.
Twm_instances = {
    ["Kalimdor"] = {
        {"Ahn'Qiraj",           1526, -8132},
        {"Blackfathom Deeps",   888, 4138},
        {"Dire Maul",           1341, -4367},
        {"Maraudon",            2932, -1415},
        {"Onyxia's Lair",       -3730, -4712},
        {"Ragefire Chasm",      -4416.2, 1818.4},
        {"Razorfen Downs",      -2336, -4721},
        {"Razorfen Kraul",      -1606, -4455},
        {"Wailing Caverns",     -2027, -796},
        {"Zul'Farrak",          -2904, -6665},
    },
    ["Azeroth"] = {
        {"Blackrock Depths",    -919, -7179},
        {"Blackrock Spire",     -1223, -7529},
        {"Gnomeregan",          933, -5161},
        {"Scarlet Monestary",   -867, 2916},
        {"Scholomance",         -2567, 1275},
        {"Shadowfang Keep",     1585, -229},
        {"Stratholme",          -3375, 3381},
        {"Stratholme (Service Entrance)", -4033, 3187},
        {"The Deadmines",       1512, -11081},
        {"The Temple of Atal'Hakkar", -3826, -10414},
        {"Zul'Gurub",           -1250, -11915},
    }
};
