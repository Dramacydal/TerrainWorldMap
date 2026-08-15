-- Native Blizzard AddOn settings panel (Interface Options), replaces the old standalone TWMOptionFrame.

-- Matches the look of the tile-filter dropdown's per-item tooltips
-- (info.tooltipTitle/info.tooltipText, rendered via GameTooltip_SetTitle +
-- GameTooltip_AddNormalLine by the dropdown template) so every option's
-- tooltip in this addon looks the same: bold title line, wrapped body below.
local function SetTooltip(frame, title, text)
    frame:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
        GameTooltip_SetTitle(GameTooltip, title);
        GameTooltip_AddNormalLine(GameTooltip, text, true);
        GameTooltip:Show();
    end);
    frame:HookScript("OnLeave", function()
        GameTooltip:Hide();
    end);
end

local function CreateCheckbox(parent, globalName, labelText)
    local button = CreateFrame("CheckButton", globalName, parent, "UICheckButtonTemplate");
    local label = button:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
    label:SetJustifyH("LEFT");
    label:SetSize(275, 16);
    label:SetPoint("LEFT", button, "RIGHT", 0, 0);
    label:SetText(labelText);
    return button;
end

local function CreateSlider(parent, globalName, labelText, minVal, maxVal, step)
    local slider = CreateFrame("Slider", globalName, parent, "OptionsSliderTemplate");
    slider:SetSize(180, 16);
    _G[globalName.."Text"]:SetText(labelText);
    _G[globalName.."High"]:SetText();
    _G[globalName.."Low"]:SetText();
    slider:SetMinMaxValues(minVal, maxVal);
    slider:SetValueStep(step);
    return slider;
end

--
-- Main panel: just what applies to the addon as a whole.
--

local MainPanel = CreateFrame("Frame");
MainPanel.name = TWM_TITLE;

local title = MainPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge");
title:SetPoint("TOPLEFT", 16, -16);
title:SetText(TWM_OPTIONS_TITLE);

local enableButton = CreateCheckbox(MainPanel, "TWMOptionButtonEnable", TWM_OPTIONS_ENABLEBUTTON);
enableButton:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -24);
enableButton:SetScript("OnClick", function(self)
    TWMOption.ShowButton = self:GetChecked() and true or false;
    TWMButton_Update();
end);
SetTooltip(enableButton, TWM_OPTIONS_ENABLEBUTTON, TWM_TOOLTIP_OPT_ENABLEBUTTON);

local TWM_TILE_FILTER_OPTIONS = {
    {value = "LINEAR",    label = TWM_OPTIONS_TILEFILTER_LINEAR,    tooltip = TWM_OPTIONS_TILEFILTER_LINEAR_DESC},
    {value = "TRILINEAR", label = TWM_OPTIONS_TILEFILTER_TRILINEAR, tooltip = TWM_OPTIONS_TILEFILTER_TRILINEAR_DESC},
    {value = "NEAREST",   label = TWM_OPTIONS_TILEFILTER_NEAREST,   tooltip = TWM_OPTIONS_TILEFILTER_NEAREST_DESC},
};

local tileFilterLabel = MainPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal");
tileFilterLabel:SetJustifyH("LEFT");
tileFilterLabel:SetPoint("TOPLEFT", enableButton, "BOTTOMLEFT", 0, -12);
tileFilterLabel:SetText(TWM_OPTIONS_TILEFILTER);

local tileFilterDropDown = CreateFrame("Frame", "TWMOptionTileFilterDropDown", MainPanel, "UIDropDownMenuTemplate");
tileFilterDropDown:SetPoint("TOPLEFT", tileFilterLabel, "BOTTOMLEFT", -16, -4);
UIDropDownMenu_SetWidth(tileFilterDropDown, 180);

local function TileFilterDropDown_Initialize()
    for _, opt in ipairs(TWM_TILE_FILTER_OPTIONS) do
        local info = UIDropDownMenu_CreateInfo();
        info.text = opt.label;
        info.checked = (TWM_GetTileFilter() == opt.value);
        info.tooltipTitle = opt.label;
        info.tooltipText = opt.tooltip;
        info.tooltipOnButton = true;
        info.func = function()
            TWM_SetTileFilter(opt.value);
            UIDropDownMenu_SetText(tileFilterDropDown, opt.label);
        end
        UIDropDownMenu_AddButton(info);
    end
end
UIDropDownMenu_Initialize(tileFilterDropDown, TileFilterDropDown_Initialize);

