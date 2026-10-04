if(GetLocale() == "ruRU") then

TWM_BUTTON_TOOLTIP1 = "TerrainWorldMap";
TWM_PLAYERJUMP = "К игроку";
TWM_TOOLTIP_PLAYERJUMP = "Центрирует карту на вашем персонаже.";
TWM_TOOLTIP_PLAYERJUMP_FOLLOW = "Shift+клик: включить или выключить режим слежения (карта следует за вами; только на континентах). Перетаскивание карты его отключает.";
TWM_TOOLTIP_CLICK_OPEN_MAP = "Клик: открыть эту карту";
TWM_OPTIONSBUTTON = "Настройки";

-- Подсказки и контекстное меню кнопки на миникарте/карте мира
TWM_TOOLTIP_LEFTCLICK_OPEN = "|cff40ff40Левый клик|r: открыть TerrainWorldMap";
TWM_TOOLTIP_LEFTCLICK_OVERLAY_ON = "|cff40ff40Левый клик|r: включить наложение карты";
TWM_TOOLTIP_LEFTCLICK_OVERLAY_OFF = "|cff40ff40Левый клик|r: выключить наложение карты";
TWM_TOOLTIP_RIGHTCLICK_MENU = "|cff40ff40Правый клик|r: меню";
TWM_MENU_OPEN = "Открыть TerrainWorldMap";
TWM_MENU_SETTINGS = "Настройки";
TWM_MENU_CHILDMAP_TILES = "Отображать тайлы дочерних карт";
TWM_MENU_WORLDVIEW_TILES = "Отображать тайлы на карте Азерота (мира)";
TWM_MENU_CITYMAP_TILES = "Отображать тайлы на картах городов";
TWM_MENU_DRAW_UNDERWATER = "Отображать рельеф под водой";
TWM_WORLDMAP_OVERLAY_ON = "TerrainWorldMap: наложение на карту мира ВКЛ";
TWM_WORLDMAP_OVERLAY_OFF = "TerrainWorldMap: наложение на карту мира ВЫКЛ";
TWM_DEBUG_TILES_ON = "TerrainWorldMap: отладочные метки тайлов ВКЛ";
TWM_DEBUG_TILES_OFF = "TerrainWorldMap: отладочные метки тайлов ВЫКЛ";

TWM_OPTIONS_TITLE = "Настройки TerrainWorldMap";
TWM_OPTIONS_WORLDMAP_TITLE = "Настройки карты мира";
TWM_OPTIONS_BROWSER_TITLE = "Настройки браузера";
TWM_OPTIONS_TAB_WORLDMAP = "Карта мира";
TWM_OPTIONS_TAB_BROWSER = "Браузер";
TWM_OPTIONS_ENABLEBUTTON = "Включить кнопку на миникарте";
TWM_OPTIONS_TRACKONSHOW = "Приближать к игроку при открытии";
TWM_OPTIONS_ALPHA = "Прозрачность";
TWM_OPTIONS_ICONSIZE = "Размер иконок";
TWM_OPTIONS_RESETPOSITION = "Сбросить к умолчаниям";

TWM_OPTIONS_TILEFILTER = "Фильтрация тайлов";
TWM_OPTIONS_TILEFILTER_LINEAR = "Плавная (линейная)";
TWM_OPTIONS_TILEFILTER_LINEAR_DESC = "Смешивает соседние пиксели. Стандартная фильтрация игры - слегка размывает рельеф, особенно при приближении.";
TWM_OPTIONS_TILEFILTER_TRILINEAR = "Плавная + мипмапы (трилинейная)";
TWM_OPTIONS_TILEFILTER_TRILINEAR_DESC = "То же сглаживание, что и у \"Плавной\", плюс сэмплирование мипмапов для более чистой картинки при отдалении.";
TWM_OPTIONS_TILEFILTER_NEAREST = "Резкая (ближайший сосед)";
TWM_OPTIONS_TILEFILTER_NEAREST_DESC = "Без сглаживания - края рельефа остаются чёткими, но при сильном приближении заметна пикселизация.";

