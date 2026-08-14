if(GetLocale() == "ruRU") then

TWM_HELP_TEXT = {
    "TerrainWorldMap отображает карту мира на основе миникарты (довольно высокая "..
        "детализация).\n\n"..
    "Чтобы перемещать область просмотра, кликните на карту и потяните. "..
        "Вы можете выбрать континент (сейчас доступны Калимдор, Восточные "..
        "королевства и Запределье) в верхней части окна. Также можно "..
        "переходить по зонам и приближать вид к игроку.\n\n"..
    "Наведение курсора на точку интереса покажет подсказку.\n"
    };

TWM_BUTTON_TOOLTIP1 = "TerrainWorldMap";
TWM_PLAYERJUMP = "К игроку";
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
TWM_OPTIONS_TAB_WORLDMAP = "Карта мира";
TWM_OPTIONS_TAB_BROWSER = "Браузер";
TWM_OPTIONS_ENABLEBUTTON = "Включить кнопку на миникарте";
TWM_OPTIONS_TRACKONSHOW = "Приближать к игроку при открытии";
TWM_OPTIONS_ALPHA = "Прозрачность";
TWM_OPTIONS_ICONSIZE = "Размер иконок";
TWM_OPTIONS_RESETPOSITION = "Сбросить положение";

TWM_POINTS_SHOWPOINTS_TITLE = "Показывать метки";
TWM_POINTS_LANDMARKS = "Достопримечательности";
TWM_POINTS_GRAVEYARDS = "Кладбища";

TWM_OPTIONS_SHOW_LANDMARKS = "Показывать достопримечательности";
TWM_OPTIONS_SHOW_GRAVEYARDS = "Показывать кладбища";


BINDING_NAME_TWM_TOGGLE = "Открыть/закрыть окно TerrainWorldMap";
BINDING_HEADER_TWM = TWM_TITLE;

end