-- Only exists for flavors whose data was actually generated with a minimaps
-- dir and found at least one noLiquid tile (see TWM_HasNoLiquidData() in
-- TerrainWorldMap.lua) -- e.g. not TBC/Vanilla, which never got this data.
local drawUnderwaterButton;
if(TWM_HasNoLiquidData()) then
    drawUnderwaterButton = CreateCheckbox(MainPanel, "TWMOptionDrawUnderwater", TWM_MENU_DRAW_UNDERWATER);
    drawUnderwaterButton:SetPoint("TOPLEFT", tileFilterDropDown, "BOTTOMLEFT", 16, -12);
    drawUnderwaterButton:SetScript("OnClick", function(self)
        TWM_SetDrawUnderwater(self:GetChecked() and true or false);
    end);
    SetTooltip(drawUnderwaterButton, TWM_MENU_DRAW_UNDERWATER, TWM_TOOLTIP_OPT_DRAWUNDERWATER);
end

function MainPanel.OnRefresh()
    enableButton:SetChecked(TWMOption.ShowButton);
    for _, opt in ipairs(TWM_TILE_FILTER_OPTIONS) do
        if(opt.value == TWM_GetTileFilter()) then
            UIDropDownMenu_SetText(tileFilterDropDown, opt.label);
        end
    end
    if(drawUnderwaterButton) then
        drawUnderwaterButton:SetChecked(TWM_IsDrawUnderwaterEnabled());
    end
end

--
-- "World Map" subcategory: the WorldMapFrame tile-overlay toggles.
--

local WorldMapPanel = CreateFrame("Frame");
WorldMapPanel.name = TWM_OPTIONS_TAB_WORLDMAP;

local worldMapTitle = WorldMapPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge");
worldMapTitle:SetPoint("TOPLEFT", 16, -16);
worldMapTitle:SetText(TWM_OPTIONS_WORLDMAP_TITLE);

local childMapTilesButton = CreateCheckbox(WorldMapPanel, "TWMOptionChildMapTiles", TWM_MENU_CHILDMAP_TILES);
childMapTilesButton:SetPoint("TOPLEFT", worldMapTitle, "BOTTOMLEFT", 0, -24);
childMapTilesButton:SetScript("OnClick", function(self)
    TWM_SetChildMapTiles(self:GetChecked() and true or false);
end);
SetTooltip(childMapTilesButton, TWM_MENU_CHILDMAP_TILES, TWM_TOOLTIP_OPT_CHILDMAPTILES);

local worldViewTilesButton = CreateCheckbox(WorldMapPanel, "TWMOptionWorldViewTiles", TWM_MENU_WORLDVIEW_TILES);
worldViewTilesButton:SetPoint("TOPLEFT", childMapTilesButton, "BOTTOMLEFT", 0, -12);
worldViewTilesButton:SetScript("OnClick", function(self)
    TWM_SetWorldViewTiles(self:GetChecked() and true or false);
end);
SetTooltip(worldViewTilesButton, TWM_MENU_WORLDVIEW_TILES, TWM_TOOLTIP_OPT_WORLDVIEWTILES);

local cityMapTilesButton = CreateCheckbox(WorldMapPanel, "TWMOptionCityMapTiles", TWM_MENU_CITYMAP_TILES);
cityMapTilesButton:SetPoint("TOPLEFT", worldViewTilesButton, "BOTTOMLEFT", 0, -12);
cityMapTilesButton:SetScript("OnClick", function(self)
    TWM_SetCityMapTiles(self:GetChecked() and true or false);
end);
SetTooltip(cityMapTilesButton, TWM_MENU_CITYMAP_TILES, TWM_TOOLTIP_OPT_CITYMAPTILES);

function WorldMapPanel.OnRefresh()
    childMapTilesButton:SetChecked(TWM_IsChildMapTilesEnabled());
    worldViewTilesButton:SetChecked(TWM_IsWorldViewTilesEnabled());
    cityMapTilesButton:SetChecked(TWM_IsCityMapTilesEnabled());
end

--
-- "Browser" subcategory: the TerrainWorldMap window itself (tracking + appearance).
--

local BrowserPanel = CreateFrame("Frame");
BrowserPanel.name = TWM_OPTIONS_TAB_BROWSER;

local browserTitle = BrowserPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge");
browserTitle:SetPoint("TOPLEFT", 16, -16);
browserTitle:SetText(TWM_OPTIONS_BROWSER_TITLE);

local trackOnShowButton = CreateCheckbox(BrowserPanel, "TWMOptionTrackOnShow", TWM_OPTIONS_TRACKONSHOW);
trackOnShowButton:SetPoint("TOPLEFT", browserTitle, "BOTTOMLEFT", 0, -24);
trackOnShowButton:SetScript("OnClick", function(self)
    for h,v in pairs(TWMOption.Frames) do
        if(self:GetChecked()) then
            v.trackonshow = "player";
        else
            v.trackonshow = nil;
        end
    end
end);
SetTooltip(trackOnShowButton, TWM_OPTIONS_TRACKONSHOW, TWM_TOOLTIP_OPT_TRACKONSHOW);

