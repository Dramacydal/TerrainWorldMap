-- HAND-KEPT, not generated: the Tile toggle and Tile move lists of the debug window
-- ("Export" tab), pasted here whole. Twm_TileToggle: WMO tiles (FileDataIDs) that are never
-- drawn, per WMO group (<WMOID>-<GroupNum>), on the given maps. Twm_TileMove: the tiles put
-- in another place, per map and group, {FileDataID, center x, center y [, yaw]} (Big
-- coordinates, the final center, the yaw in degrees as the data's own, only when the tile
-- was turned; just {FileDataID} for a tile listed but not placed yet). When
-- Twm_TileToggleVersion is not the saved TWMOption.TileToggleVersion, both saved lists are
-- replaced by these.
Twm_TileToggleVersion = "2026-10-23 00:25";
Twm_TileToggle = {
    {group = "648-0", name = "mountaincave01", maps = {"Kalimdor"}, tiles = {215181, 2257173, 2257170, 2257175}},
    {group = "648-1", name = "mountaincave03", maps = {"Kalimdor"}, tiles = {215185, 2257188, 2257185, 2257193}},
    {group = "648-2", name = "mountaincave04", maps = {"Kalimdor"}, tiles = {215189, 2257201, 2257199, 2257208}},
    {group = "648-3", name = "mountaincave06", maps = {"Kalimdor"}, tiles = {215193, 2257218, 2257214, 2257221}},
    {group = "648-4", name = "mountaincave07", maps = {"Kalimdor"}, tiles = {215197, 2257234, 2257231, 2257241}},
    {group = "648-5", name = "mountaincave08", maps = {"Kalimdor"}, tiles = {215201, 2257252, 2257249, 2257255}},
    {group = "648-6", name = "mountaincave09", maps = {"Kalimdor"}, tiles = {215205, 2257266, 2257262, 2257272}},
    {group = "648-7", name = "mountaincave10", maps = {"Kalimdor"}, tiles = {215209, 2257285, 2257281, 2257288}},
    {group = "648-8", name = "mountaincave11b", maps = {"Kalimdor"}, tiles = {215213}},
    {group = "648-9", name = "mountaincave11a", maps = {"Kalimdor"}, tiles = {215214}},
    {group = "648-10", name = "mountaincave05", maps = {"Kalimdor"}, tiles = {215215, 2257309, 2257303, 2257314}},
    {group = "648-11", name = "mountaincave02", maps = {"Kalimdor"}, tiles = {215219, 2257326, 2257320, 2257329}},
    {group = "653-1", name = "int", maps = {"2784", "Kalimdor"}, tiles = {216940}},
    {group = "3113-1", name = "IntHouseGBottom01", maps = {"Kalimdor"}, tiles = {216996}},
    {group = "3634-83", name = "FacadeHighborn", maps = {"DireMaul"}, tiles = {212809, 212813, 212817, 2256218, 2256238, 2256261, 212810, 212814, 212818, 2256223, 2256244, 2256268, 212811, 212815, 212819, 2256230, 2256249, 2256272, 2256183, 2256196, 2256211, 2256234, 2256253, 2256276}},
    {group = "3634-99", name = "TreeTower", maps = {"DireMaul"}, tiles = {212855, 212862, 212869, 212876, 212883, 212890, 212856, 212863, 212870, 212877, 212884, 212891, 212857, 212864, 212871, 212878, 212885, 212892, 212858, 212865, 212872, 212879, 212886, 212893, 212859, 212866, 212873, 212880, 212887, 212894, 212860, 212867, 212874, 212881, 212888, 212895, 212861, 212868, 212875, 212882, 212889, 212896}},
    {group = "3634-61", name = "FacadeSatyr", maps = {"DireMaul"}, tiles = {212732, 2255886, 2255913, 2255936, 2255958, 2255980, 2255868, 2255889, 2255917, 2255941, 2255963, 2255987, 2255872, 2255894, 2255921, 2255947, 2255967, 2255995, 2255876, 2255899, 2255925, 2255951, 2255970, 2256000, 2255880, 2255905, 2255930, 2255954, 2255974, 2256003}},
    {group = "121-1", name = "entrance", maps = {"2807", "2832", "2856", "2921", "CavernsOfTime", "Shadowfang", "Stratholme Raid"}, tiles = {209922}},
    {group = "121-2", name = "upstairs", maps = {"2807", "2832", "2856", "2921", "CavernsOfTime", "Shadowfang", "Stratholme Raid"}, tiles = {209923}},
    {group = "121-3", name = "upperback", maps = {"2807", "2832", "2856", "2921", "CavernsOfTime", "Shadowfang", "Stratholme Raid"}, tiles = {209924}},
    {group = "121-4", name = "lowerback", maps = {"2807", "2832", "2856", "2921", "CavernsOfTime", "Shadowfang", "Stratholme Raid"}, tiles = {209925}},
    {group = "121-5", name = "livingroom", maps = {"2807", "2832", "2856", "2921", "CavernsOfTime", "Shadowfang", "Stratholme Raid"}, tiles = {209926}},
    {group = "122-1", name = "interior", maps = {"2807", "2832", "2853", "2856", "2875", "2921", "CavernsOfTime", "Shadowfang", "Stratholme", "Stratholme Raid"}, tiles = {209921}},
    {group = "123-1", name = "hall", maps = {"2807", "2832", "2856", "2921", "CavernsOfTime", "Stratholme Raid"}, tiles = {209937}},
    {group = "123-2", name = "entry", maps = {"2807", "2832", "2856", "2921", "CavernsOfTime", "Stratholme Raid"}, tiles = {209938}},
    {group = "123-3", name = "kitchen", maps = {"2807", "2832", "2856", "2921", "CavernsOfTime", "Stratholme Raid"}, tiles = {209939}},
    {group = "123-4", name = "room03", maps = {"2807", "2832", "2856", "2921", "CavernsOfTime", "Stratholme Raid"}, tiles = {209940}},
    {group = "123-5", name = "room04", maps = {"2807", "2832", "2856", "2921", "CavernsOfTime", "Stratholme Raid"}, tiles = {209941}},
    {group = "123-6", name = "cellar", maps = {"2807", "2832", "2856", "2921", "CavernsOfTime", "Stratholme Raid"}, tiles = {209942}},
    {group = "123-7", name = "room02", maps = {"2807", "2832", "2856", "2921", "CavernsOfTime", "Stratholme Raid"}, tiles = {209943}},
    {group = "123-8", name = "room01", maps = {"2807", "2832", "2856", "2921", "CavernsOfTime", "Stratholme Raid"}, tiles = {209944}},
    {group = "123-9", name = "upstairs", maps = {"2807", "2832", "2856", "2921", "CavernsOfTime", "Stratholme Raid"}, tiles = {209945}},
    {group = "123-10", name = "commonroom", maps = {"2807", "2832", "2856", "2921", "CavernsOfTime", "Stratholme Raid"}, tiles = {209946}},
    {group = "925-2", name = "hall01", maps = {"2856", "2921", "Stratholme", "Stratholme Raid"}, tiles = {217562}},
    {group = "925-3", name = "hall02", maps = {"2856", "2921", "Stratholme", "Stratholme Raid"}, tiles = {217563}},
    {group = "925-4", name = "assemblyroom", maps = {"2856", "2921", "Stratholme", "Stratholme Raid"}, tiles = {217564}},
    {group = "925-5", name = "meatlocker", maps = {"2856", "2921", "Stratholme", "Stratholme Raid"}, tiles = {217565}},
    {group = "925-6", name = "lab01", maps = {"2856", "2921", "Stratholme", "Stratholme Raid"}, tiles = {217566}},
    {group = "925-7", name = "spiral_left", maps = {"2856", "2921", "Stratholme", "Stratholme Raid"}, tiles = {217567}},
    {group = "925-8", name = "spiral_right", maps = {"2856", "2921", "Stratholme", "Stratholme Raid"}, tiles = {217568}},
    {group = "925-9", name = "meatlocker01", maps = {"2856", "2921", "Stratholme", "Stratholme Raid"}, tiles = {217569}},
    {group = "925-10", name = "meatlocker03", maps = {"2856", "2921", "Stratholme", "Stratholme Raid"}, tiles = {217570}},
    {group = "925-11", name = "meatlocker04", maps = {"2856", "2921", "Stratholme", "Stratholme Raid"}, tiles = {217571}},
    {group = "1078-1", name = "interior", maps = {"2856", "2921", "Stratholme", "Stratholme Raid"}, tiles = {217580, 2253720}},
    {group = "3453-0", name = "King's Square", maps = {"2856", "2921", "Stratholme Raid"}, tiles = {2252349, 2252354, 2252351, 2252357}},
    {group = "3453-2", name = "city01", maps = {"2856", "2921", "Stratholme Raid"}, tiles = {213992}},
    {group = "3453-3", name = "entrance01", maps = {"2856", "2921", "Stratholme Raid"}, tiles = {213993}},
    {group = "3453-4", name = "King's Square", maps = {"2856", "2921", "Stratholme Raid"}, tiles = {2252367, 2252372, 2252370, 2252377}},
    {group = "3455-0", name = "tunnel_elbow03", maps = {"2856", "2921", "Stratholme Raid"}, tiles = {214106}},
    {group = "3455-1", name = "tunnelA01A09", maps = {"2856", "2921", "Stratholme Raid"}, tiles = {214107}},
    {group = "3455-2", name = "tunnel_elbow04", maps = {"2856", "2921", "Stratholme Raid"}, tiles = {214108}},
    {group = "3455-3", name = "tunnelA01A10", maps = {"2856", "2921", "Stratholme Raid"}, tiles = {214109}},
    {group = "3455-4", name = "tunnelA01A08", maps = {"2856", "2921", "Stratholme Raid"}, tiles = {214110}},
    {group = "3455-6", name = "tunnelA01A11", maps = {"2856", "2921", "Stratholme Raid"}, tiles = {214111}},
    {group = "961-0", name = "int01", maps = {"2853", "2856", "2875", "2921", "CavernsOfTime", "Stratholme Raid"}, tiles = {209852}},
};
Twm_TileMove = {
};
