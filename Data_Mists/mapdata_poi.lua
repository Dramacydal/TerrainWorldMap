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

-- TODO: no Northrend/Outland/Pandaria towns hand-collected yet, and
-- Kalimdor/Azeroth's Cataclysm-revamped zones (Southern Barrens, Uldum,
-- Twilight Highlands, Vashj'ir) aren't covered by this reused-from-TBC list.
Twm_towns2 = {
    ["Kalimdor"] = {
        -- Ashenvale --
        {"Maestra's Post",          154, 3240},
        {"The Talondeep Path",          -718, 1913},
        {"Raynewood Retreat",       -1881, 2707},
        {"Satyrnaar",               -2981.2, 2694},
        {"Warsong Lumber Camp",     -3545.8, 2438},
        {"Zoram'Gar Outpost",       1012.5, 3353},
        -- Azshara --
        {"Valormok",                -4400, 3600},
        {"Talrendis Point",         -3975, 2693},
        {"Ruins of Eldarath",       -5150, 3542},
        -- Darkshore --
        {"Ruins of Mathystra",      -845, 7368},
        {"Bashal'Aran",             -22.9, 6695},
        {"Ameth'Aran",              200, 5702},
        {"Grove of the Ancients",   102, 4993},
        -- Desolace --
        {"Sargeron",                762, -230},
        {"Thunder Axe Fortress",    1762, -346},
        {"Kodo Graveyard",          1929, -1303},
        {"Ghostwalker Post",        1752,  -1238},
        {"Mannoroc Coven",          1902, -1905},
        {"Valley of Spears",        2793, -1273},
        {"Gelkis Village",          2558, -2184},
        {"Magram Village",          1045, -1807},
        {"Kolkar Village",          954, -948},
        -- Durotar --
        {"Razor Hill",              -4741.6, 309},
        {"The Den",                 -4218, -609},
        {"Sen'jin Village",         -4912, -823},
        -- Duskwallow --
        {"Brackenwall Village",     -2877, -3122},
        {"Stonemaul Ruins",         -3295, -4329},
        -- Felwood --
        {"Felpaw Village",          -1935, 6785},
        {"Jaedenar",                -551, 4329},
        {"Emerald Sanctuary",       -1310, 4008},
        {"Talonbranch Glade",       -1935, 6173},
        -- Feralas --
        {"Ruins of Isildien",       1376, -5686},
        {"Gordunni Outpost",        155, -3730},
        {"Grimtotem Compound",      824, -4507},
        -- Moonglade --
        {"Nighthaven",              -2497, 7890},
        {"Stormrage Barrow Dens",   -2947, 7565},
        {"Shrine of Remulos",       -2214, 7846},
        -- Mulgore --
        {"Red Rocks",               -1137.5, -935},
        {"Bloodhoof Village",       -381.2, -2318},
        {"Brambleblade Ravine",     -1181, -3000},
        {"Camp Narache",            -254, -2904},
        -- Silithus --
        {"Staghelm Point",          100, -6548},
        {"Valor's Rest",            -304, -6430},
        {"Southwind Village",       364, -7196},
        {"Bronzebeard Encampment",  1122, -8036},
        -- Stonetalon Mountains --
        {"Malaka'jin",              -327, -196},
        {"The Talon Den",           1814, 2409},
        {"The Talondeep Path",      -579, 1544},
        -- Tanaris --
        {"Steamwheedle Port",       -4864, -6937},
        {"Uldum",                   -2785, -9656},
        {"Dunemaul Compound",       -3050, -8435},
        {"Sandsorrow Warch",        -2952, -7162},
        -- Teldrassil --
        {"Aldrassil",               818, 10480},
        {"The Oracle Glade",        1918, 10684},
        {"Dolanaar",                968, 9846},
        {"Starbreeze Village",      420, 9871},
        {"Rut'Theran Village",      991, 8709},
        -- The Barrens --
        {"The Sludge Fen",          -3079, 1044},
        {"Northwatch Hold",         -3641, -2098},
        -- Thousand Needles --
        {"The Great Lift",          -1849, -4662},
        {"Mirage Raceway",          -3914, -6220},
        {"Roguefeather Den",        -1614, -5487},
        {"The Weathered Nook",      -2797, -5208},
        {"Ironstone Camp",          -3422, -5825},
        {"Whitereach Post",         -1366, -4918},
        {"Darkcloud Pinnacle",      -1931, -5087},
        -- Un'goro Crater --
        {"Marshal's Refuge",        -1087, -6165},
        {"Fungal Rock",             -1856, -6382},
        -- Winterspring --
        {"Owl Wing Thicket",        -4958, 5652},
        {"The Hidden Grove",        -4842, 7733},
        {"Starfall Village",        -3931, 7147},
        {"Winterfall Village",      -5129, 6764},
    },
    ["Azeroth"] = {
        -- Alterac --
        {"Strahnbrad",              -956, 679},
        {"Ruins of Alterac",        -310, 539},
        {"Dalaran",                 364, 266},
        {"Lordamere Internment Camp", 226, -95},
        -- Arathi Highlands --
        {"The Tower of Arathor",    -1500, -1777},
        {"Stromgarde",              -1800, -1631},
        {"Witherbark Village",      -3398, -1741},
        {"Faldir's Cove",           -2112, -2079},
        {"Refuge Pointe",           -2416, -1373},
        -- Badlands --
        {"Angor Fortress",          -3137, -6375},
        {"Dustbelch Grotto",        -2289, -7275},
        -- Blasted Lands --
        {"Nethergarde Keep",        -3431, -10991},
        {"The Dark Portal",         -3193, -11829},
        {"Dreadmaul Hold",          -2664, -108524},
        -- Burning Steppes --
        {"Flame Crest",             -2193, -7480},
        {"Blackrock Stronghold",    -1439, -7701},
        -- Deadwind Pass --
        -- Dun Morogh --
        {"Anvilmar",                387, -6102},
        {"Kharanos",                -500, -5583},
        {"Brewnall Village",        302, -5360},
        -- Duskwood --
        {"Ravenhill",               327, -10735},
        -- Eastern Plaguelands --
        {"Terrorweb Tunnel",        -2772, 3034},
        {"Terrorweb Tunnel",        -2470, 2751},
        {"Light's Hope Chapel",     -5339, 2298},
        {"Tyr's Hand",              -5558, 1596},
        {"Darrowshire",             -3695, 1438},
        {"Corin's Crossing",        -4505, 2032},
        -- Elwynn Forest --
        {"Northshire Abbey",        -172, -8878},
        {"Eastvale Logging Camp",   -1352, -9460},
        {"Goldshire",               68, -9458},
        {"Westbrook Garrison",      677, -9624},
        -- Hillsbrad Foothills
        {"Azurlode Mine",           196, -827},
        {"Durnholde Keep",          -1457, -456},
        {"Dun Garok",               -1218, -1292},
        {"Purgation Isle",          590, -1333},
        -- Loch Modan --
        {"The Farstrider Lodge",    -4270, -5655},
        -- Red Ridge Mountains --
        {"Tower of Ilgalar",        -3297, -9280},
        {"Stonewatch Keep",         -3052, -9380},
        -- Searing Gorge --
        {"Thorium Point",           -1153, -6504},
        -- Silverpine Forest --
        {"Ambermill",               791, -122},
        {"Pyrewood Village",        1556, -385},
        -- Strangethorn Vale --
        {"Mosh'Ogg Ogre Mound",     -1006, -12368},
        {"Venture Co. Base Camp",   -523, -11972},
        {"Gurubashi Arena",         278, -13204},
        -- Swamp of Sorrows --
        {"Fallow Sanctuary",        -3641, -9954},
        {"Misty Valley",            -2526, -10164},
        {"Stagalbog Cave",          -3745, -10795},
        -- The Hinterlands --
        {"Skulk Rock",              -3795, 393},
        {"Quel'Danil Lodge",        -2764, 239},
        {"The Altar of Zul",        -3454, -293},
        {"Jintha'Alor",             -3955, -468},
        -- Tirisfal Glades --
        {"Agamand Mills",           871, 2839},
        {"Deathknell",              1580, 1929},
        {"Brill",                   286, 2304},
        -- Western Plaguelands --
        {"Hearthglen",              1516, 2877},
        {"Ruins of Andorhal",       -1518,1383},
        {"Caer Darrow",             -2558, 1156},
        {"The Bulwark",             -762, 1745},
        {"Chillwind Camp",          -1441, 925},
        -- Westfall --
        {"Jangolode Mine",          1453, -9968},
        {"Gold Coast Quarry",       1915, -10416},
        {"Moonbrook",               1501, -11010},
        -- Wetlands --
        {"Dun Modr",                -2327, -2610},
        {"Dun Algaz",               -2369, -4198},
        {"Grim Batol",              -3429, -4006},
    }
}
