-- Vanilla-flavor data (loaded on top of the generic mapdata_poi.lua).
-- uiMapIDs for the top-level continents (Data_Vanilla/UiMapAssignment.1.15.9.69109.csv);
-- same continent uiMapIDs as TBC's Azeroth=1415/Kalimdor=1414 (stable DB2 IDs).
-- No Expansion01 entry: Classic Era has no Outland continent map.
Twm_ContinentMapID = {
    ["Kalimdor"] = 1414,
    ["Azeroth"] = 1415,      -- Eastern Kingdoms
};

-- TerrainWorldMap map mapping
-- Display_Name - Actual Map Folder Name
-- Display name is resolved live via C_Map.GetMapInfo so it always matches
-- this client's own locale/era instead of a stale scraped translation.
TWM_MAPS = {
    [C_Map.GetMapInfo(Twm_ContinentMapID["Azeroth"]).name] = {"Azeroth"},
    [C_Map.GetMapInfo(Twm_ContinentMapID["Kalimdor"]).name] = {"Kalimdor"},
};

-- Instances (entrances) -- all pre-TBC dungeons, same world-space
-- coordinates as TBC's table, so reused as-is.
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
