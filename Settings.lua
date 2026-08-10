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

local alphaSlider = CreateSlider(BrowserPanel, "TWMOptionAlphaSlider", TWM_OPTIONS_ALPHA, .1, 1, .05);
alphaSlider:SetPoint("TOPLEFT", trackOnShowButton, "BOTTOMLEFT", 4, -32);
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
