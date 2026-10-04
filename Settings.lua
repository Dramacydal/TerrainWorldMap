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

-- Keeps each slider's own label showing its live value, e.g.
-- "Icon Size (1.2)" -- decimals should match that slider's own step (0 for
-- a step of 1, 1 for 0.5/0.1, 2 for 0.05, etc.) so the label never shows
-- more precision than the slider can actually land on.
local function UpdateSliderLabel(globalName, labelText, v, decimals)
    _G[globalName.."Text"]:SetText(labelText .. " (" .. string.format("%." .. decimals .. "f", v) .. ")");
end

local function CreateSlider(parent, globalName, labelText, minVal, maxVal, step)
    local slider = CreateFrame("Slider", globalName, parent, "OptionsSliderTemplate");
    slider:SetSize(180, 16);
    _G[globalName.."Text"]:SetText(labelText);
    _G[globalName.."High"]:SetText();
    _G[globalName.."Low"]:SetText();
    slider:SetMinMaxValues(minVal, maxVal);
    slider:SetValueStep(step);
    -- SetValueStep alone only snaps arrow-key nudges -- dragging the thumb
    -- with the mouse ignores it and returns fractional values unless this
    -- is also set.
    slider:SetObeyStepOnDrag(true);
    return slider;
end

-- Heading of an option group: yellow caption with a thin line under it.
local function CreateGroupHeader(parent, text)
    local header = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal");
    header:SetJustifyH("LEFT");
    header:SetText(text);

    local line = parent:CreateTexture(nil, "ARTWORK");
    line:SetColorTexture(1, 1, 1, 0.25);
    line:SetSize(340, 1);
    line:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -3);
    return header;
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

local tileFilterDropDown = CreateFrame("DropdownButton", "TWMOptionTileFilterDropDown", MainPanel, "WowStyle1DropdownTemplate");
tileFilterDropDown:SetPoint("TOPLEFT", tileFilterLabel, "BOTTOMLEFT", 0, -4);
tileFilterDropDown:SetSize(220, 24);

-- The button text is the selected radio's text.
tileFilterDropDown:SetupMenu(function(dropdown, root)
    for _, opt in ipairs(TWM_TILE_FILTER_OPTIONS) do
        local radio = root:CreateRadio(opt.label,
            function(value) return TWM_GetTileFilter() == value; end,
            TWM_SetTileFilter, opt.value);
        radio:SetTooltip(function(tooltip)
            GameTooltip_SetTitle(tooltip, opt.label);
            GameTooltip_AddNormalLine(tooltip, opt.tooltip);
        end);
    end
end);

-- Only exists for flavors whose data was actually generated with a minimaps
-- dir and found at least one noLiquid tile (see TWM_HasNoLiquidData() in
-- TerrainWorldMap.lua) -- e.g. not TBC/Vanilla, which never got this data.
local drawUnderwaterButton;
if(TWM_HasNoLiquidData()) then
    drawUnderwaterButton = CreateCheckbox(MainPanel, "TWMOptionDrawUnderwater", TWM_MENU_DRAW_UNDERWATER);
    drawUnderwaterButton:SetPoint("TOPLEFT", tileFilterDropDown, "BOTTOMLEFT", 0, -12);
    drawUnderwaterButton:SetScript("OnClick", function(self)
        TWM_SetDrawUnderwater(self:GetChecked() and true or false);
    end);
    SetTooltip(drawUnderwaterButton, TWM_MENU_DRAW_UNDERWATER, TWM_TOOLTIP_OPT_DRAWUNDERWATER);
end

function MainPanel.OnRefresh()
    enableButton:SetChecked(TWMOption.ShowButton);
    tileFilterDropDown:GenerateMenu();
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