local showLandmarksButton = CreateCheckbox(BrowserPanel, "TWMOptionShowLandmarks", TWM_OPTIONS_SHOW_LANDMARKS);
showLandmarksButton:SetPoint("TOPLEFT", trackOnShowButton, "BOTTOMLEFT", 0, -12);
showLandmarksButton:SetScript("OnClick", function(self)
    TWMOption.Frames["TWMFrame"].PointCfg["landmarks"] = not self:GetChecked();
    TWMPoints_ForceUpdate(TWMFrame);
end);
SetTooltip(showLandmarksButton, TWM_OPTIONS_SHOW_LANDMARKS, TWM_TOOLTIP_OPT_SHOWLANDMARKS);

local showGraveyardsButton = CreateCheckbox(BrowserPanel, "TWMOptionShowGraveyards", TWM_OPTIONS_SHOW_GRAVEYARDS);
showGraveyardsButton:SetPoint("TOPLEFT", showLandmarksButton, "BOTTOMLEFT", 0, -12);
showGraveyardsButton:SetScript("OnClick", function(self)
    TWMOption.Frames["TWMFrame"].PointCfg["graveyards"] = not self:GetChecked();
    TWMPoints_ForceUpdate(TWMFrame);
end);
SetTooltip(showGraveyardsButton, TWM_OPTIONS_SHOW_GRAVEYARDS, TWM_TOOLTIP_OPT_SHOWGRAVEYARDS);

local showCapitalsButton = CreateCheckbox(BrowserPanel, "TWMOptionShowCapitals", TWM_OPTIONS_SHOW_CAPITALS);
showCapitalsButton:SetPoint("TOPLEFT", showGraveyardsButton, "BOTTOMLEFT", 0, -12);
showCapitalsButton:SetScript("OnClick", function(self)
    TWMOption.Frames["TWMFrame"].PointCfg["capitals"] = not self:GetChecked();
    TWMPoints_ForceUpdate(TWMFrame);
end);
SetTooltip(showCapitalsButton, TWM_OPTIONS_SHOW_CAPITALS, TWM_TOOLTIP_OPT_SHOWCAPITALS);

local showDungeonsButton = CreateCheckbox(BrowserPanel, "TWMOptionShowDungeons", TWM_OPTIONS_SHOW_DUNGEONS);
showDungeonsButton:SetPoint("TOPLEFT", showCapitalsButton, "BOTTOMLEFT", 0, -12);
showDungeonsButton:SetScript("OnClick", function(self)
    TWMOption.Frames["TWMFrame"].PointCfg["dungeons"] = not self:GetChecked();
    TWMPoints_ForceUpdate(TWMFrame);
end);
SetTooltip(showDungeonsButton, TWM_OPTIONS_SHOW_DUNGEONS, TWM_TOOLTIP_OPT_SHOWDUNGEONS);

local showFlightmastersButton = CreateCheckbox(BrowserPanel, "TWMOptionShowFlightmasters", TWM_OPTIONS_SHOW_FLIGHTMASTERS);
showFlightmastersButton:SetPoint("TOPLEFT", showDungeonsButton, "BOTTOMLEFT", 0, -12);
showFlightmastersButton:SetScript("OnClick", function(self)
    TWMOption.Frames["TWMFrame"].PointCfg["flightmasters"] = not self:GetChecked();
    TWMPoints_ForceUpdate(TWMFrame);
end);
SetTooltip(showFlightmastersButton, TWM_OPTIONS_SHOW_FLIGHTMASTERS, TWM_TOOLTIP_OPT_SHOWFLIGHTMASTERS);

local showEnemyFlightmastersButton = CreateCheckbox(BrowserPanel, "TWMOptionShowEnemyFlightmasters", TWM_OPTIONS_SHOW_ENEMY_FLIGHTMASTERS);
showEnemyFlightmastersButton:SetPoint("TOPLEFT", showFlightmastersButton, "BOTTOMLEFT", 16, -12);
showEnemyFlightmastersButton:SetScript("OnClick", function(self)
    TWMOption.ShowEnemyFlightmasters = self:GetChecked() and true or false;
    TWMPoints_ForceUpdate(TWMFrame);
end);
SetTooltip(showEnemyFlightmastersButton, TWM_OPTIONS_SHOW_ENEMY_FLIGHTMASTERS, TWM_TOOLTIP_OPT_SHOWENEMYFLIGHTMASTERS);

