-- uiMapIDs for the top-level continents TerrainWorldMap knows how to render, as
-- reported by this client (2.5.6 / TBC Anniversary) via
-- C_Map.GetMapChildrenInfo(946, Enum.UIMapType.Continent, true).
-- No Northrend entry: this client doesn't have a Northrend continent map.
Twm_ContinentMapID = {
    ["Kalimdor"] = 1414,
    ["Azeroth"] = 1415,      -- Eastern Kingdoms
    ["Expansion01"] = 1945,  -- Outland
};

-- TerrainWorldMap map mapping
-- Display_Name - Actual Map Folder Name
-- Display name is resolved live via C_Map.GetMapInfo so it always matches
-- this client's own locale/era instead of a stale scraped translation.
TWM_MAPS = {
    [C_Map.GetMapInfo(Twm_ContinentMapID["Azeroth"]).name] = {"Azeroth"},
    [C_Map.GetMapInfo(Twm_ContinentMapID["Kalimdor"]).name] = {"Kalimdor"},
    [C_Map.GetMapInfo(Twm_ContinentMapID["Expansion01"]).name] = {"Expansion01"},
};