-- This tab's own option list has grown past one screen's worth of height,
-- and Blizzard's canvas-category Settings panels (unlike the declarative
-- Settings-list ones) don't scroll on their own -- wrapped in a real
-- ScrollFrame + UIPanelScrollBarTemplate scrollbar so it no longer spills
-- past the window's own bottom edge. The scrollbar's own up/down arrow buttons render OUTSIDE its declared
-- rect, so TWM_BROWSER_SCROLLBAR_ARROW_HEIGHT reserves room for both above
-- and below it.
local TWM_BROWSER_SCROLLBAR_ARROW_HEIGHT = 16;
local browserScroll = CreateFrame("ScrollFrame", nil, BrowserPanel);
browserScroll:SetPoint("TOPLEFT", BrowserPanel, "TOPLEFT", 0, 0);
browserScroll:SetPoint("BOTTOMRIGHT", BrowserPanel, "BOTTOMRIGHT", -20, 0);

local browserContent = CreateFrame("Frame", nil, browserScroll);
browserContent:SetPoint("TOPLEFT");
browserScroll:SetScrollChild(browserContent);

local browserScrollBar = CreateFrame("Slider", nil, BrowserPanel, "UIPanelScrollBarTemplate");
browserScrollBar:SetPoint("TOPLEFT", browserScroll, "TOPRIGHT", 4, -TWM_BROWSER_SCROLLBAR_ARROW_HEIGHT);
browserScrollBar:SetPoint("BOTTOMLEFT", browserScroll, "BOTTOMRIGHT", 4, TWM_BROWSER_SCROLLBAR_ARROW_HEIGHT);
browserScrollBar:SetScript("OnValueChanged", function(self, value)
    browserScroll:SetVerticalScroll(value);
end);
browserScroll:EnableMouseWheel(true);
browserScroll:SetScript("OnMouseWheel", function(self, delta)
    local lo, hi = browserScrollBar:GetMinMaxValues();
    browserScrollBar:SetValue(math.max(lo, math.min(hi, browserScrollBar:GetValue() - delta * 40)));
end);

local browserTitle = browserContent:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge");
browserTitle:SetPoint("TOPLEFT", 16, -16);
browserTitle:SetText(TWM_OPTIONS_BROWSER_TITLE);

local trackOnShowButton = CreateCheckbox(browserContent, "TWMOptionTrackOnShow", TWM_OPTIONS_TRACKONSHOW);
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

local showLandmarksButton = CreateCheckbox(browserContent, "TWMOptionShowLandmarks", TWM_OPTIONS_SHOW_LANDMARKS);
showLandmarksButton:SetScript("OnClick", function(self)
    TWMOption.Frames["TWMFrame"].PointCfg["landmarks"] = not self:GetChecked();
    TWMPoints_ForceUpdate(TWMFrame);
end);
SetTooltip(showLandmarksButton, TWM_OPTIONS_SHOW_LANDMARKS, TWM_TOOLTIP_OPT_SHOWLANDMARKS);

local showGraveyardsButton = CreateCheckbox(browserContent, "TWMOptionShowGraveyards", TWM_OPTIONS_SHOW_GRAVEYARDS);
showGraveyardsButton:SetScript("OnClick", function(self)
    TWMOption.Frames["TWMFrame"].PointCfg["graveyards"] = not self:GetChecked();
    TWMPoints_ForceUpdate(TWMFrame);
end);
SetTooltip(showGraveyardsButton, TWM_OPTIONS_SHOW_GRAVEYARDS, TWM_TOOLTIP_OPT_SHOWGRAVEYARDS);

local showCapitalsButton = CreateCheckbox(browserContent, "TWMOptionShowCapitals", TWM_OPTIONS_SHOW_CAPITALS);
showCapitalsButton:SetScript("OnClick", function(self)
    TWMOption.Frames["TWMFrame"].PointCfg["capitals"] = not self:GetChecked();
    TWMPoints_ForceUpdate(TWMFrame);
end);
SetTooltip(showCapitalsButton, TWM_OPTIONS_SHOW_CAPITALS, TWM_TOOLTIP_OPT_SHOWCAPITALS);

