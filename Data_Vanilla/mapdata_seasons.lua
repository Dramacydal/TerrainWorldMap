-- Hand-maintained. Dungeon/raid maps (Map.csv IDs, strings) that exist only
-- in a seasonal ruleset; listed in the dropdown only while
-- C_Seasons.GetActiveSeason() equals the key (2 = Season of Discovery).
-- Read by TerrainWorldMap.lua (TWM_IsMapHiddenBySeason).
Twm_SeasonOnlyMaps = {
    [2] = {
        "2720",  -- The Searing Basin
        "2784",  -- Demon Fall Canyon
        "2789",  -- The Tainted Scar
        "2791",  -- Storm Cliffs
        "2804",  -- The Crystal Vale
        "2806",  -- Shadow Hold
        "2807",  -- Burning of Andorhal
        "2817",  -- Starfall Barrow Den
        "2832",  -- Nightmare Grove
        "2853",  -- Deadwind Pass
        "2856",  -- Scarlet Enclave
        "2875",  -- Karazhan Crypts
        "2902",  -- The Scarab Dais
        "2921",  -- Naxxramas
    },
};
