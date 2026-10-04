
if (GetLocale() == "esES" or GetLocale() == "esMX") then

-- One file for both Spanish clients; they differ only in the word for dungeons.
local dungeons = GetLocale() == "esMX" and "calabozos" or "mazmorras";
local Dungeons = dungeons:sub(1, 1):upper() .. dungeons:sub(2);

TWM_BUTTON_TOOLTIP1 = "TerrainWorldMap";
TWM_PLAYERJUMP = "Ir al jugador";
TWM_TOOLTIP_PLAYERJUMP = "Centra el mapa en tu personaje.";
TWM_TOOLTIP_PLAYERJUMP_FOLLOW = "Mayús+clic: activa o desactiva el modo de seguimiento (el mapa te sigue; solo en continentes). Arrastrar el mapa lo desactiva.";
TWM_TOOLTIP_CLICK_OPEN_MAP = "Clic: abrir este mapa";
TWM_OPTIONSBUTTON = "Opciones";

-- Minimap/world-map button tooltips and right-click context menu
TWM_TOOLTIP_LEFTCLICK_OPEN = "|cff40ff40Clic izquierdo|r: abrir TerrainWorldMap";
TWM_TOOLTIP_LEFTCLICK_OVERLAY_ON = "|cff40ff40Clic izquierdo|r: activar la superposición del mapa";
TWM_TOOLTIP_LEFTCLICK_OVERLAY_OFF = "|cff40ff40Clic izquierdo|r: desactivar la superposición del mapa";
TWM_TOOLTIP_RIGHTCLICK_MENU = "|cff40ff40Clic derecho|r: menú";
TWM_MENU_OPEN = "Abrir TerrainWorldMap";
TWM_MENU_SETTINGS = "Ajustes";
TWM_MENU_CHILDMAP_TILES = "Dibujar teselas de los mapas secundarios";
TWM_MENU_WORLDVIEW_TILES = "Dibujar teselas en el mapa de Azeroth (mundo)";
TWM_MENU_CITYMAP_TILES = "Dibujar teselas en los mapas de ciudad";
TWM_MENU_DRAW_UNDERWATER = "Mostrar el terreno submarino";
TWM_WORLDMAP_OVERLAY_ON = "TerrainWorldMap: superposición del mapa del mundo ACTIVADA";
TWM_WORLDMAP_OVERLAY_OFF = "TerrainWorldMap: superposición del mapa del mundo DESACTIVADA";
TWM_DEBUG_TILES_ON = "TerrainWorldMap: etiquetas de depuración de teselas ACTIVADAS";
TWM_DEBUG_TILES_OFF = "TerrainWorldMap: etiquetas de depuración de teselas DESACTIVADAS";

TWM_OPTIONS_TITLE = "Opciones de TerrainWorldMap";
TWM_OPTIONS_WORLDMAP_TITLE = "Opciones del mapa del mundo";
TWM_OPTIONS_BROWSER_TITLE = "Opciones de la ventana independiente";
TWM_OPTIONS_TAB_WORLDMAP = "Mapa del mundo";
TWM_OPTIONS_TAB_BROWSER = "Ventana independiente";
TWM_OPTIONS_ENABLEBUTTON = "Activar el botón del minimapa";
TWM_OPTIONS_TRACKONSHOW = "Centrar en el jugador al abrir";
TWM_OPTIONS_ALPHA = "Transparencia";
TWM_OPTIONS_ICONSIZE = "Tamaño de los iconos";
TWM_OPTIONS_RESETPOSITION = "Restablecer valores predeterminados";

TWM_OPTIONS_TILEFILTER = "Filtrado de teselas";
TWM_OPTIONS_TILEFILTER_LINEAR = "Suave (lineal)";
TWM_OPTIONS_TILEFILTER_LINEAR_DESC = "Mezcla los píxeles vecinos entre sí. Es el filtrado predeterminado del juego: difumina ligeramente el terreno, sobre todo al acercar.";
TWM_OPTIONS_TILEFILTER_TRILINEAR = "Suave + mipmaps (trilineal)";
TWM_OPTIONS_TILEFILTER_TRILINEAR_DESC = "La misma mezcla que Suave, con muestreo de mipmaps para un resultado más limpio al alejar.";
TWM_OPTIONS_TILEFILTER_NEAREST = "Nítido (vecino más cercano)";
TWM_OPTIONS_TILEFILTER_NEAREST_DESC = "Sin mezcla: mantiene nítidos los bordes del terreno, pero se nota la pixelación al acercar mucho.";

