-- Mists-flavor data (loaded on top of the generic mapdata_zones.lua).
-- Capital/major city uiMapIDs -- found in the exported UiMap.csv by name
-- (Type=3, same as regular zones -- no dedicated city UIMapType exists).
-- Note: these IDs don't match TBC/Vanilla's (84 vs 1453 etc.) -- MoP
-- Classic's UiMap table was renumbered from a much lower base, unrelated
-- to the legacy TBC/Vanilla numbering.
Twm_CityMapIDs = {
    [84] = true,  -- Stormwind City
    [87] = true,  -- Ironforge
    [998] = true, -- Undercity
    [85] = true,  -- Orgrimmar
    [88] = true,  -- Thunder Bluff
    [89] = true,  -- Darnassus
    [103] = true, -- The Exodar
    [110] = true, -- Silvermoon City
}
