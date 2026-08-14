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