local showDungeonsButton = CreateCheckbox(browserContent, "TWMOptionShowDungeons", TWM_OPTIONS_SHOW_DUNGEONS);
showDungeonsButton:SetScript("OnClick", function(self)
    TWMOption.Frames["TWMFrame"].PointCfg["dungeons"] = not self:GetChecked();
    TWMPoints_ForceUpdate(TWMFrame);
end);
SetTooltip(showDungeonsButton, TWM_OPTIONS_SHOW_DUNGEONS, TWM_TOOLTIP_OPT_SHOWDUNGEONS);

local showFlightmastersButton = CreateCheckbox(browserContent, "TWMOptionShowFlightmasters", TWM_OPTIONS_SHOW_FLIGHTMASTERS);
showFlightmastersButton:SetScript("OnClick", function(self)
    TWMOption.Frames["TWMFrame"].PointCfg["flightmasters"] = not self:GetChecked();
    TWMPoints_ForceUpdate(TWMFrame);
end);
SetTooltip(showFlightmastersButton, TWM_OPTIONS_SHOW_FLIGHTMASTERS, TWM_TOOLTIP_OPT_SHOWFLIGHTMASTERS);

local showEnemyFlightmastersButton = CreateCheckbox(browserContent, "TWMOptionShowEnemyFlightmasters", TWM_OPTIONS_SHOW_ENEMY_FLIGHTMASTERS);
showEnemyFlightmastersButton:SetScript("OnClick", function(self)
    TWMOption.ShowEnemyFlightmasters = self:GetChecked() and true or false;
    TWMPoints_ForceUpdate(TWMFrame);
end);
SetTooltip(showEnemyFlightmastersButton, TWM_OPTIONS_SHOW_ENEMY_FLIGHTMASTERS, TWM_TOOLTIP_OPT_SHOWENEMYFLIGHTMASTERS);

local showFlightPathsButton = CreateCheckbox(browserContent, "TWMOptionShowFlightPaths", TWM_OPTIONS_TOGGLE_FLIGHTPATHS);
showFlightPathsButton:SetScript("OnClick", function(self)
    TWMOption.ShowFlightPaths = self:GetChecked() and true or false;
    if(TWM_FlightPaths_Refresh) then TWM_FlightPaths_Refresh(); end
end);
SetTooltip(showFlightPathsButton, TWM_OPTIONS_TOGGLE_FLIGHTPATHS, TWM_TOOLTIP_OPT_TOGGLEFLIGHTPATHS);

local flightPathThicknessSlider = CreateSlider(browserContent, "TWMOptionFlightPathThicknessSlider", TWM_OPTIONS_FLIGHTPATH_THICKNESS, 1, 4, 0.5);
flightPathThicknessSlider:SetScript("OnValueChanged", function(self)
    local v = self:GetValue();
    UpdateSliderLabel("TWMOptionFlightPathThicknessSlider", TWM_OPTIONS_FLIGHTPATH_THICKNESS, v, 1);
    if(TWM_SetFlightPathThickness) then TWM_SetFlightPathThickness(v); end
end);
SetTooltip(flightPathThicknessSlider, TWM_OPTIONS_FLIGHTPATH_THICKNESS, TWM_TOOLTIP_OPT_FLIGHTPATHTHICKNESS);

local flightPathInterpolationSlider = CreateSlider(browserContent, "TWMOptionFlightPathInterpolationSlider", TWM_OPTIONS_FLIGHTPATH_INTERPOLATION, 0, 10, 1);
flightPathInterpolationSlider:SetScript("OnValueChanged", function(self)
    local v = Round(self:GetValue());
    UpdateSliderLabel("TWMOptionFlightPathInterpolationSlider", TWM_OPTIONS_FLIGHTPATH_INTERPOLATION, v, 0);
    if(TWM_SetFlightPathInterpolation) then TWM_SetFlightPathInterpolation(v); end
end);
SetTooltip(flightPathInterpolationSlider, TWM_OPTIONS_FLIGHTPATH_INTERPOLATION, TWM_TOOLTIP_OPT_FLIGHTPATHINTERPOLATION);

