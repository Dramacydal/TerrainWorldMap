-- Native Blizzard AddOn settings panel (Interface Options), replaces the old standalone TWMOptionFrame.
--
-- Every tab is a native vertical-layout category: Blizzard lays the list out and
-- scrolls it. Each option is a proxy setting (getter/setter over TWMOption), so
-- the saved layout (and the code that reads it) is independent of the panel.

local function FrameOption()
    return TWMOption and TWMOption.Frames and TWMOption.Frames["TWMFrame"];
end

-- A tab: a category with its layout, plus the settings registered in it.
local tabs = {};

local function CreateTab(name, parent)
    local tab = {settings = {}};
    if(parent) then
        tab.category, tab.layout = Settings.RegisterVerticalLayoutSubcategory(parent.category, name);
    else
        tab.category, tab.layout = Settings.RegisterVerticalLayoutCategory(name);
        Settings.RegisterAddOnCategory(tab.category);
    end
    tabs[tab.category] = tab;
    return tab;
end

local function AddHeader(tab, text)
    tab.layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(text));
end

local function AddSetting(tab, variable, varType, name, default, getValue, setValue)
    local setting = Settings.RegisterProxySetting(tab.category, "TWM_" .. variable, varType, name, default, getValue, setValue);
    table.insert(tab.settings, setting);
    return setting;
end

local function AddCheckbox(tab, variable, name, tooltip, default, getValue, setValue)
    local setting = AddSetting(tab, variable, Settings.VarType.Boolean, name, default, getValue, setValue);
    return setting, Settings.CreateCheckbox(tab.category, setting, tooltip);
end

local function AddSlider(tab, variable, name, tooltip, default, minValue, maxValue, step, decimals, getValue, setValue)
    local setting = AddSetting(tab, variable, Settings.VarType.Number, name, default, getValue, function(value)
        -- The slider hands over floating point values (0.30000000000000004).
        setValue(math.floor(value / step + 0.5) * step);
    end);
    local options = Settings.CreateSliderOptions(minValue, maxValue, step);
    options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
        return string.format("%." .. decimals .. "f", value);
    end);
    Settings.CreateSlider(tab.category, setting, options, tooltip);
    return setting;
end

-- choices: {{value, label, tooltip}, ...}
local function AddDropdown(tab, variable, name, tooltip, default, choices, getValue, setValue)
    local setting = AddSetting(tab, variable, Settings.VarType.String, name, default, getValue, setValue);
    Settings.CreateDropdown(tab.category, setting, function()
        local container = Settings.CreateControlTextContainer();
        for _, choice in ipairs(choices) do
            container:Add(choice[1], choice[2], choice[3]);
        end
        return container:GetData();
    end, tooltip);
    return setting;
end

local function GlobalOptionGetter(key, default)
    return function()
        local value = TWMOption and TWMOption[key];
        if(value == nil) then return default; end
        return value;
    end
end

--
-- Main tab: what applies to the addon as a whole.
--

local mainTab = CreateTab(TWM_TITLE);

AddHeader(mainTab, string.format(TWM_OPTIONS_VERSION, TWM_VERSION));

AddCheckbox(mainTab, "ShowButton", TWM_OPTIONS_ENABLEBUTTON, TWM_TOOLTIP_OPT_ENABLEBUTTON, true,
    GlobalOptionGetter("ShowButton", true),
    function(value)
        TWMOption.ShowButton = value;
        TWMButton_Update();
    end);

AddDropdown(mainTab, "TileFilter", TWM_OPTIONS_TILEFILTER, nil, "NEAREST", {
        {"LINEAR", TWM_OPTIONS_TILEFILTER_LINEAR, TWM_OPTIONS_TILEFILTER_LINEAR_DESC},
        {"TRILINEAR", TWM_OPTIONS_TILEFILTER_TRILINEAR, TWM_OPTIONS_TILEFILTER_TRILINEAR_DESC},
        {"NEAREST", TWM_OPTIONS_TILEFILTER_NEAREST, TWM_OPTIONS_TILEFILTER_NEAREST_DESC},
    },
    function() return TWM_GetTileFilter(); end,
    function(value) TWM_SetTileFilter(value); end);

-- Only exists for flavors whose data was actually generated with a minimaps
-- dir and found at least one noLiquid tile (see TWM_HasNoLiquidData() in
-- TerrainWorldMap.lua) -- e.g. not TBC/Vanilla, which never got this data.
if(TWM_HasNoLiquidData()) then
    AddCheckbox(mainTab, "DrawUnderwater", TWM_MENU_DRAW_UNDERWATER, TWM_TOOLTIP_OPT_DRAWUNDERWATER, true,
        GlobalOptionGetter("DrawUnderwater", true),
        function(value) TWM_SetDrawUnderwater(value); end);
end

TWMSettingsCategory = mainTab.category;

