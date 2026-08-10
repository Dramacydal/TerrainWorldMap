local _;

-- metadata magic
YATLAS_TITLE = C_AddOns.GetAddOnMetadata("TerrainWorldMap", "Title") or "Y";
YATLAS_VERSION = C_AddOns.GetAddOnMetadata("TerrainWorldMap","Version") or "???";
_,_,YATLAS_RELEASE_DATE = string.find(C_AddOns.GetAddOnMetadata("TerrainWorldMap","X-LastChangedDate") or "", "[(](.+)[)]");

YATLAS_WEBSITE = "https://github.com/Dramacydal/Yatlas"
YATLAS_AUTHOR = "Boo Diddly, Dramacydal";
YATLAS_AUTHOR_EMAIL = "PulLumBerMal@gmail.com";

-- localize from this point on as needed
YATLAS_HELP_TEXT = {
    "TerrainWorldMap provides a minimap-based map of the world (reasonably high "..
        "detail).\n\n"..
    "To move your view around click and drag on the map itself. You can "..
        "choose which map (currently Kalimdor, the Eastern Kingdoms, and "..
        "Outland) at the top. You can jump around by zone and zoom to "..
        "player as well.\n\n"..
    "Mousing over a point of interest will bring up a tooltip.\n"
    };

YATLAS_BUTTON_TOOLTIP1 = "TerrainWorldMap";
YATLAS_PLAYERJUMP = "Goto Player";
YATLAS_OPTIONSBUTTON = "Options";

-- Minimap/world-map button tooltips and right-click context menu
YATLAS_TOOLTIP_LEFTCLICK_OPEN = "|cff40ff40Left-click|r: open TerrainWorldMap";
YATLAS_TOOLTIP_LEFTCLICK_OVERLAY_ON = "|cff40ff40Left-click|r: enable baked map overlay";
YATLAS_TOOLTIP_LEFTCLICK_OVERLAY_OFF = "|cff40ff40Left-click|r: disable baked map overlay";
YATLAS_TOOLTIP_RIGHTCLICK_MENU = "|cff40ff40Right-click|r: menu";
YATLAS_MENU_OPEN = "Open TerrainWorldMap";
YATLAS_MENU_SETTINGS = "Settings";
YATLAS_MENU_CHILDMAP_TILES = "Draw child-map tiles";
YATLAS_MENU_WORLDVIEW_TILES = "Draw tiles on Azeroth (world) map";
YATLAS_MENU_CITYMAP_TILES = "Draw tiles on city maps";
YATLAS_WORLDMAP_OVERLAY_ON = "TerrainWorldMap: world map overlay ON";
YATLAS_WORLDMAP_OVERLAY_OFF = "TerrainWorldMap: world map overlay OFF";
YATLAS_DEBUG_TILES_ON = "TerrainWorldMap: tile debug labels ON";
YATLAS_DEBUG_TILES_OFF = "TerrainWorldMap: tile debug labels OFF";

YATLAS_OPTIONS_TITLE = "TerrainWorldMap Options";
YATLAS_OPTIONS_TAB_WORLDMAP = "World Map";
YATLAS_OPTIONS_TAB_BROWSER = "Browser";
YATLAS_OPTIONS_ENABLEBUTTON = "Enable Minimap Button";
YATLAS_OPTIONS_TRACKONSHOW = "Zoom to Player on Show";
YATLAS_OPTIONS_ALPHA = "Transparency";
YATLAS_OPTIONS_ICONSIZE = "Icon Size";
YATLAS_OPTIONS_RESETPOSITION = "Reset Position";

YATLAS_POINTS_SHOWPOINTS_TITLE = "Show Points";
YATLAS_POINTS_LANDMARKS = "Landmarks";

YATLAS_UNKNOWN_ZONE = "Unknown";

YATLAS_ZOOMIN =     "+";
YATLAS_ZOOMOUT =     "-";

BINDING_NAME_YATLAS_TOGGLE = "Toggle TerrainWorldMap Frame";
BINDING_HEADER_YATLAS = YATLAS_TITLE;