TWM_TOOLTIP_OPT_ENABLEBUTTON = "Показывает перетаскиваемую иконку TerrainWorldMap на миникарте. Левый клик открывает окно, правый - быстрое меню.";
TWM_TOOLTIP_OPT_DRAWUNDERWATER = "Отображает подводную версию прибрежных тайлов рельефа (например, Вайш'ир, затопленное побережье Пандарии) вместо надводного варианта. Доступно только там, где для этого клиента есть данные с подводными тайлами.";
TWM_TOOLTIP_OPT_CHILDMAPTILES = "Также отображает любую зону, которая в иерархии карт Blizzard номинально приписана к одному континенту, хотя её реальный рельеф находится на другом - например, стартовые зоны дренеев (Остров Лазурной Дымки, Остров Кровавой Дымки) показываются здесь рядом с Калимдором, а зоны кровавых эльфов (Леса Вечной Песни, Призрачные земли, остров Кель'Данас) - на Восточных королевствах. Внимание - возможны наложения тайлов зон из-за особенностей их координат, из-за этого функция сделана опциональной.";
TWM_TOOLTIP_OPT_WORLDVIEWTILES = "Отображает реальные тайлы рельефа на отдалённом виде карты континента/мира. Эта функция может добавлять подтормаживания при просмотре соответствующей карты, поэтому сделана опциональной.";
TWM_TOOLTIP_OPT_CITYMAPTILES = "Отображает реальные тайлы рельефа на картах городов (например, Штормграда, Оргриммара), открываемых с карты мира. Отключите эту функцию, если хотите оригинальную карту для столиц. Например, для Подгорода реальный ландшафт не подходит.";
TWM_TOOLTIP_OPT_TRACKONSHOW = "Автоматически центрирует и приближает окно TerrainWorldMap к вашему текущему положению при каждом открытии.";
TWM_TOOLTIP_OPT_WMOTILEMANAGEMENT = "Позволяет вручную включать/отключать отрисовку групп тайлов на карте.";
TWM_TOOLTIP_OPT_SHOWDEVELOPMENTMAPS = "Показывает в списке карт те, что есть в данных клиента, но недоступны игрокам: незавершённые, вырезанные или заменённые новыми версиями.";
TWM_TOOLTIP_OPT_SHOWLANDMARKS = "Отображение подзон - таверн, пещер, озёр и подобных точек интереса - на карте.";
TWM_TOOLTIP_OPT_SHOWGRAVEYARDS = "Отображение меток кладбищ на карте.";
TWM_TOOLTIP_OPT_SHOWCAPITALS = "Отображение меток столиц на карте.";
TWM_TOOLTIP_OPT_SHOWDUNGEONS = "Отображение меток входов в подземелья и рейды на карте.";
TWM_TOOLTIP_OPT_ALPHA = "Задаёт прозрачность окна TerrainWorldMap.";
TWM_TOOLTIP_OPT_ICONSIZE = "Изменяет размер всех меток точек интереса на карте.";
TWM_TOOLTIP_OPT_RESETPOSITION = "Возвращает положение и размер окна TerrainWorldMap, а также все чекбоксы и ползунки на этой вкладке, к значениям по умолчанию. Полезно, если с окном что-то пошло не так.";
TWM_TOOLTIP_OPT_SHOWFLIGHTMASTERS = "Отображение меток лётных мастеров на карте, с раскраской по фракции и отдельной иконкой для нейтральных.";
TWM_TOOLTIP_OPT_SHOWENEMYFLIGHTMASTERS = "Также показывать лётных мастеров вражеской фракции. По умолчанию выключено - без этой опции показываются только мастера вашей фракции и нейтральные, как на обычной карте полётов в игре.";
TWM_TOOLTIP_OPT_TOGGLEFLIGHTPATHS = "Всегда отображать все известные маршруты полётов на карте. Если выключено, при наведении на лётного мастера показываются только маршруты, отправляющиеся из этой точки. В любом случае, зажмите Shift, чтобы увидеть настоящую изогнутую траекторию маршрута вместо прямой линии. На континентах с большим количеством маршрутов может подтормаживать, особенно с зажатым Shift.";
TWM_TOOLTIP_OPT_FLIGHTPATHTHICKNESS = "Задаёт толщину линий маршрутов полётов в экранных пикселях.";
TWM_TOOLTIP_OPT_FLIGHTPATHINTERPOLATION = "Сглаживает реальный изогнутый маршрут полёта (при зажатом Shift), добавляя между его исходными точками дополнительные вычисленные точки, вместо заметно ломаной линии. 0 отключает сглаживание. Применяется только к тому флайт-мастеру, над которым сейчас находится курсор, и никогда — к полному виду континента при включённом \"Показывать маршруты полётов\", чтобы не вызывать лаги.";


