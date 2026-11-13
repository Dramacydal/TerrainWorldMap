-- Raises the maximum zoom of the World Map and of the Battlefield Minimap (the map of the
-- Shift+M frame): extra zoom levels are appended to the map canvas' zoom levels, and the World
-- Map can reopen at the zoom and position it was closed with. (Formerly the WorldMapZoomMax addon.)
--
-- Options (Settings.lua, "World Map" tab), all in TWMOption:
--   WorldMapZoomIncrease  extra zoom levels on or off (default on)
--   WorldMapZoomLevel     the maximum zoom, as a multiple of the zoom at which the whole map fits
--                         the window (x1) -- default 8, 3..30 (the game's own maximum is lower)
--   WorldMapZoomRestore   reopen the World Map at the zoom and position it was closed with
--                         (default on; independent of the other two)

local DEFAULT_ZOOM_LEVEL = 8;
local MAX_EXTRA_LEVELS = 30;

-- Map frames to extend; both are load-on-demand in some clients, hooked once their frame exists.
local MAPS = {"WorldMapFrame", "BattlefieldMapFrame"};

local hooked = {};

function TWM_IsWorldMapZoomIncreased()
    return TWMOption.WorldMapZoomIncrease ~= false;
end

function TWM_GetWorldMapZoomLevel()
    return TWMOption.WorldMapZoomLevel or DEFAULT_ZOOM_LEVEL;
end

function TWM_IsWorldMapZoomRestored()
    return TWMOption.WorldMapZoomRestore ~= false;
end

-- Appends levels after the last Blizzard zoom level up to the chosen maximum, with the same step
-- ratio as Blizzard's last step. Runs on every CreateZoomLevels (the canvas builds the levels again
-- on a map or size change), so a level table is only ever extended once.
local function ExtendZoomLevels(container)
    local levels = container.zoomLevels;
    if(not levels or not TWM_IsWorldMapZoomIncreased() or container.twmZoomExtended == levels) then return; end
    container.twmZoomExtended = levels;

    local last = levels[#levels];
    local target = TWM_GetWorldMapZoomLevel() * container.baseScale;
    if(target <= last.scale) then return; end

    local prev = levels[#levels - 1];
    local stepFactor = prev and last.scale / prev.scale or 1.5;
    stepFactor = math.max(stepFactor, 1.1);
    local steps = math.min(math.ceil(math.log(target / last.scale) / math.log(stepFactor)), MAX_EXTRA_LEVELS);
    local factor = (target / last.scale) ^ (1 / steps);
    for i = 1, steps do
        levels[#levels + 1] = {scale = last.scale * factor ^ i, layerIndex = last.layerIndex};
    end
end

-- Builds the zoom levels of the hooked maps again (a setting changed).
local function RefreshZoomLevels()
    for _, name in ipairs(MAPS) do
        local container = hooked[name] and _G[name].ScrollContainer;
        if(container and container.mapID) then container:OnCanvasSizeChanged(); end
    end
end

function TWM_SetWorldMapZoomIncrease(enabled)
    TWMOption.WorldMapZoomIncrease = enabled;
    RefreshZoomLevels();
end

function TWM_SetWorldMapZoomLevel(level)
    TWMOption.WorldMapZoomLevel = level;
    RefreshZoomLevels();
end

-- World Map: zoom and position kept over a close and reopen.
local savedView; -- {mapID, ratio (scale / baseScale), x, y}
local restoreUntil = 0;

local function RestoreView()
    local view = savedView;
    if(not view or not WorldMapFrame:IsShown() or WorldMapFrame:GetMapID() ~= view.mapID) then return; end
    local container = WorldMapFrame.ScrollContainer;
    if(not container.zoomLevels) then return; end
    local scale = Clamp(view.ratio * container.baseScale, container:GetScaleForMinZoom(), container:GetScaleForMaxZoom());
    container:InstantPanAndZoom(scale, view.x, view.y, true);

    -- Forever's InstantPanAndZoom takes the pan as given (the 4th argument); the Classic clients' has no
    -- such argument and blends the pan with the current scroll by the ratio of the scales (it is meant
    -- for zooming towards a point), so the map would come back a little off and drift further with
    -- every close and reopen. Only where the pan did not come out as saved (Classic) the scroll is set
    -- exactly, the way InstantPanAndZoom ends.
    local x = Clamp(view.x, container.scrollXExtentsMin, container.scrollXExtentsMax);
    local y = Clamp(view.y, container.scrollYExtentsMin, container.scrollYExtentsMax);
    if(container.targetScrollX == x and container.targetScrollY == y) then return; end
    container.targetScrollX, container.targetScrollY = x, y;
    container.currentScrollX, container.currentScrollY = x, y;
    container:SetNormalizedHorizontalScroll(x);
    container:SetNormalizedVerticalScroll(y);
    container:MarkAreaTriggersDirty();
    container:MarkViewRectDirty();
end

local function SaveView()
    savedView = nil;
    if(not TWM_IsWorldMapZoomRestored()) then return; end
    local container = WorldMapFrame.ScrollContainer;
    if(not container.zoomLevels or container.targetScale <= container:GetScaleForMinZoom()) then return; end
    savedView = {
        mapID = WorldMapFrame:GetMapID(),
        ratio = container.targetScale / container.baseScale,
        x = container.targetScrollX,
        y = container.targetScrollY,
    };
end

function TWM_SetWorldMapZoomRestore(enabled)
    TWMOption.WorldMapZoomRestore = enabled;
    if(not enabled) then savedView = nil; end
end

local function SetupRestoreZoom()
    WorldMapFrame:HookScript("OnShow", function()
        RestoreView();
        restoreUntil = GetTime() + 0.5;
    end);
    WorldMapFrame:HookScript("OnHide", function()
        restoreUntil = 0;
        SaveView();
    end);
    -- Applied again if the frame is resized right after opening (maximize/minimize resets the zoom).
    hooksecurefunc(WorldMapFrame.ScrollContainer, "ResetZoom", function()
        if(GetTime() < restoreUntil) then RestoreView(); end
    end);
end

-- Mouse wheel on the World Map. The Classic clients (Era, Anniversary, Mists) switch it off in the
-- World Map's XML (the scroll container's OnMouseWheel is `nop`: "Disable mouse wheel scrolling"),
-- so the map has zoom levels but nothing ever uses them; Forever's map zooms with the wheel as
-- the stock map canvas does. The container's wheel script is wrapped: the original runs, and a
-- frame later, if nothing zoomed the map meanwhile (the stock handler moves targetScale, or
-- currentScale when zooming instantly; the hooks other addons put on the wheel -- Leatrix Maps
-- zooms the same way -- have all run by then, so a notch is never taken twice), the map goes one
-- zoom level in or out at the cursor.
local function SetupWheelZoom(container)
    local original = container:GetScript("OnMouseWheel");
    container:SetScript("OnMouseWheel", function(self, delta)
        local targetBefore, currentBefore = self.targetScale, self.currentScale;
        if(original) then original(self, delta); end
        local x, y = self:GetNormalizedCursorPosition();

        C_Timer.After(0, function()
            if(self.targetScale ~= targetBefore or self.currentScale ~= currentBefore or not self.zoomLevels) then return; end

            local nextZoomOutScale, nextZoomInScale = self:GetCurrentZoomRange();
            local scale = self:GetCanvasScale();
            if(delta > 0) then
                if(nextZoomInScale > scale) then self:InstantPanAndZoom(nextZoomInScale, x or 0.5, y or 0.5); end
            else
                if(nextZoomOutScale < scale) then self:InstantPanAndZoom(nextZoomOutScale, x or 0.5, y or 0.5); end
            end
        end);
    end);
end

local function Setup()
    for _, name in ipairs(MAPS) do
        local frame = _G[name];
        local container = frame and frame.ScrollContainer;
        if(container and not hooked[name]) then
            hooked[name] = true;
            hooksecurefunc(container, "CreateZoomLevels", ExtendZoomLevels);
            ExtendZoomLevels(container);
            if(name == "WorldMapFrame") then
                SetupRestoreZoom();
                SetupWheelZoom(container);
            end
        end
    end
end

local function AllHooked()
    for _, name in ipairs(MAPS) do
        if(not hooked[name]) then return false; end
    end
    return true;
end

local eventFrame = CreateFrame("Frame");
eventFrame:RegisterEvent("ADDON_LOADED");
eventFrame:RegisterEvent("PLAYER_LOGIN");
eventFrame:SetScript("OnEvent", function(self, event)
    Setup();
    if(event == "PLAYER_LOGIN") then
        -- The saved settings are in TWMOption by now: levels built earlier with the defaults are built again.
        RefreshZoomLevels();
    end
    if(AllHooked()) then self:UnregisterEvent("ADDON_LOADED"); end
end);
