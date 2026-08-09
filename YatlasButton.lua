local LDB = LibStub("LibDataBroker-1.1");
local icon = LibStub("LibDBIcon-1.0");

local YatlasLDB = LDB:NewDataObject("Yatlas", {
    type = "launcher",
    icon = "Interface\\AddOns\\Yatlas\\images\\Button",
    OnClick = function(self, button)
        YatlasFrame:Toggle();
    end,
    OnTooltipShow = function(tooltip)
        tooltip:AddLine(YATLAS_BUTTON_TOOLTIP1);
        tooltip:AddLine(YATLAS_BUTTON_TOOLTIP2);
        tooltip:AddLine(YATLAS_BUTTON_TOOLTIP3);
    end,
});

function YatlasButton_Update()
    if(YatlasOptions.ShowButton) then
        icon:Show("Yatlas");
    else
        icon:Hide("Yatlas");
    end
end

local buttonframe = CreateFrame("Frame");
buttonframe:RegisterEvent("VARIABLES_LOADED");
buttonframe:SetScript("OnEvent", function(self, event, ...)
    if(YatlasOptions.MinimapButton == nil) then
        YatlasOptions.MinimapButton = {};
    end

    icon:Register("Yatlas", YatlasLDB, YatlasOptions.MinimapButton);
    YatlasButton_Update();
end);
