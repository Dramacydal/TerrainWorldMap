if(GetLocale() == "ruRU") then

YATLAS_HELP_TEXT = {
    "TerrainWorldMap отображает карту мира на основе миникарты (довольно высокая "..
        "детализация).\n\n"..
    "Чтобы перемещать область просмотра, кликните на карту и потяните. "..
        "Вы можете выбрать континент (сейчас доступны Калимдор, Восточные "..
        "королевства и Запределье) в верхней части окна. Также можно "..
        "переходить по зонам и приближать вид к игроку.\n\n"..
    "Наведение курсора на точку интереса покажет подсказку.\n"
    };

YATLAS_BUTTON_TOOLTIP1 = "TerrainWorldMap";
YATLAS_PLAYERJUMP = "К игроку";
YATLAS_OPTIONSBUTTON = "Настройки";

-- Подсказки и контекстное меню кнопки на миникарте/карте мира
YATLAS_TOOLTIP_LEFTCLICK_OPEN = "|cff40ff40Левый клик|r: открыть TerrainWorldMap";
YATLAS_TOOLTIP_LEFTCLICK_OVERLAY_ON = "|cff40ff40Левый клик|r: включить наложение карты";
YATLAS_TOOLTIP_LEFTCLICK_OVERLAY_OFF = "|cff40ff40Левый клик|r: выключить наложение карты";
YATLAS_TOOLTIP_RIGHTCLICK_MENU = "|cff40ff40Правый клик|r: меню";
YATLAS_MENU_OPEN = "Открыть TerrainWorldMap";
YATLAS_MENU_SETTINGS = "Настройки";
YATLAS_MENU_CHILDMAP_TILES = "Отображать тайлы дочерних карт";
YATLAS_MENU_WORLDVIEW_TILES = "Отображать тайлы на карте Азерота (мира)";
YATLAS_MENU_CITYMAP_TILES = "Отображать тайлы на картах городов";
YATLAS_WORLDMAP_OVERLAY_ON = "TerrainWorldMap: наложение на карту мира ВКЛ";
YATLAS_WORLDMAP_OVERLAY_OFF = "TerrainWorldMap: наложение на карту мира ВЫКЛ";
YATLAS_DEBUG_TILES_ON = "TerrainWorldMap: отладочные метки тайлов ВКЛ";
YATLAS_DEBUG_TILES_OFF = "TerrainWorldMap: отладочные метки тайлов ВЫКЛ";

YATLAS_OPTIONS_TITLE = "Настройки TerrainWorldMap";
YATLAS_OPTIONS_TAB_WORLDMAP = "Карта мира";
YATLAS_OPTIONS_TAB_BROWSER = "Браузер";
YATLAS_OPTIONS_ENABLEBUTTON = "Включить кнопку на миникарте";
YATLAS_OPTIONS_TRACKONSHOW = "Приближать к игроку при открытии";
YATLAS_OPTIONS_ALPHA = "Прозрачность";
YATLAS_OPTIONS_ICONSIZE = "Размер иконок";
YATLAS_OPTIONS_RESETPOSITION = "Сбросить положение";

YATLAS_POINTS_SHOWPOINTS_TITLE = "Показывать метки";
YATLAS_POINTS_LANDMARKS = "Достопримечательности";

YATLAS_UNKNOWN_ZONE = "Неизвестно";

BINDING_NAME_YATLAS_TOGGLE = "Открыть/закрыть окно TerrainWorldMap";
BINDING_HEADER_YATLAS = YATLAS_TITLE;

end
