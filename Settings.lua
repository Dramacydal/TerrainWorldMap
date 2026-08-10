-- Native Blizzard AddOn settings panel (Interface Options), replaces the old standalone YatlasOptionsFrame.

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

local enableButton = CreateCheckbox(MainPanel, "YatlasOptionsButtonEnable", TWM_OPTIONS_ENABLEBUTTON);
enableButton:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -24);
enableButton:SetScript("OnClick", function(self)
    YatlasOptions.ShowButton = self:GetChecked() and true or false;
    YatlasButton_Update();
end);

function MainPanel.OnRefresh()
    enableButton:SetChecked(YatlasOptions.ShowButton);
end

--
-- "World Map" subcategory: the WorldMapFrame tile-overlay toggles.
--

local WorldMapPanel = CreateFrame("Frame");
WorldMapPanel.name = TWM_OPTIONS_TAB_WORLDMAP;

local childMapTilesButton = CreateCheckbox(WorldMapPanel, "YatlasOptionsChildMapTiles", TWM_MENU_CHILDMAP_TILES);
childMapTilesButton:SetPoint("TOPLEFT", 16, -16);
childMapTilesButton:SetScript("OnClick", function(self)
    Yatlas_SetChildMapTiles(self:GetChecked() and true or false);
end);

local worldViewTilesButton = CreateCheckbox(WorldMapPanel, "YatlasOptionsWorldViewTiles", TWM_MENU_WORLDVIEW_TILES);
worldViewTilesButton:SetPoint("TOPLEFT", childMapTilesButton, "BOTTOMLEFT", 0, -12);
worldViewTilesButton:SetScript("OnClick", function(self)
    Yatlas_SetWorldViewTiles(self:GetChecked() and true or false);
end);

local cityMapTilesButton = CreateCheckbox(WorldMapPanel, "YatlasOptionsCityMapTiles", TWM_MENU_CITYMAP_TILES);
cityMapTilesButton:SetPoint("TOPLEFT", worldViewTilesButton, "BOTTOMLEFT", 0, -12);
cityMapTilesButton:SetScript("OnClick", function(self)
    Yatlas_SetCityMapTiles(self:GetChecked() and true or false);
end);

function WorldMapPanel.OnRefresh()
    childMapTilesButton:SetChecked(Yatlas_IsChildMapTilesEnabled());
    worldViewTilesButton:SetChecked(Yatlas_IsWorldViewTilesEnabled());
    cityMapTilesButton:SetChecked(Yatlas_IsCityMapTilesEnabled());
end

--
-- "Browser" subcategory: the Yatlas window itself (tracking + appearance).
--

local BrowserPanel = CreateFrame("Frame");
BrowserPanel.name = TWM_OPTIONS_TAB_BROWSER;

local trackOnShowButton = CreateCheckbox(BrowserPanel, "YatlasOptionsTrackOnShow", TWM_OPTIONS_TRACKONSHOW);
trackOnShowButton:SetPoint("TOPLEFT", 16, -16);
trackOnShowButton:SetScript("OnClick", function(self)
    for h,v in pairs(YatlasOptions.Frames) do
        if(self:GetChecked()) then
            v.trackonshow = "player";
        else
            v.trackonshow = nil;
        end
    end
end);

local alphaSlider = CreateSlider(BrowserPanel, "YatlasOptionsAlphaSlider", TWM_OPTIONS_ALPHA, .1, 1, .05);
alphaSlider:SetPoint("TOPLEFT", trackOnShowButton, "BOTTOMLEFT", 4, -32);
alphaSlider:SetScript("OnValueChanged", function(self)
    YatlasFrame:SetAlpha(self:GetValue());
    YatlasOptions.Frames["YatlasFrame"].Alpha = self:GetValue();
end);

local iconSizeSlider = CreateSlider(BrowserPanel, "YatlasOptionsIconSizeSlider", TWM_OPTIONS_ICONSIZE, 0.5, 3.0, 0.1);
iconSizeSlider:SetPoint("TOPLEFT", alphaSlider, "BOTTOMLEFT", 0, -32);
iconSizeSlider:SetScript("OnValueChanged", function(self)
    local v = self:GetValue();
    if(YatlasOptions.Frames["YatlasFrame"].IconSize ~= v) then
        YatlasOptions.Frames["YatlasFrame"].IconSize = v;
        YAPoints_Update(YatlasFrame);
    end
end);

local resetPositionButton = CreateFrame("Button", "YatlasOptionsResetPosition", BrowserPanel, "UIPanelButtonTemplate");
resetPositionButton:SetSize(160, 22);
resetPositionButton:SetPoint("TOPLEFT", iconSizeSlider, "BOTTOMLEFT", -4, -32);
resetPositionButton:SetText(TWM_OPTIONS_RESETPOSITION);
resetPositionButton:SetScript("OnClick", function()
    Yatlas_ResetFramePosition();
end);

function BrowserPanel.OnRefresh()
    local aframe = next(YatlasOptions.Frames);
    trackOnShowButton:SetChecked(aframe and YatlasOptions.Frames[aframe].trackonshow ~= nil);

    local opt = YatlasOptions.Frames["YatlasFrame"];
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
YatlasSettingsCategory = category;

local worldMapSubcategory = Settings.RegisterCanvasLayoutSubcategory(category, WorldMapPanel, WorldMapPanel.name);
worldMapSubcategory.ID = worldMapSubcategory.ID or WorldMapPanel.name;

local browserSubcategory = Settings.RegisterCanvasLayoutSubcategory(category, BrowserPanel, BrowserPanel.name);
browserSubcategory.ID = browserSubcategory.ID or BrowserPanel.name;

function YatlasOptions_Toggle()
    Settings.OpenToCategory(YatlasSettingsCategory.ID);
end
