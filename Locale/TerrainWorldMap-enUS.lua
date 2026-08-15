local _;

-- metadata magic
TWM_TITLE = C_AddOns.GetAddOnMetadata("TerrainWorldMap", "Title") or "Y";
TWM_VERSION = C_AddOns.GetAddOnMetadata("TerrainWorldMap","Version") or "???";

-- localize from this point on as needed
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
TWM_OPTIONS_WORLDMAP_TITLE = "World Map Options";
TWM_OPTIONS_BROWSER_TITLE = "Browser Options";
TWM_OPTIONS_TAB_WORLDMAP = "World Map";
TWM_OPTIONS_TAB_BROWSER = "Browser";
TWM_OPTIONS_ENABLEBUTTON = "Enable Minimap Button";
TWM_OPTIONS_TRACKONSHOW = "Zoom to Player on Show";
TWM_OPTIONS_ALPHA = "Transparency";
TWM_OPTIONS_ICONSIZE = "Icon Size";
TWM_OPTIONS_RESETPOSITION = "Reset Position";

TWM_OPTIONS_TILEFILTER = "Tile Filtering";
TWM_OPTIONS_TILEFILTER_LINEAR = "Smooth (Linear)";
TWM_OPTIONS_TILEFILTER_LINEAR_DESC = "Blends neighboring pixels together. The game's default filtering - slightly blurs the terrain, especially when zoomed in.";
TWM_OPTIONS_TILEFILTER_TRILINEAR = "Smooth + Mipmaps (Trilinear)";
TWM_OPTIONS_TILEFILTER_TRILINEAR_DESC = "Same blending as Smooth, plus mipmap sampling for cleaner results when zoomed out.";
TWM_OPTIONS_TILEFILTER_NEAREST = "Sharp (Nearest)";
TWM_OPTIONS_TILEFILTER_NEAREST_DESC = "No blending - keeps terrain edges crisp, but shows visible pixelation when zoomed in far.";

TWM_TOOLTIP_OPT_ENABLEBUTTON = "Shows a draggable TerrainWorldMap icon on the minimap. Left-click opens the window, right-click opens a quick-access menu.";
TWM_TOOLTIP_OPT_DRAWUNDERWATER = "Draws the submerged version of coastal terrain tiles (e.g. Vashj'ir, Pandaria's flooded coastline) instead of the dry-land art underneath. Only available where this client's data includes underwater tile variants.";
TWM_TOOLTIP_OPT_CHILDMAPTILES = "Also draws any zone that Blizzard's map hierarchy nominally files under one continent, even though its real terrain lives on a different one - for example, the Draenei starting zones (Azuremyst Isle, Bloodmyst Isle) show up here under Kalimdor, and the Blood Elf starting zones (Eversong Woods, Ghostlands, Isle of Quel'Danas) under Eastern Kingdoms. Note: overlapping zone tiles can occur due to how their coordinates work, which is why this is made an optional toggle.";
TWM_TOOLTIP_OPT_WORLDVIEWTILES = "Overlays real terrain tiles on the zoomed-out continent/world view of the World Map. This can cause some stuttering while viewing that map, which is why it's made optional.";
TWM_TOOLTIP_OPT_CITYMAPTILES = "Overlays real terrain tiles on city maps (e.g. Stormwind, Orgrimmar) opened from the World Map. Turn this off if you'd rather see the original city map artwork - for example, the real terrain doesn't suit Undercity well.";
TWM_TOOLTIP_OPT_TRACKONSHOW = "Automatically centers and zooms the TerrainWorldMap window on your current position every time it's opened.";
TWM_TOOLTIP_OPT_SHOWLANDMARKS = "Toggles sub-zone markers - inns, caves, lakes, and similar points of interest - shown on the map.";
TWM_TOOLTIP_OPT_SHOWGRAVEYARDS = "Toggles graveyard markers on the map.";
TWM_TOOLTIP_OPT_SHOWCAPITALS = "Toggles capital city markers on the map.";
TWM_TOOLTIP_OPT_SHOWDUNGEONS = "Toggles dungeon and raid entrance markers on the map.";
TWM_TOOLTIP_OPT_ALPHA = "Sets the opacity of the TerrainWorldMap window.";
TWM_TOOLTIP_OPT_ICONSIZE = "Scales the size of all point markers shown on the map.";
TWM_TOOLTIP_OPT_RESETPOSITION = "Moves the TerrainWorldMap window back to its default position and size on screen. Useful if something went wrong with the window (e.g. it became stuck off-screen or unusably sized).";

TWM_POINTS_SHOWPOINTS_TITLE = "Show Points";
TWM_POINTS_LANDMARKS = "Landmarks";
TWM_POINTS_GRAVEYARDS = "Graveyards";
TWM_POINTS_CAPITALS = "Capitals";
TWM_POINTS_DUNGEONS = "Dungeons";

TWM_OPTIONS_SHOW_LANDMARKS = "Show Landmarks";
TWM_OPTIONS_SHOW_GRAVEYARDS = "Show Graveyards";
TWM_OPTIONS_SHOW_CAPITALS = "Show Capitals";
TWM_OPTIONS_SHOW_DUNGEONS = "Show Dungeons";


TWM_ZOOMIN =     "+";
TWM_ZOOMOUT =     "-";

BINDING_NAME_TWM_TOGGLE = "Toggle TerrainWorldMap Frame";
BINDING_HEADER_TWM = TWM_TITLE;

