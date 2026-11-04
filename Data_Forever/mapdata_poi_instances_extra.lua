-- HAND-KEPT, not generated. Loaded right after mapdata_poi_instances.lua (which
-- copy_poi_instances.js rewrites wholesale from Vanilla's table and so knows
-- nothing of the dungeons that exist only in Forever): their entrance markers,
-- found in game, appended to Twm_instances. Same entry shapes as there:
--   continent:     {"Dungeon", MapID, "Name", x, y, "<instance key>", arrivalX, arrivalY}
--   instance map:  {"Exit", contMapID, "<continent name>", x, y, "<continent key>", arrivalX, arrivalY}
-- x, y are Big coordinates (x = the game's Y, y = the game's X). The exit marker
-- inside each instance sits where one arrives on entering (the portals are close
-- to it), and its arrival point is the entrance outside.

local function add(map, entry)
    Twm_instances[map] = Twm_instances[map] or {};
    tinsert(Twm_instances[map], entry);
end

-- The Hall of Thanes (Ironforge): outside X -4822 Y -933 Z 401, inside X -102 Y 0 Z 514
add("Azeroth", {"Dungeon", 3065, "The Hall of Thanes", -933.00, -4822.00, "3065", 0.00, -102.00});
add("3065", {"Exit", 0, "Eastern Kingdoms", 0.00, -102.00, "Azeroth", -933.00, -4822.00});

-- Excavation Site: Wetlands: outside and inside X -3703 Y -2371 Z 170
add("Azeroth", {"Dungeon", 2998, "Excavation Site: Wetlands", -2371.00, -3703.00, "2998", -2371.00, -3703.00});
add("2998", {"Exit", 0, "Eastern Kingdoms", -2371.00, -3703.00, "Azeroth", -2371.00, -3703.00});

-- Ruins of Lordaeron: outside X 1805 Y 175 Z 73, inside X 1805 Y 155 Z 73
add("Azeroth", {"Dungeon", 2999, "Ruins of Lordaeron", 175.00, 1805.00, "2999", 155.00, 1805.00});
add("2999", {"Exit", 0, "Eastern Kingdoms", 155.00, 1805.00, "Azeroth", 175.00, 1805.00});

-- City of Dalaran: outside and inside X 377 Y 524 Z 45
add("Azeroth", {"Dungeon", 2959, "City of Dalaran", 524.00, 377.00, "2959", 524.00, 377.00});
add("2959", {"Exit", 0, "Eastern Kingdoms", 524.00, 377.00, "Azeroth", 524.00, 377.00});
