-- Native Blizzard AddOn settings panel (Interface Options), replaces the old standalone YatlasOptionsFrame.

local Panel = CreateFrame("Frame");
Panel.name = YATLAS_OPTIONS_TITLE;

local title = Panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge");
title:SetPoint("TOPLEFT", 16, -16);
title:SetText(YATLAS_OPTIONS_TITLE);

local enableButton = CreateFrame("CheckButton", "YatlasOptionsButtonEnable", Panel, "UICheckButtonTemplate");
enableButton:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -24);
local enableButtonLabel = enableButton:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
enableButtonLabel:SetJustifyH("LEFT");
enableButtonLabel:SetSize(275, 16);
enableButtonLabel:SetPoint("LEFT", enableButton, "RIGHT", 0, 0);
enableButtonLabel:SetText(YATLAS_OPTIONS_ENABLEBUTTON);
enableButton:SetScript("OnClick", function(self)
    YatlasOptions.ShowButton = self:GetChecked() and true or false;
    YatlasButton_Update();
end);

local trackOnShowButton = CreateFrame("CheckButton", "YatlasOptionsTrackOnShow", Panel, "UICheckButtonTemplate");
trackOnShowButton:SetPoint("TOPLEFT", enableButton, "BOTTOMLEFT", 0, -12);
local trackOnShowLabel = trackOnShowButton:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
trackOnShowLabel:SetJustifyH("LEFT");
trackOnShowLabel:SetSize(275, 16);
trackOnShowLabel:SetPoint("LEFT", trackOnShowButton, "RIGHT", 0, 0);
trackOnShowLabel:SetText(YATLAS_OPTIONS_TRACKONSHOW);
trackOnShowButton:SetScript("OnClick", function(self)
    for h,v in pairs(YatlasOptions.Frames) do
        if(self:GetChecked()) then
            v.trackonshow = "player";
        else
            v.trackonshow = nil;
        end
    end
end);

local alphaSlider = CreateFrame("Slider", "YatlasOptionsAlphaSlider", Panel, "OptionsSliderTemplate");
alphaSlider:SetSize(180, 16);
alphaSlider:SetPoint("TOPLEFT", trackOnShowButton, "BOTTOMLEFT", 4, -32);
_G[alphaSlider:GetName().."Text"]:SetText(YATLAS_OPTIONS_ALPHA);
_G[alphaSlider:GetName().."High"]:SetText();
_G[alphaSlider:GetName().."Low"]:SetText();
alphaSlider:SetMinMaxValues(.1, 1);
alphaSlider:SetValueStep(.05);
alphaSlider:SetScript("OnValueChanged", function(self)
    YatlasFrame:SetAlpha(self:GetValue());
    YatlasOptions.Frames["YatlasFrame"].Alpha = self:GetValue();
end);

local iconSizeSlider = CreateFrame("Slider", "YatlasOptionsIconSizeSlider", Panel, "OptionsSliderTemplate");
iconSizeSlider:SetSize(180, 16);
iconSizeSlider:SetPoint("TOPLEFT", alphaSlider, "BOTTOMLEFT", 0, -32);
_G[iconSizeSlider:GetName().."Text"]:SetText(YATLAS_OPTIONS_ICONSIZE);
_G[iconSizeSlider:GetName().."High"]:SetText();
_G[iconSizeSlider:GetName().."Low"]:SetText();
iconSizeSlider:SetMinMaxValues(0.5, 3.0);
iconSizeSlider:SetValueStep(0.1);
iconSizeSlider:SetScript("OnValueChanged", function(self)
    local v = self:GetValue();
    if(YatlasOptions.Frames["YatlasFrame"].IconSize ~= v) then
        YatlasOptions.Frames["YatlasFrame"].IconSize = v;
        YAPoints_Update(YatlasFrame);
    end
end);

local childMapTilesButton = CreateFrame("CheckButton", "YatlasOptionsChildMapTiles", Panel, "UICheckButtonTemplate");
childMapTilesButton:SetPoint("TOPLEFT", iconSizeSlider, "BOTTOMLEFT", -4, -32);
local childMapTilesLabel = childMapTilesButton:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
childMapTilesLabel:SetJustifyH("LEFT");
childMapTilesLabel:SetSize(275, 16);
childMapTilesLabel:SetPoint("LEFT", childMapTilesButton, "RIGHT", 0, 0);
childMapTilesLabel:SetText(YATLAS_MENU_CHILDMAP_TILES);
childMapTilesButton:SetScript("OnClick", function(self)
    Yatlas_SetChildMapTiles(self:GetChecked() and true or false);
end);

local worldViewTilesButton = CreateFrame("CheckButton", "YatlasOptionsWorldViewTiles", Panel, "UICheckButtonTemplate");
worldViewTilesButton:SetPoint("TOPLEFT", childMapTilesButton, "BOTTOMLEFT", 0, -12);
local worldViewTilesLabel = worldViewTilesButton:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
worldViewTilesLabel:SetJustifyH("LEFT");
worldViewTilesLabel:SetSize(275, 16);
worldViewTilesLabel:SetPoint("LEFT", worldViewTilesButton, "RIGHT", 0, 0);
worldViewTilesLabel:SetText(YATLAS_MENU_WORLDVIEW_TILES);
worldViewTilesButton:SetScript("OnClick", function(self)
    Yatlas_SetWorldViewTiles(self:GetChecked() and true or false);
end);

function Panel.OnRefresh()
    enableButton:SetChecked(YatlasOptions.ShowButton);

    local aframe = next(YatlasOptions.Frames);
    trackOnShowButton:SetChecked(aframe and YatlasOptions.Frames[aframe].trackonshow ~= nil);

    local opt = YatlasOptions.Frames["YatlasFrame"];
    if(opt) then
        alphaSlider:SetValue(opt.Alpha);
        iconSizeSlider:SetValue(opt.IconSize);
    end

    childMapTilesButton:SetChecked(Yatlas_IsChildMapTilesEnabled());
    worldViewTilesButton:SetChecked(Yatlas_IsWorldViewTilesEnabled());
end

local category = Settings.RegisterCanvasLayoutCategory(Panel, Panel.name);
category.ID = category.ID or Panel.name;
Settings.RegisterAddOnCategory(category);
YatlasSettingsCategory = category;

function YatlasOptions_Toggle()
    Settings.OpenToCategory(YatlasSettingsCategory.ID);
end