TWM_TOOLTIP_OPT_ENABLEBUTTON = "Muestra un icono de TerrainWorldMap movible en el minimapa. El clic izquierdo abre la ventana y el clic derecho abre un menú de acceso rápido.";
TWM_TOOLTIP_OPT_DRAWUNDERWATER = "Dibuja la versión sumergida de las teselas de terreno costeras (p. ej., Vashj'ir, la costa inundada de Pandaria) en lugar del dibujo de tierra firme. Solo disponible si los datos de este cliente incluyen variantes submarinas de las teselas.";
TWM_TOOLTIP_OPT_CHILDMAPTILES = "Dibuja también cualquier zona que la jerarquía de mapas de Blizzard asigna nominalmente a un continente aunque su terreno real esté en otro; por ejemplo, las zonas iniciales de los draenei (Isla Azur, Isla Bruma de Sangre) aparecen aquí bajo Kalimdor, y las de los elfos de sangre (Bosque de Canción Eterna, Tierras Fantasma, Isla de Quel'Danas) bajo los Reinos del Este. Nota: pueden aparecer teselas de zonas superpuestas por cómo funcionan sus coordenadas, por eso es una opción.";
TWM_TOOLTIP_OPT_WORLDVIEWTILES = "Superpone teselas de terreno reales en la vista alejada de continentes y mundo del mapa del mundo. Puede provocar algunos tirones al ver ese mapa, por eso es opcional.";
TWM_TOOLTIP_OPT_CITYMAPTILES = "Superpone teselas de terreno reales en los mapas de ciudad (p. ej., Ventormenta, Orgrimmar) abiertos desde el mapa del mundo. Desactívalo si prefieres ver el dibujo original del mapa de la ciudad; por ejemplo, el terreno real no encaja bien en Entrañas.";
TWM_TOOLTIP_OPT_TRACKONSHOW = "Centra y acerca automáticamente la ventana de TerrainWorldMap a tu posición actual cada vez que se abre.";
TWM_TOOLTIP_OPT_WMOTILEMANAGEMENT = "Permite mostrar u ocultar manualmente grupos de teselas de minimapa WMO precalculadas en el mapa.";
TWM_TOOLTIP_OPT_SHOWDEVELOPMENTMAPS = "Muestra en la lista de mapas los que existen en los datos del cliente pero no son accesibles para los jugadores: inacabados, eliminados o sustituidos por versiones más recientes.";
TWM_TOOLTIP_OPT_SHOWLANDMARKS = "Activa o desactiva los marcadores de subzonas (posadas, cuevas, lagos y otros puntos de interés similares) en el mapa.";
TWM_TOOLTIP_OPT_SHOWGRAVEYARDS = "Activa o desactiva los marcadores de cementerios en el mapa.";
TWM_TOOLTIP_OPT_SHOWCAPITALS = "Activa o desactiva los marcadores de capitales en el mapa.";
TWM_TOOLTIP_OPT_SHOWDUNGEONS = "Activa o desactiva los marcadores de entrada de " .. dungeons .. " y bandas en el mapa.";
TWM_TOOLTIP_OPT_ALPHA = "Define la opacidad de la ventana de TerrainWorldMap.";
TWM_TOOLTIP_OPT_ICONSIZE = "Cambia el tamaño de todos los marcadores que se muestran en el mapa.";
TWM_TOOLTIP_OPT_RESETPOSITION = "Restablece la posición y el tamaño de la ventana de TerrainWorldMap, así como todas las casillas y deslizadores de esta pestaña, a sus valores predeterminados. Útil si algo ha fallado con la ventana (p. ej., se ha quedado fuera de la pantalla o con un tamaño inutilizable).";
TWM_TOOLTIP_OPT_SHOWFLIGHTMASTERS = "Activa o desactiva los marcadores de maestros de vuelo en el mapa, coloreados según la facción, con un icono distinto para los neutrales.";
TWM_TOOLTIP_OPT_SHOWENEMYFLIGHTMASTERS = "Muestra también los maestros de vuelo de la facción contraria. Desactivado de forma predeterminada: sin esta opción solo se muestran los maestros de vuelo de tu facción y los neutrales, igual que en el mapa de vuelo real del juego.";
TWM_TOOLTIP_OPT_TOGGLEFLIGHTPATHS = "Dibuja siempre todas las rutas de vuelo conocidas en el mapa. Si está desactivado, al pasar el cursor sobre un maestro de vuelo solo se muestran las rutas que salen de él. En ambos casos, mantén Mayús pulsado para ver el trazado curvo real de una ruta en lugar de una línea recta. Puede ralentizar el juego en continentes con muchas rutas, sobre todo con Mayús pulsado.";
TWM_TOOLTIP_OPT_FLIGHTPATHTHICKNESS = "Define el grosor de las líneas de las rutas de vuelo, en píxeles de pantalla.";
TWM_TOOLTIP_OPT_FLIGHTPATHINTERPOLATION = "Suaviza el trazado curvo real de una ruta de vuelo (con Mayús pulsado) añadiendo puntos calculados entre los originales, en lugar de una línea quebrada con ángulos visibles. 0 lo desactiva. Solo se aplica al maestro de vuelo sobre el que tienes el cursor, nunca a la vista completa del continente de \"Alternar rutas de vuelo\", para evitar ralentizaciones.";

