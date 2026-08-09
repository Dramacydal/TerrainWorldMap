local _;

-- metadata magic
YATLAS_TITLE = C_AddOns.GetAddOnMetadata("Yatlas", "Title") or "Y";
YATLAS_VERSION = C_AddOns.GetAddOnMetadata("Yatlas","Version") or "???";
_,_,YATLAS_RELEASE_DATE = string.find(C_AddOns.GetAddOnMetadata("Yatlas","X-LastChangedDate") or "", "[(](.+)[)]");

YATLAS_WEBSITE = ""
YATLAS_AUTHOR = "Boo Diddly";
YATLAS_AUTHOR_EMAIL = "";

-- localize from this point on as needed
YATLAS_HELP_TEXT = {
    "Yatlas provides a minimap-based map of the world (reasonably high "..
        "detail).\n\n"..
    "To move your view around click and drag on the map itself. You can "..
        "choose which map (currently only Kalimdor and the Eastern "..
        "Kingdoms) at the top. You can jump around by zone and zoom to "..
        "player as well.\n\n"..
    "Mousing over a point of interest will bring up a tooltip.\n"
    };

YATLAS_TAB_DATA = "Show Data";
YATLAS_TAB_OPTIONS = "Options";

YATLAS_BUTTON_TOOLTIP1 = "Yatlas";
YATLAS_PLAYERJUMP = "Goto Player";
YATLAS_OPTIONSBUTTON = "Options";

-- Minimap/world-map button tooltips and right-click context menu
YATLAS_TOOLTIP_LEFTCLICK_OPEN = "|cff40ff40Left-click|r: open Yatlas";
YATLAS_TOOLTIP_LEFTCLICK_OVERLAY_ON = "|cff40ff40Left-click|r: enable baked map overlay";
YATLAS_TOOLTIP_LEFTCLICK_OVERLAY_OFF = "|cff40ff40Left-click|r: disable baked map overlay";
YATLAS_TOOLTIP_RIGHTCLICK_MENU = "|cff40ff40Right-click|r: menu";
YATLAS_MENU_OPEN = "Open Yatlas";
YATLAS_MENU_CHILDMAP_TILES = "Draw child-map tiles";
YATLAS_MENU_WORLDVIEW_TILES = "Draw tiles on Azeroth (world) map";
YATLAS_WORLDMAP_OVERLAY_ON = "Yatlas: world map overlay ON";
YATLAS_WORLDMAP_OVERLAY_OFF = "Yatlas: world map overlay OFF";
YATLAS_DEBUG_TILES_ON = "Yatlas: tile debug labels ON";
YATLAS_DEBUG_TILES_OFF = "Yatlas: tile debug labels OFF";

YATLAS_OPTIONS_TITLE = "Yatlas Options";
YATLAS_OPTIONS_BUTTONPOS = "Minimap Button Position";
YATLAS_OPTIONS_BUTTONPOS_TIP = "%d degrees";
YATLAS_OPTIONS_ENABLEBUTTON = "Enable Minimap Button";
YATLAS_OPTIONS_TRACKONSHOW = "Zoom to Player on Show";
YATLAS_OPTIONS_ALPHA = "Transparency";
YATLAS_OPTIONS_ICONSIZE = "Icon Size";
YATLAS_OPTIONS_ENABLECOORD = "Enable Cursor Coordinates";

YATLAS_POINTS_SHOWPOINTS_TITLE = "Show Points";
YATLAS_POINTS_LANDMARKS = "Landmarks";

YATLAS_UNKNOWN_ZONE = "Unknown";

YATLAS_BIGDRAGMESSAGE = "Click on map and drag to move view."
YATLAS_ZOOMIN =     "+";
YATLAS_ZOOMOUT =     "-";

BINDING_NAME_YATLAS_TOGGLE = "Toggle Yatlas Frame";
BINDING_NAME_YATLAS_BIG_TOGGLE = "Toggle Fullscreen Yatlas Frame";
BINDING_HEADER_YATLAS = YATLAS_TITLE;

