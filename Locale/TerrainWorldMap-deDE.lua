
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
TWM_OPTIONS_WORLDMAP_TITLE = "Weltkarten-Optionen";
TWM_OPTIONS_BROWSER_TITLE = "Browser-Optionen";
TWM_OPTIONS_TAB_WORLDMAP = "Weltkarte";
TWM_OPTIONS_TAB_BROWSER = "Browser";
TWM_OPTIONS_ENABLEBUTTON = "Aktiviere Minimap-Icon";
TWM_OPTIONS_TRACKONSHOW = "Beim \195\150ffnen zum Spieler zoomen";
TWM_OPTIONS_ALPHA = "Transparenz";
TWM_OPTIONS_ICONSIZE = "Icon Gr\195\182\195\159e";
TWM_OPTIONS_RESETPOSITION = "Position zur\195\188cksetzen";

TWM_OPTIONS_TILEFILTER = "Kachelfilterung";
TWM_OPTIONS_TILEFILTER_LINEAR = "Weich (Linear)";
TWM_OPTIONS_TILEFILTER_LINEAR_DESC = "Vermischt benachbarte Pixel. Die Standardfilterung des Spiels - verwischt das Gel\195\164nde leicht, besonders beim Heranzoomen.";
TWM_OPTIONS_TILEFILTER_TRILINEAR = "Weich + Mipmaps (Trilinear)";
TWM_OPTIONS_TILEFILTER_TRILINEAR_DESC = "Die gleiche Weichzeichnung wie bei \"Weich\", zus\195\164tzlich mit Mipmap-Sampling f\195\188r sauberere Ergebnisse beim Herauszoomen.";
TWM_OPTIONS_TILEFILTER_NEAREST = "Scharf (Nearest)";
TWM_OPTIONS_TILEFILTER_NEAREST_DESC = "Keine Weichzeichnung - h\195\164lt die Gel\195\164ndekanten scharf, zeigt aber sichtbare Pixelierung beim starken Heranzoomen.";

