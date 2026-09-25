-- uiMapIDs for the top-level continents TerrainWorldMap knows how to render,
-- for WoW Forever (wow_classic_beta). Kalimdor/Azeroth are the same stable
-- IDs every other flavor already uses. "2991" (Zephras Isle, no proper
-- flavor-specific directory name assigned by Blizzard yet in this beta --
-- see gen_mapareas.js's continent list) was derived from
-- UiMapAssignment.csv directly rather than a live C_Map.GetMapChildrenInfo
-- call (unlike the other flavors' own mapdata_poi.lua): its UiMapAssignment
-- row with AreaID=0 (the "whole map" sentinel, same convention as
-- Twm_mapareas[continent][0]) has MapID=2991 and UiMapID=2665 -- the exact
-- same MapID/AreaID=0 pattern Kalimdor(1414)/Eastern Kingdoms(1415) have
-- for their own MapIDs (1/0). A second UiMapID (2521) also exists for
-- Zephras Isle but assigns AreaID=16593 (its one real zone, not the whole
-- map), same relationship Durotar/Mulgore's own UiMapIDs have to Kalimdor.
Twm_ContinentMapID = {
    ["Kalimdor"] = 1414,
    ["Azeroth"] = 1415,      -- Eastern Kingdoms
    ["2991"] = 2665,         -- Zephras Isle
};

-- TerrainWorldMap map mapping
-- Display_Name - Actual Map Folder Name
-- Display name is resolved live via C_Map.GetMapInfo so it always matches
-- this client's own locale/era instead of a stale scraped translation.
TWM_MAPS = {
    [C_Map.GetMapInfo(Twm_ContinentMapID["Azeroth"]).name] = {"Azeroth"},
    [C_Map.GetMapInfo(Twm_ContinentMapID["Kalimdor"]).name] = {"Kalimdor"},
    [C_Map.GetMapInfo(Twm_ContinentMapID["2991"]).name] = {"2991"},
};
