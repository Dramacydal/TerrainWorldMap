
if (GetLocale() == "deDE") then

-- Deutsche
--            lower      upper
-- a umlaut   \195\164   \195\132
-- o umlaut   \195\192   \195\150
-- u umlaut   \195\188   \195\156
-- "          \"
-- '          \'

TWM_BUTTON_TOOLTIP1 = "TerrainWorldMap";
TWM_PLAYERJUMP = "Spielerposition";
TWM_OPTIONSBUTTON = "Optionen";

-- Minimap-/Weltkarten-Button: Tooltips und Rechtsklick-Kontextmen\195\188
TWM_TOOLTIP_LEFTCLICK_OPEN = "|cff40ff40Linksklick|r: TerrainWorldMap \195\182ffnen";
TWM_TOOLTIP_LEFTCLICK_OVERLAY_ON = "|cff40ff40Linksklick|r: gebackenes Karten-Overlay aktivieren";
TWM_TOOLTIP_LEFTCLICK_OVERLAY_OFF = "|cff40ff40Linksklick|r: gebackenes Karten-Overlay deaktivieren";
TWM_TOOLTIP_RIGHTCLICK_MENU = "|cff40ff40Rechtsklick|r: Men\195\188";
TWM_MENU_OPEN = "TerrainWorldMap \195\182ffnen";
TWM_MENU_SETTINGS = "Einstellungen";
TWM_MENU_CHILDMAP_TILES = "Kindkarten-Kacheln zeichnen";
TWM_MENU_WORLDVIEW_TILES = "Kacheln auf der Azeroth-Weltkarte zeichnen";
TWM_MENU_CITYMAP_TILES = "Kacheln auf Stadtkarten zeichnen";
TWM_MENU_DRAW_UNDERWATER = "Gelände unter Wasser anzeigen";
TWM_WORLDMAP_OVERLAY_ON = "TerrainWorldMap: Weltkarten-Overlay AN";
TWM_WORLDMAP_OVERLAY_OFF = "TerrainWorldMap: Weltkarten-Overlay AUS";
TWM_DEBUG_TILES_ON = "TerrainWorldMap: Kachel-Debug-Beschriftungen AN";
TWM_DEBUG_TILES_OFF = "TerrainWorldMap: Kachel-Debug-Beschriftungen AUS";

TWM_OPTIONS_TITLE = "TerrainWorldMap-Optionen";
TWM_OPTIONS_TAB_WORLDMAP = "Weltkarte";
TWM_OPTIONS_TAB_BROWSER = "Browser";
TWM_OPTIONS_ENABLEBUTTON = "Aktiviere Minimap-Icon";
TWM_OPTIONS_TRACKONSHOW = "Beim \195\150ffnen zum Spieler zoomen";
TWM_OPTIONS_ALPHA = "Transparenz";
TWM_OPTIONS_ICONSIZE = "Icon Gr\195\182\195\159e";
TWM_OPTIONS_RESETPOSITION = "Position zur\195\188cksetzen";

TWM_POINTS_SHOWPOINTS_TITLE = "Zeige Punkte";
-- Landmarks would tranlsate to "Landmarken", "wichtige Orte" would be translated to English: "important places"
-- I would prefer "wichtige Orte" over "Landmarken"
TWM_POINTS_LANDMARKS = "wichtige Orte";
TWM_POINTS_GRAVEYARDS = "Friedh\195\182fe";
TWM_POINTS_CAPITALS = "Hauptst\195\164dte";
TWM_POINTS_DUNGEONS = "Dungeons";

TWM_OPTIONS_SHOW_LANDMARKS = "Zeige wichtige Orte";
TWM_OPTIONS_SHOW_GRAVEYARDS = "Zeige Friedh\195\182fe";
TWM_OPTIONS_SHOW_CAPITALS = "Zeige Hauptst\195\164dte";
TWM_OPTIONS_SHOW_DUNGEONS = "Zeige Dungeons";



BINDING_NAME_TWM_TOGGLE = "Ein- und Ausblenden des TerrainWorldMap-Fensters";
BINDING_HEADER_TWM = TWM_TITLE;

end