TWM_TOOLTIP_OPT_ENABLEBUTTON = "Zeigt ein verschiebbares TerrainWorldMap-Symbol auf der Minikarte. Linksklick \195\182ffnet das Fenster, Rechtsklick \195\182ffnet ein Schnellzugriffsmen\195\188.";
TWM_TOOLTIP_OPT_DRAWUNDERWATER = "Zeichnet die untergetauchte Variante k\195\188stennaher Gel\195\164ndekacheln (z. B. Vashj'ir, die \195\188berflutete K\195\188ste Pandarias) anstelle der Landvariante. Nur verf\195\188gbar, wenn die Daten dieses Clients Unterwasser-Kachelvarianten enthalten.";
TWM_TOOLTIP_OPT_CHILDMAPTILES = "Zeichnet zus\195\164tzlich jede Zone, die in Blizzards Kartenhierarchie zwar einem Kontinent zugeordnet ist, deren echtes Gel\195\164nde aber auf einem anderen liegt - z. B. erscheinen die Startgebiete der Draenei hier unter Kalimdor und die der Blutelfen unter den \195\150stlichen K\195\182nigreichen. Hinweis: Durch die Eigenheiten ihrer Koordinaten k\195\182nnen sich Zonenkacheln \195\188berlappen, weshalb diese Funktion optional ist.";
TWM_TOOLTIP_OPT_WORLDVIEWTILES = "Zeichnet echte Gel\195\164ndekacheln auf der herausgezoomten Kontinent-/Weltansicht der Weltkarte. Dies kann beim Betrachten dieser Karte zu Rucklern f\195\188hren, weshalb die Funktion optional ist.";
TWM_TOOLTIP_OPT_CITYMAPTILES = "Zeichnet echte Gel\195\164ndekacheln auf Stadtkarten (z. B. Sturmwind, Orgrimmar), die von der Weltkarte ge\195\182ffnet werden. Deaktiviere dies, wenn du lieber die originale Stadtkarten-Grafik sehen m\195\182chtest - f\195\188r Unterstadt z. B. passt das echte Gel\195\164nde nicht gut.";
TWM_TOOLTIP_OPT_TRACKONSHOW = "Zentriert und zoomt das TerrainWorldMap-Fenster bei jedem \195\150ffnen automatisch auf deine aktuelle Position.";
TWM_TOOLTIP_OPT_SHOWLANDMARKS = "Zeigt Unterzonen-Markierungen - Gasth\195\164user, H\195\182hlen, Seen und \195\164hnliche Orte von Interesse - auf der Karte.";
TWM_TOOLTIP_OPT_SHOWGRAVEYARDS = "Zeigt Friedhof-Markierungen auf der Karte.";
TWM_TOOLTIP_OPT_SHOWCAPITALS = "Zeigt Hauptstadt-Markierungen auf der Karte.";
TWM_TOOLTIP_OPT_SHOWDUNGEONS = "Zeigt Markierungen f\195\188r Dungeon- und Schlachtzugseing\195\164nge auf der Karte.";
TWM_TOOLTIP_OPT_ALPHA = "Legt die Transparenz des TerrainWorldMap-Fensters fest.";
TWM_TOOLTIP_OPT_ICONSIZE = "Skaliert die Gr\195\182\195\159e aller Markierungen auf der Karte.";
TWM_TOOLTIP_OPT_RESETPOSITION = "Setzt das TerrainWorldMap-Fenster auf Standardposition und -gr\195\182\195\159e zur\195\188ck. N\195\188tzlich, wenn mit dem Fenster etwas schiefgelaufen ist.";
TWM_TOOLTIP_OPT_SHOWFLIGHTMASTERS = "Zeigt Flugmeister-Markierungen auf der Karte, farblich nach Fraktion sortiert, mit einem eigenen Symbol f\195\188r neutrale.";
TWM_TOOLTIP_OPT_SHOWENEMYFLIGHTMASTERS = "Zeigt auch Flugmeister der gegnerischen Fraktion. Standardm\195\164\195\159ig deaktiviert - ohne diese Option werden nur die Flugmeister der eigenen Fraktion und neutrale angezeigt, genau wie auf der echten Flugkarte im Spiel.";
TWM_TOOLTIP_OPT_TOGGLEFLIGHTPATHS = "Zeichnet immer alle bekannten Flugrouten auf der Karte. Wenn deaktiviert, werden beim \195\156berfahren eines Flugmeisters stattdessen nur die von dort abgehenden Routen angezeigt.";

TWM_POINTS_SHOWPOINTS_TITLE = "Zeige Punkte";
-- Landmarks would tranlsate to "Landmarken", "wichtige Orte" would be translated to English: "important places"
-- I would prefer "wichtige Orte" over "Landmarken"
TWM_POINTS_LANDMARKS = "wichtige Orte";
TWM_POINTS_GRAVEYARDS = "Friedh\195\182fe";
TWM_POINTS_CAPITALS = "Hauptst\195\164dte";
TWM_POINTS_DUNGEONS = "Dungeons";
TWM_POINTS_FLIGHTMASTERS = "Flugmeister";

TWM_OPTIONS_SHOW_LANDMARKS = "Zeige wichtige Orte";
TWM_OPTIONS_SHOW_GRAVEYARDS = "Zeige Friedh\195\182fe";
TWM_OPTIONS_SHOW_CAPITALS = "Zeige Hauptst\195\164dte";
TWM_OPTIONS_SHOW_DUNGEONS = "Zeige Dungeons";
TWM_OPTIONS_SHOW_FLIGHTMASTERS = "Zeige Flugmeister";
TWM_OPTIONS_SHOW_ENEMY_FLIGHTMASTERS = "Zeige gegnerische Flugmeister";
TWM_OPTIONS_TOGGLE_FLIGHTPATHS = "Flugrouten anzeigen";



BINDING_NAME_TWM_TOGGLE = "Ein- und Ausblenden des TerrainWorldMap-Fensters";
BINDING_HEADER_TWM = TWM_TITLE;

end

