local LDB = LibStub("LibDataBroker-1.1");
local icon = LibStub("LibDBIcon-1.0");

local YatlasLDB = LDB:NewDataObject("TerrainWorldMap", {
    type = "launcher",
    icon = "Interface\\AddOns\\Yatlas\\images\\Button",
    OnClick = function(self, button)
        if(button == "RightButton") then
            MenuUtil.CreateContextMenu(self, function(owner, rootDescription)
                rootDescription:CreateButton(YATLAS_MENU_OPEN, function()
                    YatlasFrame:Toggle();
                end);
                rootDescription:CreateButton(YATLAS_MENU_SETTINGS, function()
                    YatlasOptions_Toggle();
                end);
                rootDescription:CreateCheckbox(YATLAS_MENU_CHILDMAP_TILES,
                    Yatlas_IsChildMapTilesEnabled,
                    function() Yatlas_SetChildMapTiles(not Yatlas_IsChildMapTilesEnabled()); end);
                rootDescription:CreateCheckbox(YATLAS_MENU_WORLDVIEW_TILES,
                    Yatlas_IsWorldViewTilesEnabled,
                    function() Yatlas_SetWorldViewTiles(not Yatlas_IsWorldViewTilesEnabled()); end);
                rootDescription:CreateCheckbox(YATLAS_MENU_CITYMAP_TILES,
                    Yatlas_IsCityMapTilesEnabled,
                    function() Yatlas_SetCityMapTiles(not Yatlas_IsCityMapTilesEnabled()); end);
            end);
        else
            YatlasFrame:Toggle();
        end
    end,
    OnTooltipShow = function(tooltip)
        tooltip:AddLine(YATLAS_BUTTON_TOOLTIP1, 1, 1, 1);
        tooltip:AddLine(YATLAS_TOOLTIP_LEFTCLICK_OPEN);
        tooltip:AddLine(YATLAS_TOOLTIP_RIGHTCLICK_MENU);
    end,
});

function YatlasButton_Update()
    if(YatlasOptions.ShowButton) then
        icon:Show("TerrainWorldMap");
    else
        icon:Hide("TerrainWorldMap");
    end
end

local buttonframe = CreateFrame("Frame");
buttonframe:RegisterEvent("VARIABLES_LOADED");
buttonframe:SetScript("OnEvent", function(self, event, ...)
    if(YatlasOptions.MinimapButton == nil) then
        YatlasOptions.MinimapButton = {};
    end

    icon:Register("TerrainWorldMap", YatlasLDB, YatlasOptions.MinimapButton);
    YatlasButton_Update();
end);