TWM_CATEGORY_CONTINENTS = "Continentes";
TWM_CATEGORY_DUNGEONS = Dungeons;
TWM_CATEGORY_RAIDS = "Bandas";
TWM_CATEGORY_SCENARIOS = "Escenarios";
TWM_CATEGORY_BATTLEGROUNDS = "Campos de batalla";
TWM_CATEGORY_ARENAS = "Arenas";

-- Same titles as the esES/esMX clients' own EXPANSION_NAME<N> strings (Classic: "World of Warcraft: Clásico").
TWM_EXPANSION_0 = "Clásico";
TWM_EXPANSION_1 = "The Burning Crusade";
TWM_EXPANSION_2 = "Wrath of the Lich King";
TWM_EXPANSION_3 = "Cataclysm";
TWM_EXPANSION_4 = "Mists of Pandaria";
TWM_POINTS_GRAVEYARDS = "Cementerios";

TWM_OPTIONS_SHOW_TERRAIN = "Mostrar terreno";
TWM_OPTIONS_SHOW_WMO_OVERLAY = "Mostrar capas WMO";
TWM_OPTIONS_WMO_TILE_MANAGEMENT = "Gestión de teselas WMO";
TWM_OPTIONS_WMO_SHOW_ALL = "Mostrar todo";
TWM_OPTIONS_SHOW_DEVELOPMENT_MAPS = "Mostrar mapas inaccesibles";
TWM_OPTIONS_AUTOHIDE_CONTROLS = "Atenuar los controles cuando el ratón está fuera de la ventana";
TWM_TOOLTIP_OPT_AUTOHIDECONTROLS = "Desvanece el encabezado, el pie y todos los botones cuando el ratón sale de la ventana de TerrainWorldMap, y los vuelve a mostrar cuando regresa.";
TWM_OPTIONS_GROUP_WINDOW = "Ventana";
TWM_OPTIONS_GROUP_MARKERS = "Marcadores del mapa";
TWM_OPTIONS_GROUP_FLIGHTPATHS = "Rutas de vuelo";
TWM_OPTIONS_GROUP_EXTRAS = "Extras";
TWM_WMO_HEIGHT_CUTOFF = "Límite de altura";
TWM_OPTIONS_SHOW_LANDMARKS = "Mostrar puntos de interés";
TWM_OPTIONS_SHOW_GRAVEYARDS = "Mostrar cementerios";
TWM_OPTIONS_SHOW_CAPITALS = "Mostrar capitales";
TWM_OPTIONS_SHOW_DUNGEONS = "Mostrar " .. dungeons;
TWM_OPTIONS_SHOW_FLIGHTMASTERS = "Mostrar maestros de vuelo";
TWM_OPTIONS_SHOW_ENEMY_FLIGHTMASTERS = "Mostrar maestros de vuelo de la facción contraria";
TWM_OPTIONS_TOGGLE_FLIGHTPATHS = "Alternar rutas de vuelo";
TWM_OPTIONS_FLIGHTPATH_THICKNESS = "Grosor de las rutas de vuelo";
TWM_OPTIONS_FLIGHTPATH_INTERPOLATION = "Suavizado de las rutas de vuelo";


BINDING_NAME_TWM_TOGGLE = "Mostrar u ocultar la ventana de TerrainWorldMap";
BINDING_HEADER_TWM = TWM_TITLE;

end