--
-- "World Map" tab: the WorldMapFrame tile-overlay toggles.
--

local worldMapTab = CreateTab(TWM_OPTIONS_TAB_WORLDMAP, mainTab);

AddCheckbox(worldMapTab, "ChildMapTiles", TWM_MENU_CHILDMAP_TILES, TWM_TOOLTIP_OPT_CHILDMAPTILES, true,
    GlobalOptionGetter("WorldMapOverlayChildMaps", true),
    function(value) TWM_SetChildMapTiles(value); end);

AddCheckbox(worldMapTab, "WorldViewTiles", TWM_MENU_WORLDVIEW_TILES, TWM_TOOLTIP_OPT_WORLDVIEWTILES, false,
    GlobalOptionGetter("WorldMapOverlayWorldView", false),
    function(value) TWM_SetWorldViewTiles(value); end);

AddCheckbox(worldMapTab, "CityMapTiles", TWM_MENU_CITYMAP_TILES, TWM_TOOLTIP_OPT_CITYMAPTILES, false,
    GlobalOptionGetter("WorldMapOverlayCityMaps", false),
    function(value) TWM_SetCityMapTiles(value); end);

--
-- "Browser" tab: the TerrainWorldMap window itself.
--

local browserTab = CreateTab(TWM_OPTIONS_TAB_BROWSER, mainTab);

-- A point set is shown unless PointCfg[key] says otherwise.
local function MarkerGetter(key)
    return function()
        local opt = FrameOption();
        return not (opt and opt.PointCfg and opt.PointCfg[key]);
    end
end

local function MarkerSetter(key)
    return function(value)
        local opt = FrameOption();
        if(not opt) then return; end
        opt.PointCfg = opt.PointCfg or {};
        opt.PointCfg[key] = not value;
        if(TWMFrame) then TWMPoints_ForceUpdate(TWMFrame); end
    end
end

local function AddMarkerCheckbox(key, name, tooltip)
    return AddCheckbox(browserTab, "Show_" .. key, name, tooltip, true, MarkerGetter(key), MarkerSetter(key));
end

-- Window

AddHeader(browserTab, TWM_OPTIONS_GROUP_WINDOW);

AddCheckbox(browserTab, "TrackOnShow", TWM_OPTIONS_TRACKONSHOW, TWM_TOOLTIP_OPT_TRACKONSHOW, false,
    function()
        local _, opt = next(TWMOption and TWMOption.Frames or {});
        return opt ~= nil and opt.trackonshow ~= nil;
    end,
    function(value)
        for _, opt in pairs(TWMOption.Frames) do
            opt.trackonshow = value and "player" or nil;
        end
    end);

AddCheckbox(browserTab, "AutoHideControls", TWM_OPTIONS_AUTOHIDE_CONTROLS, TWM_TOOLTIP_OPT_AUTOHIDECONTROLS, true,
    GlobalOptionGetter("AutoHideControls", true),
    function(value) TWMOption.AutoHideControls = value; end);

AddSlider(browserTab, "Alpha", TWM_OPTIONS_ALPHA, TWM_TOOLTIP_OPT_ALPHA, TWM_FRAME_OPTION_DEFAULTS.Alpha, 0.1, 1, 0.05, 2,
    function()
        local opt = FrameOption();
        return opt and opt.Alpha or TWM_FRAME_OPTION_DEFAULTS.Alpha;
    end,
    function(value)
        local opt = FrameOption();
        if(not opt) then return; end
        opt.Alpha = value;
        if(TWMFrame) then TWMFrame:SetAlpha(value); end
    end);

-- Map markers

AddHeader(browserTab, TWM_OPTIONS_GROUP_MARKERS);

AddMarkerCheckbox("landmarks", TWM_OPTIONS_SHOW_LANDMARKS, TWM_TOOLTIP_OPT_SHOWLANDMARKS);
AddMarkerCheckbox("graveyards", TWM_OPTIONS_SHOW_GRAVEYARDS, TWM_TOOLTIP_OPT_SHOWGRAVEYARDS);
AddMarkerCheckbox("capitals", TWM_OPTIONS_SHOW_CAPITALS, TWM_TOOLTIP_OPT_SHOWCAPITALS);
AddMarkerCheckbox("dungeons", TWM_OPTIONS_SHOW_DUNGEONS, TWM_TOOLTIP_OPT_SHOWDUNGEONS);

local flightmastersSetting, flightmastersInitializer =
    AddMarkerCheckbox("flightmasters", TWM_OPTIONS_SHOW_FLIGHTMASTERS, TWM_TOOLTIP_OPT_SHOWFLIGHTMASTERS);

