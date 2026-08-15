--                                                -*- coding: utf-8 -*-
-- Translated by:
-- 2006-07-12 lulu[EasyUI]

if(GetLocale() == "zhCN") then

TWM_BUTTON_TOOLTIP1 = "地形世界地图";
TWM_PLAYERJUMP = "玩家位置";
TWM_OPTIONSBUTTON = "设定";

-- 小地图/世界地图按钮的提示和右键菜单
TWM_TOOLTIP_LEFTCLICK_OPEN = "|cff40ff40左键|r：打开地形世界地图";
TWM_TOOLTIP_LEFTCLICK_OVERLAY_ON = "|cff40ff40左键|r：启用烘焙地图叠加层";
TWM_TOOLTIP_LEFTCLICK_OVERLAY_OFF = "|cff40ff40左键|r：禁用烘焙地图叠加层";
TWM_TOOLTIP_RIGHTCLICK_MENU = "|cff40ff40右键|r：菜单";
TWM_MENU_OPEN = "打开地形世界地图";
TWM_MENU_SETTINGS = "设定";
TWM_MENU_CHILDMAP_TILES = "绘制子地图贴图";
TWM_MENU_WORLDVIEW_TILES = "在艾泽拉斯（世界）地图上绘制贴图";
TWM_MENU_CITYMAP_TILES = "在城市地图上绘制贴图";
TWM_MENU_DRAW_UNDERWATER = "显示水下地形";
TWM_WORLDMAP_OVERLAY_ON = "地形世界地图：世界地图叠加层 开启";
TWM_WORLDMAP_OVERLAY_OFF = "地形世界地图：世界地图叠加层 关闭";
TWM_DEBUG_TILES_ON = "地形世界地图：贴图调试标签 开启";
TWM_DEBUG_TILES_OFF = "地形世界地图：贴图调试标签 关闭";

TWM_OPTIONS_TITLE = "地形世界地图设定";
TWM_OPTIONS_WORLDMAP_TITLE = "世界地图设定";
TWM_OPTIONS_BROWSER_TITLE = "浏览器设定";
TWM_OPTIONS_TAB_WORLDMAP = "世界地图";
TWM_OPTIONS_TAB_BROWSER = "浏览器";
TWM_OPTIONS_ENABLEBUTTON = "开启按钮";
TWM_OPTIONS_TRACKONSHOW = "缩放至玩家可见";
TWM_OPTIONS_ALPHA = "透明度";
TWM_OPTIONS_ICONSIZE = "图标大小";
TWM_OPTIONS_RESETPOSITION = "重置位置";

TWM_OPTIONS_TILEFILTER = "贴图过滤方式";
TWM_OPTIONS_TILEFILTER_LINEAR = "平滑（线性）";
TWM_OPTIONS_TILEFILTER_LINEAR_DESC = "混合相邻像素。游戏默认的过滤方式——放大时地形会略微模糊。";
TWM_OPTIONS_TILEFILTER_TRILINEAR = "平滑+多级纹理（三线性）";
TWM_OPTIONS_TILEFILTER_TRILINEAR_DESC = "与平滑效果相同，并额外采样多级纹理，缩小时画面更干净。";
TWM_OPTIONS_TILEFILTER_NEAREST = "锐利（最近邻）";
TWM_OPTIONS_TILEFILTER_NEAREST_DESC = "不进行混合——地形边缘更锐利，但放大较多时会出现明显的像素颗粒感。";

