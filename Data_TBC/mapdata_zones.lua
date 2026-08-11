-- TBC-flavor data (loaded on top of the generic mapdata_zones.lua).

-- Capital/major city uiMapIDs (WorldMapFrame zoom-in sub-maps), hand-collected
-- via C_Map.GetMapChildrenInfo since Blizzard's map hierarchy gives no
-- type/parent-based way to tell a city map apart from a real outdoor zone --
-- see WorldMapOverlay.lua's city-map-tiles option.
Twm_CityMapIDs = {
    [1453] = true, -- Stormwind City
    [1455] = true, -- Ironforge
    [1458] = true, -- Undercity
    [1954] = true, -- Silvermoon City
    [1454] = true, -- Orgrimmar
    [1456] = true, -- Thunder Bluff
    [1457] = true, -- Darnassus
    [1947] = true, -- The Exodar
    [1955] = true, -- Shattrath City
}


