local _;

-- metadata magic
TWM_TITLE = C_AddOns.GetAddOnMetadata("TerrainWorldMap", "Title") or "Y";
TWM_VERSION = C_AddOns.GetAddOnMetadata("TerrainWorldMap","Version") or "???";
_,_,TWM_RELEASE_DATE = string.find(C_AddOns.GetAddOnMetadata("TerrainWorldMap","X-LastChangedDate") or "", "[(](.+)[)]");

TWM_WEBSITE = "https://github.com/Dramacydal/TerrainWorldMap"
TWM_AUTHOR = "Boo Diddly, Dramacydal";
TWM_AUTHOR_EMAIL = "PulLumBerMal@gmail.com";

-- localize from this point on as needed
TWM_HELP_TEXT = {
    "TerrainWorldMap provides a minimap-based map of the world (reasonably high "..
        "detail).\n\n"..
    "To move your view around click and drag on the map itself. You can "..
        "choose which map (currently Kalimdor, the Eastern Kingdoms, and "..
        "Outland) at the top. You can jump around by zone and zoom to "..
        "player as well.\n\n"..
    "Mousing over a point of interest will bring up a tooltip.\n"
    };

TWM_BUTTON_TOOLTIP1 = "TerrainWorldMap";
TWM_PLAYERJUMP = "Goto Player";
TWM_OPTIONSBUTTON = "Options";

-- Minimap/world-map button tooltips and right-click context menu
TWM_TOOLTIP_LEFTCLICK_OPEN = "|cff40ff40Left-click|r: open TerrainWorldMap";
TWM_TOOLTIP_LEFTCLICK_OVERLAY_ON = "|cff40ff40Left-click|r: enable baked map overlay";
TWM_TOOLTIP_LEFTCLICK_OVERLAY_OFF = "|cff40ff40Left-click|r: disable baked map overlay";
TWM_TOOLTIP_RIGHTCLICK_MENU = "|cff40ff40Right-click|r: menu";
TWM_MENU_OPEN = "Open TerrainWorldMap";
TWM_MENU_SETTINGS = "Settings";
TWM_MENU_CHILDMAP_TILES = "Draw child-map tiles";
TWM_MENU_WORLDVIEW_TILES = "Draw tiles on Azeroth (world) map";
TWM_MENU_CITYMAP_TILES = "Draw tiles on city maps";
TWM_MENU_DRAW_UNDERWATER = "Show underwater terrain";
TWM_WORLDMAP_OVERLAY_ON = "TerrainWorldMap: world map overlay ON";
TWM_WORLDMAP_OVERLAY_OFF = "TerrainWorldMap: world map overlay OFF";
TWM_DEBUG_TILES_ON = "TerrainWorldMap: tile debug labels ON";
TWM_DEBUG_TILES_OFF = "TerrainWorldMap: tile debug labels OFF";

TWM_OPTIONS_TITLE = "TerrainWorldMap Options";
TWM_OPTIONS_TAB_WORLDMAP = "World Map";
TWM_OPTIONS_TAB_BROWSER = "Browser";
TWM_OPTIONS_ENABLEBUTTON = "Enable Minimap Button";
TWM_OPTIONS_TRACKONSHOW = "Zoom to Player on Show";
TWM_OPTIONS_ALPHA = "Transparency";
TWM_OPTIONS_ICONSIZE = "Icon Size";
TWM_OPTIONS_RESETPOSITION = "Reset Position";

TWM_POINTS_SHOWPOINTS_TITLE = "Show Points";
TWM_POINTS_LANDMARKS = "Landmarks";


TWM_ZOOMIN =     "+";
TWM_ZOOMOUT =     "-";

BINDING_NAME_TWM_TOGGLE = "Toggle TerrainWorldMap Frame";
BINDING_HEADER_TWM = TWM_TITLE;