TWM_TOOLTIP_OPT_ENABLEBUTTON = "在小地图上显示一个可拖动的地形世界地图图标。左键点击打开窗口，右键点击打开快捷菜单。";
TWM_TOOLTIP_OPT_DRAWUNDERWATER = "在沿海地形贴图上显示淹没版本（例如瓦斯琴尔、潘达利亚被淹没的海岸线），而不是原本的陆地画面。仅当此客户端的数据包含水下贴图变体时才可用。";
TWM_TOOLTIP_OPT_CHILDMAPTILES = "还会额外绘制任何在暴雪地图层级中名义上归属于某个大陆、但实际地形其实位于另一个大陆的区域——例如，德莱尼的初始区域会显示在卡利姆多地图下，而血精灵的初始区域会显示在东部王国地图下。注意：由于坐标机制的特殊性，区域贴图之间可能出现重叠，因此该功能被设为可选项。";
TWM_TOOLTIP_OPT_WORLDVIEWTILES = "在世界地图缩小后的大陆/世界视图上叠加真实地形贴图。查看该地图时可能会造成一些卡顿，因此该功能被设为可选项。";
TWM_TOOLTIP_OPT_CITYMAPTILES = "在从世界地图打开的城市地图（例如暴风城、奥格瑞玛）上叠加真实地形贴图。如果你更喜欢原版城市地图的画面，可以关闭此功能——例如，幽暗城就不太适合使用真实地形。";
TWM_TOOLTIP_OPT_TRACKONSHOW = "每次打开地形世界地图窗口时，自动将视图居中并缩放到你当前所在的位置。";
TWM_TOOLTIP_OPT_SHOWLANDMARKS = "显示子区域标记——旅店、洞穴、湖泊等类似的兴趣点。";
TWM_TOOLTIP_OPT_SHOWGRAVEYARDS = "在地图上显示墓地标记。";
TWM_TOOLTIP_OPT_SHOWCAPITALS = "在地图上显示首都标记。";
TWM_TOOLTIP_OPT_SHOWDUNGEONS = "在地图上显示地下城与团队副本入口标记。";
TWM_TOOLTIP_OPT_ALPHA = "设置地形世界地图窗口的透明度。";
TWM_TOOLTIP_OPT_ICONSIZE = "缩放地图上所有标记点的大小。";
TWM_TOOLTIP_OPT_RESETPOSITION = "将地形世界地图窗口恢复到默认的位置和大小。当窗口出现问题时很有用。";
TWM_TOOLTIP_OPT_SHOWFLIGHTMASTERS = "在地图上显示飞行管理员标记，按阵营区分颜色，中立飞行管理员使用单独的图标。";
TWM_TOOLTIP_OPT_SHOWENEMYFLIGHTMASTERS = "同时显示敌对阵营的飞行管理员。默认关闭——关闭时只显示本阵营和中立的飞行管理员，与游戏内真实的飞行地图一致。";
TWM_TOOLTIP_OPT_TOGGLEFLIGHTPATHS = "始终在地图上绘制所有已知的飞行航线。关闭时，鼠标悬停在某个飞行管理员上才会显示从该处出发的航线。";

TWM_POINTS_SHOWPOINTS_TITLE = "显示标记";
TWM_POINTS_LANDMARKS = "地名";
TWM_POINTS_GRAVEYARDS = "墓地";
TWM_POINTS_CAPITALS = "首都";
TWM_POINTS_DUNGEONS = "地下城";
TWM_POINTS_FLIGHTMASTERS = "飞行管理员";

TWM_OPTIONS_SHOW_LANDMARKS = "显示地名";
TWM_OPTIONS_SHOW_GRAVEYARDS = "显示墓地";
TWM_OPTIONS_SHOW_CAPITALS = "显示首都";
TWM_OPTIONS_SHOW_DUNGEONS = "显示地下城";
TWM_OPTIONS_SHOW_FLIGHTMASTERS = "显示飞行管理员";
TWM_OPTIONS_SHOW_ENEMY_FLIGHTMASTERS = "显示敌对阵营飞行管理员";
TWM_OPTIONS_TOGGLE_FLIGHTPATHS = "显示飞行航线";


TWM_ZOOMIN =     "+";
TWM_ZOOMOUT =     "-";

BINDING_NAME_TWM_TOGGLE = "正常地形世界地图";
BINDING_HEADER_TWM = TWM_TITLE;

end