local alphaSlider = CreateSlider(browserContent, "TWMOptionAlphaSlider", TWM_OPTIONS_ALPHA, .1, 1, .05);
alphaSlider:SetScript("OnValueChanged", function(self)
    local v = self:GetValue();
    UpdateSliderLabel("TWMOptionAlphaSlider", TWM_OPTIONS_ALPHA, v, 2);
    TWMFrame:SetAlpha(v);
    TWMOption.Frames["TWMFrame"].Alpha = v;
end);
SetTooltip(alphaSlider, TWM_OPTIONS_ALPHA, TWM_TOOLTIP_OPT_ALPHA);

local iconSizeSlider = CreateSlider(browserContent, "TWMOptionIconSizeSlider", TWM_OPTIONS_ICONSIZE, 0.5, 3.0, 0.1);
iconSizeSlider:SetScript("OnValueChanged", function(self)
    local v = self:GetValue();
    UpdateSliderLabel("TWMOptionIconSizeSlider", TWM_OPTIONS_ICONSIZE, v, 1);
    if(TWMOption.Frames["TWMFrame"].IconSize ~= v) then
        TWMOption.Frames["TWMFrame"].IconSize = v;
        TWMPoints_Update(TWMFrame);
    end
end);
SetTooltip(iconSizeSlider, TWM_OPTIONS_ICONSIZE, TWM_TOOLTIP_OPT_ICONSIZE);

local wmoTileManagementButton = CreateCheckbox(browserContent, "TWMOptionWMOTileManagement", TWM_OPTIONS_WMO_TILE_MANAGEMENT);
wmoTileManagementButton:SetScript("OnClick", function(self)
    TWMOption.WMOTileManagement = self:GetChecked() and true or false;
    TWM_UpdateOverlayButtons(TWMFrame);
end);
SetTooltip(wmoTileManagementButton, TWM_OPTIONS_WMO_TILE_MANAGEMENT, TWM_TOOLTIP_OPT_WMOTILEMANAGEMENT);

local showDevelopmentMapsButton = CreateCheckbox(browserContent, "TWMOptionShowDevelopmentMaps", TWM_OPTIONS_SHOW_DEVELOPMENT_MAPS);
showDevelopmentMapsButton:SetScript("OnClick", function(self)
    TWMOption.ShowDevelopmentMaps = self:GetChecked() and true or false;
    -- The dropdown lists hold the visible maps; recompute what was cached.
    TWMFrame:UpdateMapGroup();
    TWMFrame:UpdateDropDown2();
end);
SetTooltip(showDevelopmentMapsButton, TWM_OPTIONS_SHOW_DEVELOPMENT_MAPS, TWM_TOOLTIP_OPT_SHOWDEVELOPMENTMAPS);

local autoHideControlsButton = CreateCheckbox(browserContent, "TWMOptionAutoHideControls", TWM_OPTIONS_AUTOHIDE_CONTROLS);
autoHideControlsButton:SetScript("OnClick", function(self)
    TWMOption.AutoHideControls = self:GetChecked() and true or false;
end);
SetTooltip(autoHideControlsButton, TWM_OPTIONS_AUTOHIDE_CONTROLS, TWM_TOOLTIP_OPT_AUTOHIDECONTROLS);

