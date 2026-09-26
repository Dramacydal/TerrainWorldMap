
if (GetLocale() == "frFR") then

TWM_BUTTON_TOOLTIP1 = "TerrainWorldMap";
TWM_PLAYERJUMP = "Aller au joueur";
TWM_OPTIONSBUTTON = "Options";

-- Minimap/world-map button tooltips and right-click context menu
TWM_TOOLTIP_LEFTCLICK_OPEN = "|cff40ff40Clic gauche|r : ouvrir TerrainWorldMap";
TWM_TOOLTIP_LEFTCLICK_OVERLAY_ON = "|cff40ff40Clic gauche|r : activer la superposition de carte";
TWM_TOOLTIP_LEFTCLICK_OVERLAY_OFF = "|cff40ff40Clic gauche|r : désactiver la superposition de carte";
TWM_TOOLTIP_RIGHTCLICK_MENU = "|cff40ff40Clic droit|r : menu";
TWM_MENU_OPEN = "Ouvrir TerrainWorldMap";
TWM_MENU_SETTINGS = "Paramètres";
TWM_MENU_CHILDMAP_TILES = "Afficher les tuiles des sous-cartes";
TWM_MENU_WORLDVIEW_TILES = "Afficher les tuiles sur la carte d'Azeroth (monde)";
TWM_MENU_CITYMAP_TILES = "Afficher les tuiles sur les cartes de ville";
TWM_MENU_DRAW_UNDERWATER = "Afficher le relief sous-marin";
TWM_WORLDMAP_OVERLAY_ON = "TerrainWorldMap : superposition sur la carte du monde ACTIVÉE";
TWM_WORLDMAP_OVERLAY_OFF = "TerrainWorldMap : superposition sur la carte du monde DÉSACTIVÉE";
TWM_DEBUG_TILES_ON = "TerrainWorldMap : étiquettes de débogage des tuiles ACTIVÉES";
TWM_DEBUG_TILES_OFF = "TerrainWorldMap : étiquettes de débogage des tuiles DÉSACTIVÉES";

TWM_OPTIONS_TITLE = "Options de TerrainWorldMap";
TWM_OPTIONS_WORLDMAP_TITLE = "Options de la carte du monde";
TWM_OPTIONS_BROWSER_TITLE = "Options de la fenêtre autonome";
TWM_OPTIONS_TAB_WORLDMAP = "Carte du monde";
TWM_OPTIONS_TAB_BROWSER = "Fenêtre autonome";
TWM_OPTIONS_ENABLEBUTTON = "Activer le bouton sur la minicarte";
TWM_OPTIONS_TRACKONSHOW = "Centrer sur le joueur à l'ouverture";
TWM_OPTIONS_ALPHA = "Transparence";
TWM_OPTIONS_ICONSIZE = "Taille des icônes";
TWM_OPTIONS_RESETPOSITION = "Réinitialiser aux valeurs par défaut";

TWM_OPTIONS_TILEFILTER = "Filtrage des tuiles";
TWM_OPTIONS_TILEFILTER_LINEAR = "Doux (linéaire)";
TWM_OPTIONS_TILEFILTER_LINEAR_DESC = "Mélange les pixels voisins entre eux. Filtrage par défaut du jeu - adoucit légèrement le terrain, surtout en zoomant.";
TWM_OPTIONS_TILEFILTER_TRILINEAR = "Doux + Mipmaps (trilinéaire)";
TWM_OPTIONS_TILEFILTER_TRILINEAR_DESC = "Le même mélange que Doux, avec en plus un échantillonnage mipmap pour un rendu plus propre en dézoomant.";
TWM_OPTIONS_TILEFILTER_NEAREST = "Net (plus proche voisin)";
TWM_OPTIONS_TILEFILTER_NEAREST_DESC = "Aucun mélange - garde les contours du terrain nets, mais montre une pixellisation visible en zoomant beaucoup.";

