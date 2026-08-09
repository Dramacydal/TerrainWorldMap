local LDB = LibStub("LibDataBroker-1.1");
local icon = LibStub("LibDBIcon-1.0");

local YatlasLDB = LDB:NewDataObject("Yatlas", {
    type = "launcher",
    icon = "Interface\\AddOns\\Yatlas\\images\\Button",
    OnClick = function(self, button)
        if(button == "RightButton") then
            MenuUtil.CreateContextMenu(self, function(owner, rootDescription)
                rootDescription:CreateButton("Open Yatlas", function()
                    YatlasFrame:Toggle();
                end);
                rootDescription:CreateCheckbox("Draw child-map tiles",
                    Yatlas_IsChildMapTilesEnabled,
                    function() Yatlas_SetChildMapTiles(not Yatlas_IsChildMapTilesEnabled()); end);
                rootDescription:CreateCheckbox("Draw tiles on Azeroth (world) map",
                    Yatlas_IsWorldViewTilesEnabled,
                    function() Yatlas_SetWorldViewTiles(not Yatlas_IsWorldViewTilesEnabled()); end);
            end);
        else
            YatlasFrame:Toggle();
        end
    end,
    OnTooltipShow = function(tooltip)
        tooltip:AddLine(YATLAS_BUTTON_TOOLTIP1, 1, 1, 1);
        tooltip:AddLine("|cff40ff40Left-click|r: open Yatlas");
        tooltip:AddLine("|cff40ff40Right-click|r: menu");
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
