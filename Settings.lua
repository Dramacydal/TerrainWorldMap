-- Native Blizzard AddOn settings panel (Interface Options), replaces the old standalone TWMOptionFrame.

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

function MainPanel.OnRefresh()
    enableButton:SetChecked(TWMOption.ShowButton);
end

--
-- "World Map" subcategory: the WorldMapFrame tile-overlay toggles.
--

local WorldMapPanel = CreateFrame("Frame");
WorldMapPanel.name = TWM_OPTIONS_TAB_WORLDMAP;

local childMapTilesButton = CreateCheckbox(WorldMapPanel, "TWMOptionChildMapTiles", TWM_MENU_CHILDMAP_TILES);
childMapTilesButton:SetPoint("TOPLEFT", 16, -16);
childMapTilesButton:SetScript("OnClick", function(self)
    TWM_SetChildMapTiles(self:GetChecked() and true or false);
end);

local worldViewTilesButton = CreateCheckbox(WorldMapPanel, "TWMOptionWorldViewTiles", TWM_MENU_WORLDVIEW_TILES);
worldViewTilesButton:SetPoint("TOPLEFT", childMapTilesButton, "BOTTOMLEFT", 0, -12);
worldViewTilesButton:SetScript("OnClick", function(self)
    TWM_SetWorldViewTiles(self:GetChecked() and true or false);
end);

local cityMapTilesButton = CreateCheckbox(WorldMapPanel, "TWMOptionCityMapTiles", TWM_MENU_CITYMAP_TILES);
cityMapTilesButton:SetPoint("TOPLEFT", worldViewTilesButton, "BOTTOMLEFT", 0, -12);
cityMapTilesButton:SetScript("OnClick", function(self)
    TWM_SetCityMapTiles(self:GetChecked() and true or false);
end);

-- Only exists for flavors whose data was actually generated with a minimaps
-- dir and found at least one noLiquid tile (see TWM_HasNoLiquidData() in
-- TerrainWorldMap.lua) -- e.g. not TBC/Vanilla, which never got this data.
local drawUnderwaterButton;
if(TWM_HasNoLiquidData()) then
    drawUnderwaterButton = CreateCheckbox(WorldMapPanel, "TWMOptionDrawUnderwater", TWM_MENU_DRAW_UNDERWATER);
    drawUnderwaterButton:SetPoint("TOPLEFT", cityMapTilesButton, "BOTTOMLEFT", 0, -12);
    drawUnderwaterButton:SetScript("OnClick", function(self)
        TWM_SetDrawUnderwater(self:GetChecked() and true or false);
    end);
end

function WorldMapPanel.OnRefresh()
    childMapTilesButton:SetChecked(TWM_IsChildMapTilesEnabled());
    worldViewTilesButton:SetChecked(TWM_IsWorldViewTilesEnabled());
    cityMapTilesButton:SetChecked(TWM_IsCityMapTilesEnabled());
    if(drawUnderwaterButton) then
        drawUnderwaterButton:SetChecked(TWM_IsDrawUnderwaterEnabled());
    end
end

--
-- "Browser" subcategory: the TerrainWorldMap window itself (tracking + appearance).
--

local BrowserPanel = CreateFrame("Frame");
BrowserPanel.name = TWM_OPTIONS_TAB_BROWSER;

local trackOnShowButton = CreateCheckbox(BrowserPanel, "TWMOptionTrackOnShow", TWM_OPTIONS_TRACKONSHOW);
trackOnShowButton:SetPoint("TOPLEFT", 16, -16);
trackOnShowButton:SetScript("OnClick", function(self)
    for h,v in pairs(TWMOption.Frames) do
        if(self:GetChecked()) then
            v.trackonshow = "player";
        else
            v.trackonshow = nil;
        end
    end
end);

local showLandmarksButton = CreateCheckbox(BrowserPanel, "TWMOptionShowLandmarks", TWM_OPTIONS_SHOW_LANDMARKS);
showLandmarksButton:SetPoint("TOPLEFT", trackOnShowButton, "BOTTOMLEFT", 0, -12);
showLandmarksButton:SetScript("OnClick", function(self)
    TWMOption.Frames["TWMFrame"].PointCfg["landmarks"] = not self:GetChecked();
    TWMPoints_ForceUpdate(TWMFrame);
end);

local showGraveyardsButton = CreateCheckbox(BrowserPanel, "TWMOptionShowGraveyards", TWM_OPTIONS_SHOW_GRAVEYARDS);
showGraveyardsButton:SetPoint("TOPLEFT", showLandmarksButton, "BOTTOMLEFT", 0, -12);
showGraveyardsButton:SetScript("OnClick", function(self)
    TWMOption.Frames["TWMFrame"].PointCfg["graveyards"] = not self:GetChecked();
    TWMPoints_ForceUpdate(TWMFrame);
end);

local showCapitalsButton = CreateCheckbox(BrowserPanel, "TWMOptionShowCapitals", TWM_OPTIONS_SHOW_CAPITALS);
showCapitalsButton:SetPoint("TOPLEFT", showGraveyardsButton, "BOTTOMLEFT", 0, -12);
showCapitalsButton:SetScript("OnClick", function(self)
    TWMOption.Frames["TWMFrame"].PointCfg["capitals"] = not self:GetChecked();
    TWMPoints_ForceUpdate(TWMFrame);
end);

local showDungeonsButton = CreateCheckbox(BrowserPanel, "TWMOptionShowDungeons", TWM_OPTIONS_SHOW_DUNGEONS);
showDungeonsButton:SetPoint("TOPLEFT", showCapitalsButton, "BOTTOMLEFT", 0, -12);
showDungeonsButton:SetScript("OnClick", function(self)
    TWMOption.Frames["TWMFrame"].PointCfg["dungeons"] = not self:GetChecked();
    TWMPoints_ForceUpdate(TWMFrame);
end);

local alphaSlider = CreateSlider(BrowserPanel, "TWMOptionAlphaSlider", TWM_OPTIONS_ALPHA, .1, 1, .05);
alphaSlider:SetPoint("TOPLEFT", showDungeonsButton, "BOTTOMLEFT", 4, -32);
alphaSlider:SetScript("OnValueChanged", function(self)
    TWMFrame:SetAlpha(self:GetValue());
    TWMOption.Frames["TWMFrame"].Alpha = self:GetValue();
end);

local iconSizeSlider = CreateSlider(BrowserPanel, "TWMOptionIconSizeSlider", TWM_OPTIONS_ICONSIZE, 0.5, 3.0, 0.1);
iconSizeSlider:SetPoint("TOPLEFT", alphaSlider, "BOTTOMLEFT", 0, -32);
iconSizeSlider:SetScript("OnValueChanged", function(self)
    local v = self:GetValue();
    if(TWMOption.Frames["TWMFrame"].IconSize ~= v) then
        TWMOption.Frames["TWMFrame"].IconSize = v;
        TWMPoints_Update(TWMFrame);
    end
end);

local resetPositionButton = CreateFrame("Button", "TWMOptionResetPosition", BrowserPanel, "UIPanelButtonTemplate");
resetPositionButton:SetSize(160, 22);
resetPositionButton:SetPoint("TOPLEFT", iconSizeSlider, "BOTTOMLEFT", -4, -32);
resetPositionButton:SetText(TWM_OPTIONS_RESETPOSITION);
resetPositionButton:SetScript("OnClick", function()
    TWM_ResetFramePosition();
end);

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
    end
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
