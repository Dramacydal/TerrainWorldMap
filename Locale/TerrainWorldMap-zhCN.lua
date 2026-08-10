--                                                -*- coding: utf-8 -*-
-- Translated by:
-- 2006-07-12 lulu[EasyUI]

if(GetLocale() == "zhCN") then

YATLAS_HELP_TEXT = {
    "地形世界地图基于小地图数据，提供高精度的世界地图。\n\n"..
    "直接在地图上点击并拖动即可移动视野。可以在顶部选择要查看的地图"..
    "（目前支持卡利姆多、东部王国和外域）。您也可以按区域跳转，或缩放至玩家所在位置。\n\n"..
    "将鼠标悬停在标记点上会显示提示信息。\n"
    };

YATLAS_BUTTON_TOOLTIP1 = "地形世界地图";
YATLAS_PLAYERJUMP = "玩家位置";
YATLAS_OPTIONSBUTTON = "设定";

-- 小地图/世界地图按钮的提示和右键菜单
YATLAS_TOOLTIP_LEFTCLICK_OPEN = "|cff40ff40左键|r：打开地形世界地图";
YATLAS_TOOLTIP_LEFTCLICK_OVERLAY_ON = "|cff40ff40左键|r：启用烘焙地图叠加层";
YATLAS_TOOLTIP_LEFTCLICK_OVERLAY_OFF = "|cff40ff40左键|r：禁用烘焙地图叠加层";
YATLAS_TOOLTIP_RIGHTCLICK_MENU = "|cff40ff40右键|r：菜单";
YATLAS_MENU_OPEN = "打开地形世界地图";
YATLAS_MENU_SETTINGS = "设定";
YATLAS_MENU_CHILDMAP_TILES = "绘制子地图贴图";
YATLAS_MENU_WORLDVIEW_TILES = "在艾泽拉斯（世界）地图上绘制贴图";
YATLAS_MENU_CITYMAP_TILES = "在城市地图上绘制贴图";
YATLAS_WORLDMAP_OVERLAY_ON = "地形世界地图：世界地图叠加层 开启";
YATLAS_WORLDMAP_OVERLAY_OFF = "地形世界地图：世界地图叠加层 关闭";
YATLAS_DEBUG_TILES_ON = "地形世界地图：贴图调试标签 开启";
YATLAS_DEBUG_TILES_OFF = "地形世界地图：贴图调试标签 关闭";

YATLAS_OPTIONS_TITLE = "地形世界地图设定";
YATLAS_OPTIONS_TAB_WORLDMAP = "世界地图";
YATLAS_OPTIONS_TAB_BROWSER = "浏览器";
YATLAS_OPTIONS_ENABLEBUTTON = "开启按钮";
YATLAS_OPTIONS_TRACKONSHOW = "缩放至玩家可见";
YATLAS_OPTIONS_ALPHA = "透明度";
YATLAS_OPTIONS_ICONSIZE = "图标大小";
YATLAS_OPTIONS_RESETPOSITION = "重置位置";

YATLAS_POINTS_SHOWPOINTS_TITLE = "显示标记";
YATLAS_POINTS_LANDMARKS = "地名";

YATLAS_UNKNOWN_ZONE = "未知";

YATLAS_ZOOMIN =     "+";
YATLAS_ZOOMOUT =     "-";

BINDING_NAME_YATLAS_TOGGLE = "正常地形世界地图";
BINDING_HEADER_YATLAS = YATLAS_TITLE;

end