local showFlightPathsButton = CreateCheckbox(BrowserPanel, "TWMOptionShowFlightPaths", TWM_OPTIONS_TOGGLE_FLIGHTPATHS);
showFlightPathsButton:SetPoint("TOPLEFT", showEnemyFlightmastersButton, "BOTTOMLEFT", -16, -12);
showFlightPathsButton:SetScript("OnClick", function(self)
    TWMOption.ShowFlightPaths = self:GetChecked() and true or false;
    if(TWM_FlightPaths_Refresh) then TWM_FlightPaths_Refresh(); end
end);
SetTooltip(showFlightPathsButton, TWM_OPTIONS_TOGGLE_FLIGHTPATHS, TWM_TOOLTIP_OPT_TOGGLEFLIGHTPATHS);

local alphaSlider = CreateSlider(BrowserPanel, "TWMOptionAlphaSlider", TWM_OPTIONS_ALPHA, .1, 1, .05);
alphaSlider:SetPoint("TOPLEFT", showFlightPathsButton, "BOTTOMLEFT", 4, -32);
alphaSlider:SetScript("OnValueChanged", function(self)
    TWMFrame:SetAlpha(self:GetValue());
    TWMOption.Frames["TWMFrame"].Alpha = self:GetValue();
end);
SetTooltip(alphaSlider, TWM_OPTIONS_ALPHA, TWM_TOOLTIP_OPT_ALPHA);

local iconSizeSlider = CreateSlider(BrowserPanel, "TWMOptionIconSizeSlider", TWM_OPTIONS_ICONSIZE, 0.5, 3.0, 0.1);
iconSizeSlider:SetPoint("TOPLEFT", alphaSlider, "BOTTOMLEFT", 0, -32);
iconSizeSlider:SetScript("OnValueChanged", function(self)
    local v = self:GetValue();
    if(TWMOption.Frames["TWMFrame"].IconSize ~= v) then
        TWMOption.Frames["TWMFrame"].IconSize = v;
        TWMPoints_Update(TWMFrame);
    end
end);
SetTooltip(iconSizeSlider, TWM_OPTIONS_ICONSIZE, TWM_TOOLTIP_OPT_ICONSIZE);

local resetPositionButton = CreateFrame("Button", "TWMOptionResetPosition", BrowserPanel, "UIPanelButtonTemplate");
resetPositionButton:SetSize(160, 22);
resetPositionButton:SetPoint("TOPLEFT", iconSizeSlider, "BOTTOMLEFT", -4, -32);
resetPositionButton:SetText(TWM_OPTIONS_RESETPOSITION);
resetPositionButton:SetScript("OnClick", function()
    TWM_ResetFramePosition();
end);
SetTooltip(resetPositionButton, TWM_OPTIONS_RESETPOSITION, TWM_TOOLTIP_OPT_RESETPOSITION);

function BrowserPanel.OnRefresh()
    local aframe = next(TWMOption.Frames);
    trackOnShowButton:SetChecked(aframe and TWMOption.Frames[aframe].trackonshow ~= nil);

    local opt = TWMOption.Frames["TWMFrame"];
    if(opt) then
        alphaSlider:SetValue(opt.Alpha);
        iconSizeSlider:SetValue(opt.IconSize);
        showLandmarksButton:SetChecked(not (opt.PointCfg and opt.PointCfg["landmarks"]));
        showGraveyardsButton:SetChecked(not (opt.PointCfg and opt.PointCfg["graveyards"]));
        showCapitalsButton:SetChecked(not (opt.PointCfg and opt.PointCfg["capitals"]));
        showDungeonsButton:SetChecked(not (opt.PointCfg and opt.PointCfg["dungeons"]));
        showFlightmastersButton:SetChecked(not (opt.PointCfg and opt.PointCfg["flightmasters"]));
    end
    showEnemyFlightmastersButton:SetChecked(TWMOption.ShowEnemyFlightmasters);
    showFlightPathsButton:SetChecked(TWMOption.ShowFlightPaths);
end

--
-- Registration
--

local category = Settings.RegisterCanvasLayoutCategory(MainPanel, MainPanel.name);
category.ID = category.ID or MainPanel.name;
Settings.RegisterAddOnCategory(category);
TWMSettingsCategory = category;

local worldMapSubcategory = Settings.RegisterCanvasLayoutSubcategory(category, WorldMapPanel, WorldMapPanel.name);
worldMapSubcategory.ID = worldMapSubcategory.ID or WorldMapPanel.name;

local browserSubcategory = Settings.RegisterCanvasLayoutSubcategory(category, BrowserPanel, BrowserPanel.name);
browserSubcategory.ID = browserSubcategory.ID or BrowserPanel.name;

function TWMOption_Toggle()
    Settings.OpenToCategory(TWMSettingsCategory.ID);
end