local resetPositionButton = CreateFrame("Button", "TWMOptionResetPosition", browserContent, "UIPanelButtonTemplate");
resetPositionButton:SetSize(160, 22);
resetPositionButton:SetText(TWM_OPTIONS_RESETPOSITION);
resetPositionButton:SetScript("OnClick", function()
    TWM_ResetFramePosition();

    local opt = TWMOption.Frames["TWMFrame"];
    if(opt) then
        opt.trackonshow = nil;
        opt.PointCfg = {};
        opt.Alpha = TWM_FRAME_OPTION_DEFAULTS.Alpha;
        opt.IconSize = TWM_FRAME_OPTION_DEFAULTS.IconSize;
        TWMFrame:SetAlpha(opt.Alpha);
    end

    TWMOption.ShowEnemyFlightmasters = false;
    TWMOption.ShowFlightPaths = false;
    TWMOption.WMOTileManagement = false;
    TWMOption.ShowDevelopmentMaps = false;
    TWMOption.AutoHideControls = true;
    if(TWM_SetFlightPathThickness) then TWM_SetFlightPathThickness(nil); end
    if(TWM_SetFlightPathInterpolation) then TWM_SetFlightPathInterpolation(nil); end

    TWMFrame:UpdateMapGroup();
    TWMFrame:UpdateDropDown2();
    TWMPoints_ForceUpdate(TWMFrame);
    TWM_UpdateOverlayButtons(TWMFrame);
    BrowserPanel.OnRefresh();
end);
SetTooltip(resetPositionButton, TWM_OPTIONS_RESETPOSITION, TWM_TOOLTIP_OPT_RESETPOSITION);

-- Layout: option groups, each a heading followed by its controls top to bottom.
local windowHeader = CreateGroupHeader(browserContent, TWM_OPTIONS_GROUP_WINDOW);
windowHeader:SetPoint("TOPLEFT", browserTitle, "BOTTOMLEFT", 0, -20);
trackOnShowButton:SetPoint("TOPLEFT", windowHeader, "BOTTOMLEFT", 0, -10);
autoHideControlsButton:SetPoint("TOPLEFT", trackOnShowButton, "BOTTOMLEFT", 0, -12);
alphaSlider:SetPoint("TOPLEFT", autoHideControlsButton, "BOTTOMLEFT", 4, -32);

local markersHeader = CreateGroupHeader(browserContent, TWM_OPTIONS_GROUP_MARKERS);
markersHeader:SetPoint("TOPLEFT", alphaSlider, "BOTTOMLEFT", -4, -24);
showLandmarksButton:SetPoint("TOPLEFT", markersHeader, "BOTTOMLEFT", 0, -10);
showGraveyardsButton:SetPoint("TOPLEFT", showLandmarksButton, "BOTTOMLEFT", 0, -12);
showCapitalsButton:SetPoint("TOPLEFT", showGraveyardsButton, "BOTTOMLEFT", 0, -12);
showDungeonsButton:SetPoint("TOPLEFT", showCapitalsButton, "BOTTOMLEFT", 0, -12);
showFlightmastersButton:SetPoint("TOPLEFT", showDungeonsButton, "BOTTOMLEFT", 0, -12);
showEnemyFlightmastersButton:SetPoint("TOPLEFT", showFlightmastersButton, "BOTTOMLEFT", 16, -12);
iconSizeSlider:SetPoint("TOPLEFT", showEnemyFlightmastersButton, "BOTTOMLEFT", -12, -32);

local flightPathsHeader = CreateGroupHeader(browserContent, TWM_OPTIONS_GROUP_FLIGHTPATHS);
flightPathsHeader:SetPoint("TOPLEFT", iconSizeSlider, "BOTTOMLEFT", -4, -24);
showFlightPathsButton:SetPoint("TOPLEFT", flightPathsHeader, "BOTTOMLEFT", 0, -10);
flightPathThicknessSlider:SetPoint("TOPLEFT", showFlightPathsButton, "BOTTOMLEFT", 4, -32);
flightPathInterpolationSlider:SetPoint("TOPLEFT", flightPathThicknessSlider, "BOTTOMLEFT", 0, -32);

local extrasHeader = CreateGroupHeader(browserContent, TWM_OPTIONS_GROUP_EXTRAS);
extrasHeader:SetPoint("TOPLEFT", flightPathInterpolationSlider, "BOTTOMLEFT", -4, -24);
wmoTileManagementButton:SetPoint("TOPLEFT", extrasHeader, "BOTTOMLEFT", 0, -10);
showDevelopmentMapsButton:SetPoint("TOPLEFT", wmoTileManagementButton, "BOTTOMLEFT", 0, -12);
resetPositionButton:SetPoint("TOPLEFT", showDevelopmentMapsButton, "BOTTOMLEFT", 0, -24);

