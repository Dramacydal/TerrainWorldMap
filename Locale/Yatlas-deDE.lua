
if (GetLocale() == "deDE") then

-- Deutsche
--            lower      upper
-- a umlaut   \195\164   \195\132
-- o umlaut   \195\192   \195\150
-- u umlaut   \195\188   \195\156
-- "          \"
-- '          \'

YATLAS_HELP_TEXT = {
    "Yatlas bietet eine Minimap-basierte Weltkarte (deutlich mehr Details).\n\n"..
    "Zum Schieben der Karte klickt direkt auf die Karte und verschiebt sie."..
    "W\195\164hlt den darzustellenden Kontinent oberhalb der Karte aus (derzeit nur".. 
    "Kalimdor und die \195\182stlichen K\195\182nigreiche). \n"..
    "Ihr k\195\182nnt verschieden Zonen ausw\195\164hlen oder zur Spielerposition springen."..
    "Im Bereich \"Daten\" werden wichtige Orte in Form einer Legende angezeigt"..
    "und im Bereich \"Optionen\" k\195\182nnen Sichtbarkeit und Position des Minimap-Icons"..
    "und auch die Transparenz des Yatlas-Fensters ver\195\164ndert werden.\n"
    };

YATLAS_TAB_DATA = "Zeige Daten";
YATLAS_TAB_OPTIONS = "Optionen";

YATLAS_BUTTON_TOOLTIP1 = "Yatlas";
YATLAS_PLAYERJUMP = "Spielerposition";
YATLAS_OPTIONSBUTTON = "Optionen";

-- Minimap-/Weltkarten-Button: Tooltips und Rechtsklick-Kontextmen\195\188
YATLAS_TOOLTIP_LEFTCLICK_OPEN = "|cff40ff40Linksklick|r: Yatlas \195\182ffnen";
YATLAS_TOOLTIP_LEFTCLICK_OVERLAY_ON = "|cff40ff40Linksklick|r: gebackenes Karten-Overlay aktivieren";
YATLAS_TOOLTIP_LEFTCLICK_OVERLAY_OFF = "|cff40ff40Linksklick|r: gebackenes Karten-Overlay deaktivieren";
YATLAS_TOOLTIP_RIGHTCLICK_MENU = "|cff40ff40Rechtsklick|r: Men\195\188";
YATLAS_MENU_OPEN = "Yatlas \195\182ffnen";
YATLAS_MENU_SETTINGS = "Einstellungen";
YATLAS_MENU_CHILDMAP_TILES = "Kindkarten-Kacheln zeichnen";
YATLAS_MENU_WORLDVIEW_TILES = "Kacheln auf der Azeroth-Weltkarte zeichnen";
YATLAS_MENU_CITYMAP_TILES = "Kacheln auf Stadtkarten zeichnen";
YATLAS_WORLDMAP_OVERLAY_ON = "Yatlas: Weltkarten-Overlay AN";
YATLAS_WORLDMAP_OVERLAY_OFF = "Yatlas: Weltkarten-Overlay AUS";
YATLAS_DEBUG_TILES_ON = "Yatlas: Kachel-Debug-Beschriftungen AN";
YATLAS_DEBUG_TILES_OFF = "Yatlas: Kachel-Debug-Beschriftungen AUS";

YATLAS_OPTIONS_TITLE = "Yatlas-Optionen";
YATLAS_OPTIONS_TAB_WORLDMAP = "Weltkarte";
YATLAS_OPTIONS_TAB_BROWSER = "Browser";
YATLAS_OPTIONS_BUTTONPOS = " Position des Minimap-Icons";
YATLAS_OPTIONS_BUTTONPOS_TIP = "%d\�";
YATLAS_OPTIONS_ENABLEBUTTON = "Aktiviere Minimap-Icon";
YATLAS_OPTIONS_ALPHA = "Transparenz";
YATLAS_OPTIONS_ICONSIZE = "Icon Gr\195\182\195\159e";
YATLAS_OPTIONS_ENABLECOORD = "Aktiviere Cursor-Koordinaten";
YATLAS_OPTIONS_RESETPOSITION = "Position zur\195\188cksetzen";

YATLAS_POINTS_SHOWPOINTS_TITLE = "Zeige Punkte";
-- Landmarks would tranlsate to "Landmarken", "wichtige Orte" would be translated to English: "important places"
-- I would prefer "wichtige Orte" over "Landmarken"
YATLAS_POINTS_LANDMARKS = "wichtige Orte";

YATLAS_UNKNOWN_ZONE = "Unbekannt";

YATLAS_BIGDRAGMESSAGE = "Klicke und ziehe die Karte um den Ausschnitt zu verschieben."

BINDING_NAME_YATLAS_TOGGLE = "Ein- und Ausblenden des Yatlas-Fensters";
BINDING_HEADER_YATLAS = YATLAS_TITLE;

end

