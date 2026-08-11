local LDB = LibStub("LibDataBroker-1.1");
local icon = LibStub("LibDBIcon-1.0");

local TWMLDB = LDB:NewDataObject("TerrainWorldMap", {
    type = "launcher",
    icon = "Interface\\AddOns\\TerrainWorldMap\\images\\Button",
    OnClick = function(self, button)
        if(button == "RightButton") then
            MenuUtil.CreateContextMenu(self, function(owner, rootDescription)
                rootDescription:CreateButton(TWM_MENU_OPEN, function()
                    TWMFrame:Toggle();
                end);
                rootDescription:CreateButton(TWM_MENU_SETTINGS, function()
                    TWMOption_Toggle();
                end);
                rootDescription:CreateCheckbox(TWM_MENU_CHILDMAP_TILES,
                    TWM_IsChildMapTilesEnabled,
                    function() TWM_SetChildMapTiles(not TWM_IsChildMapTilesEnabled()); end);
                rootDescription:CreateCheckbox(TWM_MENU_WORLDVIEW_TILES,
                    TWM_IsWorldViewTilesEnabled,
                    function() TWM_SetWorldViewTiles(not TWM_IsWorldViewTilesEnabled()); end);
                rootDescription:CreateCheckbox(TWM_MENU_CITYMAP_TILES,
                    TWM_IsCityMapTilesEnabled,
                    function() TWM_SetCityMapTiles(not TWM_IsCityMapTilesEnabled()); end);
                if(TWM_HasNoLiquidData()) then
                    rootDescription:CreateCheckbox(TWM_MENU_DRAW_UNDERWATER,
                        TWM_IsDrawUnderwaterEnabled,
                        function() TWM_SetDrawUnderwater(not TWM_IsDrawUnderwaterEnabled()); end);
                end
            end);
        else
            TWMFrame:Toggle();
        end
    end,
    OnTooltipShow = function(tooltip)
        tooltip:AddLine(TWM_BUTTON_TOOLTIP1, 1, 1, 1);
        tooltip:AddLine(TWM_TOOLTIP_LEFTCLICK_OPEN);
        tooltip:AddLine(TWM_TOOLTIP_RIGHTCLICK_MENU);
    end,
});

function TWMButton_Update()
    if(TWMOption.ShowButton) then
        icon:Show("TerrainWorldMap");
    else
        icon:Hide("TerrainWorldMap");
    end
end

local buttonframe = CreateFrame("Frame");
buttonframe:RegisterEvent("VARIABLES_LOADED");
buttonframe:SetScript("OnEvent", function(self, event, ...)
    if(TWMOption.MinimapButton == nil) then
        TWMOption.MinimapButton = {};
    end

    icon:Register("TerrainWorldMap", TWMLDB, TWMOption.MinimapButton);
    TWMButton_Update();
end);