-- Width matched to the scroll frame's own real width here (not a second
-- TOPRIGHT anchor on the scroll child itself -- tried that, broke the scroll
-- child's layout resolution entirely, blanking the whole tab). Height
-- measured, not hand-tracked -- content:GetTop()/resetPositionButton:GetBottom()
-- reflect the real, already-resolved anchor chain, so this stays correct as
-- options are added/removed later without a matching manual height constant
-- to keep in sync. The scroll position is kept unless resetScroll is set.
local function UpdateBrowserScrollRange(resetScroll)
    browserContent:SetWidth(browserScroll:GetWidth());
    local contentHeight = (browserContent:GetTop() or 0) - (resetPositionButton:GetBottom() or 0) + 24;
    browserContent:SetHeight(math.max(contentHeight, 1));
    local overflow = contentHeight - browserScroll:GetHeight();
    if(overflow > 0) then
        browserScrollBar:SetMinMaxValues(0, overflow);
        browserScrollBar:SetValue(resetScroll == true and 0 or math.min(browserScrollBar:GetValue(), overflow));
        browserScrollBar:Show();
    else
        browserScroll:SetVerticalScroll(0);
        browserScrollBar:Hide();
    end
end

browserScroll:SetScript("OnSizeChanged", function() UpdateBrowserScrollRange(); end);

function BrowserPanel.OnRefresh()
    local aframe = next(TWMOption.Frames);
    trackOnShowButton:SetChecked(aframe and TWMOption.Frames[aframe].trackonshow ~= nil);

    local opt = TWMOption.Frames["TWMFrame"];
    if(opt) then
        alphaSlider:SetValue(opt.Alpha);
        UpdateSliderLabel("TWMOptionAlphaSlider", TWM_OPTIONS_ALPHA, opt.Alpha, 2);
        iconSizeSlider:SetValue(opt.IconSize);
        UpdateSliderLabel("TWMOptionIconSizeSlider", TWM_OPTIONS_ICONSIZE, opt.IconSize, 1);
        showLandmarksButton:SetChecked(not (opt.PointCfg and opt.PointCfg["landmarks"]));
        showGraveyardsButton:SetChecked(not (opt.PointCfg and opt.PointCfg["graveyards"]));
        showCapitalsButton:SetChecked(not (opt.PointCfg and opt.PointCfg["capitals"]));
        showDungeonsButton:SetChecked(not (opt.PointCfg and opt.PointCfg["dungeons"]));
        showFlightmastersButton:SetChecked(not (opt.PointCfg and opt.PointCfg["flightmasters"]));
    end
    showEnemyFlightmastersButton:SetChecked(TWMOption.ShowEnemyFlightmasters);
    showFlightPathsButton:SetChecked(TWMOption.ShowFlightPaths);
    wmoTileManagementButton:SetChecked(TWMOption.WMOTileManagement);
    showDevelopmentMapsButton:SetChecked(TWMOption.ShowDevelopmentMaps);
    autoHideControlsButton:SetChecked(TWMOption.AutoHideControls);
    if(TWM_GetFlightPathThickness) then
        local v = TWM_GetFlightPathThickness();
        flightPathThicknessSlider:SetValue(v);
        UpdateSliderLabel("TWMOptionFlightPathThicknessSlider", TWM_OPTIONS_FLIGHTPATH_THICKNESS, v, 1);
    end
    if(TWM_GetFlightPathInterpolation) then
        local v = TWM_GetFlightPathInterpolation();
        flightPathInterpolationSlider:SetValue(v);
        UpdateSliderLabel("TWMOptionFlightPathInterpolationSlider", TWM_OPTIONS_FLIGHTPATH_INTERPOLATION, v, 0);
    end

    UpdateBrowserScrollRange(true);
    -- Anchors on text (the group headings) and the panel's own size settle a
    -- frame after it is shown, so measure again once layout has resolved.
    C_Timer.After(0, UpdateBrowserScrollRange);
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