TWM_TOOLTIP_OPT_ENABLEBUTTON = "Affiche une icône TerrainWorldMap déplaçable sur la minicarte. Clic gauche pour ouvrir la fenêtre, clic droit pour un menu d'accès rapide.";
TWM_TOOLTIP_OPT_DRAWUNDERWATER = "Affiche la version immergée des tuiles de terrain côtières (par ex. Vashj'ir, le littoral inondé de Pandarie) au lieu du décor terrestre en dessous. Disponible uniquement là où les données de ce client incluent des variantes de tuiles sous-marines.";
TWM_TOOLTIP_OPT_CHILDMAPTILES = "Affiche aussi toute zone que la hiérarchie des cartes de Blizzard classe nominalement sous un continent, alors que son terrain réel se trouve sur un autre - par exemple, les zones de départ Draeneï (Île d'Azuremyst, Île de Bloodmyst) apparaissent ici sous Kalimdor, et les zones de départ Elfe de sang (Bois d'Eversong, Landes fantômes, Île de Quel'Danas) sous Royaume de l'Est. Remarque : des tuiles de zones qui se chevauchent peuvent apparaître à cause de la façon dont leurs coordonnées fonctionnent, c'est pourquoi cette option est facultative.";
TWM_TOOLTIP_OPT_WORLDVIEWTILES = "Superpose le vrai terrain sur la vue continent/monde dézoomée de la carte du monde. Cela peut provoquer quelques saccades en consultant cette carte, c'est pourquoi c'est rendu facultatif.";
TWM_TOOLTIP_OPT_CITYMAPTILES = "Superpose le vrai terrain sur les cartes de ville (par ex. Hurlevent, Orgrimmar) ouvertes depuis la carte du monde. Désactivez ceci si vous préférez le décor de ville original - par exemple, le vrai terrain ne convient pas bien à Fossoyeuse.";
TWM_TOOLTIP_OPT_TRACKONSHOW = "Centre et zoome automatiquement la fenêtre TerrainWorldMap sur votre position actuelle à chaque ouverture.";
TWM_TOOLTIP_OPT_SHOWLANDMARKS = "Active/désactive les marqueurs de sous-zones - auberges, grottes, lacs et autres points d'intérêt similaires - affichés sur la carte.";
TWM_TOOLTIP_OPT_SHOWGRAVEYARDS = "Active/désactive les marqueurs de cimetières sur la carte.";
TWM_TOOLTIP_OPT_SHOWCAPITALS = "Active/désactive les marqueurs de capitales sur la carte.";
TWM_TOOLTIP_OPT_SHOWDUNGEONS = "Active/désactive les marqueurs d'entrée de donjons et de raids sur la carte.";
TWM_TOOLTIP_OPT_ALPHA = "Définit l'opacité de la fenêtre TerrainWorldMap.";
TWM_TOOLTIP_OPT_ICONSIZE = "Change la taille de tous les marqueurs de points affichés sur la carte.";
TWM_TOOLTIP_OPT_RESETPOSITION = "Réinitialise la position et la taille de la fenêtre TerrainWorldMap, ainsi que chaque case et curseur de cet onglet, à leurs valeurs par défaut. Utile si quelque chose s'est mal passé avec la fenêtre (par ex. coincée hors écran ou d'une taille inutilisable).";
TWM_TOOLTIP_OPT_SHOWFLIGHTMASTERS = "Active/désactive les marqueurs de maîtres du vol sur la carte, colorés selon la faction, avec une icône distincte pour les neutres.";
TWM_TOOLTIP_OPT_SHOWENEMYFLIGHTMASTERS = "Affiche aussi les maîtres du vol de la faction adverse. Désactivé par défaut - sans cela, seuls les maîtres du vol de votre propre faction et les neutres sont affichés, comme sur la vraie carte des vols en jeu.";
TWM_TOOLTIP_OPT_TOGGLEFLIGHTPATHS = "Affiche en permanence toutes les routes de vol connues sur la carte. Si désactivé, survoler un maître du vol affiche uniquement les routes partant de celui-ci. Dans les deux cas, maintenez Maj pour voir le vrai tracé courbe d'une route au lieu d'une ligne droite. Peut ralentir le jeu sur les continents avec beaucoup de routes, surtout avec Maj enfoncée.";
TWM_TOOLTIP_OPT_FLIGHTPATHTHICKNESS = "Définit l'épaisseur des lignes de routes de vol, en pixels à l'écran.";
TWM_TOOLTIP_OPT_FLIGHTPATHINTERPOLATION = "Adoucit le vrai tracé courbe d'une route de vol (Maj enfoncée) en ajoutant des points calculés entre les points d'origine, au lieu d'une ligne brisée visiblement anguleuse. 0 désactive cet effet. Appliqué uniquement au maître du vol actuellement survolé, jamais à la vue complète du continent de \"Basculer les routes de vol\", afin d'éviter les ralentissements.";

TWM_POINTS_SHOWPOINTS_TITLE = "Afficher les points";
TWM_POINTS_LANDMARKS = "Points de repère";
TWM_POINTS_GRAVEYARDS = "Cimetières";
TWM_POINTS_CAPITALS = "Capitales";
TWM_POINTS_DUNGEONS = "Donjons";
TWM_POINTS_FLIGHTMASTERS = "Maîtres du vol";

TWM_OPTIONS_SHOW_LANDMARKS = "Afficher les points de repère";
TWM_OPTIONS_SHOW_GRAVEYARDS = "Afficher les cimetières";
TWM_OPTIONS_SHOW_CAPITALS = "Afficher les capitales";
TWM_OPTIONS_SHOW_DUNGEONS = "Afficher les donjons";
TWM_OPTIONS_SHOW_FLIGHTMASTERS = "Afficher les maîtres du vol";
TWM_OPTIONS_SHOW_ENEMY_FLIGHTMASTERS = "Afficher les maîtres du vol de la faction adverse";
TWM_OPTIONS_TOGGLE_FLIGHTPATHS = "Basculer les routes de vol";
TWM_OPTIONS_FLIGHTPATH_THICKNESS = "Épaisseur des routes de vol";
TWM_OPTIONS_FLIGHTPATH_INTERPOLATION = "Lissage des routes de vol";


TWM_ZOOMIN =     "+";
TWM_ZOOMOUT =     "-";

BINDING_NAME_TWM_TOGGLE = "Afficher/masquer la fenêtre TerrainWorldMap";
BINDING_HEADER_TWM = TWM_TITLE;

end