TWM_CATEGORY_CONTINENTS = "Континенты";
TWM_CATEGORY_DUNGEONS = "Подземелья";
TWM_CATEGORY_RAIDS = "Рейды";
TWM_CATEGORY_SCENARIOS = "Сценарии";
TWM_CATEGORY_BATTLEGROUNDS = "Поля боя";
TWM_CATEGORY_ARENAS = "Арены";

-- Официальный русский клиент не переводит эти названия (проверено по
-- игровым данным Achievement_Category, а не на глаз) - те же английские
-- названия, что и в enUS.
TWM_EXPANSION_0 = "Classic";
TWM_EXPANSION_1 = "The Burning Crusade";
TWM_EXPANSION_2 = "Wrath of the Lich King";
TWM_EXPANSION_3 = "Cataclysm";
TWM_EXPANSION_4 = "Mists of Pandaria";
TWM_POINTS_GRAVEYARDS = "Кладбища";

TWM_OPTIONS_SHOW_TERRAIN = "Показывать ландшафт";
TWM_OPTIONS_SHOW_WMO_OVERLAY = "Показывать слои WMO";
TWM_OPTIONS_WMO_TILE_MANAGEMENT = "Управление тайлами WMO";
TWM_OPTIONS_WMO_SHOW_ALL = "Показать все";
TWM_OPTIONS_SHOW_DEVELOPMENT_MAPS = "Показывать недоступные карты";
TWM_OPTIONS_AUTOHIDE_CONTROLS = "Скрывать элементы окна, когда курсор вне его";
TWM_TOOLTIP_OPT_AUTOHIDECONTROLS = "Плавно скрывает шапку, нижнюю панель и все кнопки, когда курсор покидает окно TerrainWorldMap, и снова показывает их, когда он возвращается.";
TWM_OPTIONS_GROUP_WINDOW = "Окно";
TWM_OPTIONS_GROUP_MARKERS = "Маркеры на карте";
TWM_OPTIONS_GROUP_FLIGHTPATHS = "Маршруты полётов";
TWM_OPTIONS_GROUP_EXTRAS = "Дополнительно";
TWM_WMO_HEIGHT_CUTOFF = "Порог высоты";
TWM_OPTIONS_SHOW_LANDMARKS = "Показывать достопримечательности";
TWM_OPTIONS_SHOW_GRAVEYARDS = "Показывать кладбища";
TWM_OPTIONS_SHOW_CAPITALS = "Показывать столицы";
TWM_OPTIONS_SHOW_DUNGEONS = "Показывать подземелья";
TWM_OPTIONS_SHOW_FLIGHTMASTERS = "Показывать лётных мастеров";
TWM_OPTIONS_SHOW_ENEMY_FLIGHTMASTERS = "Показывать лётных мастеров вражеской фракции";
TWM_OPTIONS_TOGGLE_FLIGHTPATHS = "Показывать маршруты полётов";
TWM_OPTIONS_FLIGHTPATH_THICKNESS = "Толщина маршрутов полётов";
TWM_OPTIONS_FLIGHTPATH_INTERPOLATION = "Сглаживание маршрутов полётов";


BINDING_NAME_TWM_TOGGLE = "Открыть/закрыть окно TerrainWorldMap";
BINDING_HEADER_TWM = TWM_TITLE;

end