local _, enemyFlightmastersInitializer = AddCheckbox(browserTab, "ShowEnemyFlightmasters",
    TWM_OPTIONS_SHOW_ENEMY_FLIGHTMASTERS, TWM_TOOLTIP_OPT_SHOWENEMYFLIGHTMASTERS, false,
    GlobalOptionGetter("ShowEnemyFlightmasters", false),
    function(value)
        TWMOption.ShowEnemyFlightmasters = value;
        if(TWMFrame) then TWMPoints_ForceUpdate(TWMFrame); end
    end);
enemyFlightmastersInitializer:SetParentInitializer(flightmastersInitializer, function()
    return flightmastersSetting:GetValue();
end);

AddSlider(browserTab, "IconSize", TWM_OPTIONS_ICONSIZE, TWM_TOOLTIP_OPT_ICONSIZE, TWM_FRAME_OPTION_DEFAULTS.IconSize, 0.5, 3.0, 0.1, 1,
    function()
        local opt = FrameOption();
        return opt and opt.IconSize or TWM_FRAME_OPTION_DEFAULTS.IconSize;
    end,
    function(value)
        local opt = FrameOption();
        if(not opt or opt.IconSize == value) then return; end
        opt.IconSize = value;
        if(TWMFrame) then TWMPoints_Update(TWMFrame); end
    end);

-- Flight paths

AddHeader(browserTab, TWM_OPTIONS_GROUP_FLIGHTPATHS);

AddCheckbox(browserTab, "ShowFlightPaths", TWM_OPTIONS_TOGGLE_FLIGHTPATHS, TWM_TOOLTIP_OPT_TOGGLEFLIGHTPATHS, false,
    GlobalOptionGetter("ShowFlightPaths", false),
    function(value)
        TWMOption.ShowFlightPaths = value;
        TWM_FlightPaths_Refresh();
    end);

AddSlider(browserTab, "FlightPathThickness", TWM_OPTIONS_FLIGHTPATH_THICKNESS, TWM_TOOLTIP_OPT_FLIGHTPATHTHICKNESS,
    TWM_FLIGHTPATH_DEFAULT_THICKNESS, 1, 4, 0.5, 1,
    TWM_GetFlightPathThickness, TWM_SetFlightPathThickness);

AddSlider(browserTab, "FlightPathInterpolation", TWM_OPTIONS_FLIGHTPATH_INTERPOLATION, TWM_TOOLTIP_OPT_FLIGHTPATHINTERPOLATION,
    TWM_FLIGHTPATH_DEFAULT_INTERPOLATION, 0, 10, 1, 0,
    TWM_GetFlightPathInterpolation, TWM_SetFlightPathInterpolation);

-- Extras

AddHeader(browserTab, TWM_OPTIONS_GROUP_EXTRAS);

AddCheckbox(browserTab, "WMOTileManagement", TWM_OPTIONS_WMO_TILE_MANAGEMENT, TWM_TOOLTIP_OPT_WMOTILEMANAGEMENT, false,
    GlobalOptionGetter("WMOTileManagement", false),
    function(value)
        TWMOption.WMOTileManagement = value;
        if(TWMFrame) then TWM_UpdateOverlayButtons(TWMFrame); end
    end);

AddCheckbox(browserTab, "ShowDevelopmentMaps", TWM_OPTIONS_SHOW_DEVELOPMENT_MAPS, TWM_TOOLTIP_OPT_SHOWDEVELOPMENTMAPS, false,
    GlobalOptionGetter("ShowDevelopmentMaps", false),
    function(value)
        TWMOption.ShowDevelopmentMaps = value;
        -- The dropdown lists hold the visible maps; recompute what was cached.
        if(TWMFrame) then
            TWMFrame:UpdateMapGroup();
            TWMFrame:UpdateDropDown2();
        end
    end);

local function ResetTab(tab)
    for _, setting in ipairs(tab.settings) do
        setting:SetValueToDefault();
    end
end

browserTab.layout:AddInitializer(CreateSettingsButtonInitializer(
    TWM_OPTIONS_RESETPOSITION, TWM_OPTIONS_RESETPOSITION,
    function()
        TWM_ResetFramePosition();
        ResetTab(browserTab);
    end,
    TWM_TOOLTIP_OPT_RESETPOSITION, true));

-- The panel's own "Defaults" button offers to reset every interface setting of
-- the game, far more than these tabs need (the Browser tab has its own reset
-- button): hidden while one of them is shown.
if(SettingsPanel and SettingsPanel.DisplayCategory) then
    hooksecurefunc(SettingsPanel, "DisplayCategory", function(panel, displayed)
        panel:GetSettingsList().Header.DefaultsButton:SetShown(not tabs[displayed]);
    end);
end

-- Every setting of every tab back to its default (/twm reset all).
function TWM_ResetSettings()
    for _, tab in pairs(tabs) do
        ResetTab(tab);
    end
end

function TWMOption_Toggle()
    Settings.OpenToCategory(TWMSettingsCategory:GetID());
end
