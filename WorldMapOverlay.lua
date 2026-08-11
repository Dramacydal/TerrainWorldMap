-- Overlays TerrainWorldMap's own baked minimap tile mosaic (World\Minimaps\<continent>\
-- mapXX_YY.blp, gated by Twm_WDTValidTiles ground truth) onto the stock
-- WorldMapFrame (opened with "M"), as an alternative to Blizzard's "painted"
-- continent/zone art -- for continents TerrainWorldMap knows about (Azeroth/Kalimdor/
-- Expansion01), at whatever zoom level (continent or zone) is shown.
--
-- Sits on its own frame parented to WorldMapFrame's canvas (WorldMapFrame:
-- GetCanvas(), i.e. WorldMapFrame.ScrollContainer.Child) so it automatically
-- pans/zooms in lockstep with the rest of the map. FrameLevel is set well
-- above the base map art (drawn BACKGROUND-layer, effectively level ~0) and
-- well below every POI/pin (MapCanvasPinFrameLevelsManagerMixin starts pins
-- at frame level 2000), so it renders strictly between the two.
--
-- Toggle with "/twm map on" / "/twm map off".

local pre = "World\\Minimaps\\";

local overlay;
local backdrop;
local texturePool = {};
local worldMapButton;

local function GetOverlayFrame()
    if(overlay) then return overlay; end

    overlay = CreateFrame("Frame", "TWMWorldMapOverlay", WorldMapFrame:GetCanvas());
    overlay:SetAllPoints(WorldMapFrame:GetCanvas());
    overlay:SetFrameLevel(500);
    overlay:Hide();

    -- Solid backing under every tile, so gaps (ocean/edge cells with no
    -- WDT-valid tile, or areas not yet covered by an inset) show black
    -- instead of Blizzard's own map art bleeding through from below. Only
    -- meaningful on zone/continent maps -- hidden on the cosmic map (see
    -- RefreshOverlay), which we never have tiles for anyway.
    backdrop = overlay:CreateTexture(nil, "BACKGROUND");
    backdrop:SetAllPoints(overlay);
    backdrop:SetColorTexture(0, 0, 0, 1);

    return overlay;
end

local function AcquireTexture(i)
    local tex = texturePool[i];
    if(not tex) then
        tex = overlay:CreateTexture(nil, "ARTWORK");
        tex:SetSnapToPixelGrid(false);
        tex:SetTexelSnappingBias(0);
        texturePool[i] = tex;
    end
    return tex;
end

local function ReleaseTexturesFrom(fromIndex)
    for i = fromIndex, #texturePool do
        texturePool[i]:Hide();
    end
end

local function ShowExplorationPins()
    for pin in WorldMapFrame:EnumeratePinsByTemplate("MapExplorationPinTemplate") do
        pin:Show();
    end
end

-- Big-coord bounding box of the currently displayed map, plus which
-- continent's tile mosaic it should be drawn from. Three sources, in
-- priority order:
--
-- 1. Twm_UiMapID2Zone (mapdata_continents.lua, generated from the same
--    UiMapAssignment DBC rows as the zone boxes) -- ground truth. Needed
--    because a handful of zones (Draenei/Blood Elf starting isles) are
--    filed under a *different* continent's DBC MapID than where C_Map's
--    own uiMap hierarchy nominally parents them: Eversong Woods is a
--    "child" of Eastern Kingdoms in C_Map's tree for world-map navigation
--    (Blizzard draws a compressed inset icon for it near Tirisfal), but
--    its real UiMapAssignment row -- and its real WDT terrain -- is filed
--    under Expansion01/Outland, exactly like the original hand-collected
--    Yatlas data already had it.
-- 2. mapID is itself one of our 3 known continents.
-- 3. C_Map.GetMapRectOnMap against each known continent -- a geometric
--    guess for ordinary zones we don't have a UiMapAssignment box for.
--    Not reliable for zones covered by case 1 (see above), which is why
--    that lookup takes priority over this one.
local function GetViewBigBox(mapID)
    local known = Twm_UiMapID2Zone[mapID];
    if(known) then
        local box = Twm_mapareas[known[1]][known[2]];
        if(box) then return known[1], box[1], box[2], box[3], box[4]; end
    end

    for continent, continentMapID in pairs(Twm_ContinentMapID) do
        if(mapID == continentMapID) then
            local box = Twm_mapareas[continent][0];
            return continent, box[1], box[2], box[3], box[4];
        end
    end

    local hint = TWM_GetContinentForMapID(mapID);
    local tryOrder = {};
    if(hint) then table.insert(tryOrder, hint); end
    for continent in pairs(Twm_ContinentMapID) do
        if(continent ~= hint) then table.insert(tryOrder, continent); end
    end

    for _, continent in ipairs(tryOrder) do
        local left, right, top, bottom = C_Map.GetMapRectOnMap(mapID, Twm_ContinentMapID[continent]);
        -- GetMapRectOnMap can return a degenerate {0,0,0,0} (not nil) for a
        -- map that isn't really geometrically related to this continent --
        -- e.g. the "both continents"/cosmic zoom-out views -- and 0 is
        -- truthy in Lua, so require an actual positive-area rect.
        if(left and right > left and bottom > top) then
            local cbox = Twm_mapareas[continent][0];
            local cx1,cx2,cy1,cy2 = cbox[1],cbox[2],cbox[3],cbox[4];
            local bx1, by1 = (-left*(cx1-cx2) + cx1), (-top*(cy1-cy2) + cy1);
            local bx2, by2 = (-right*(cx1-cx2) + cx1), (-bottom*(cy1-cy2) + cy1);
            return continent, bx1, bx2, by1, by2;
        end
    end

    return nil;
end

-- Draws `continent`'s tiles covering Big-coord box [bx1,bx2]x[by1,by2] into
-- the pixel rect [targetX1,targetX2]x[targetY1,targetY2] of `overlay`,
-- clipping (via SetTexCoord) any tile that only partially overlaps the
-- target rect -- needed so an inset (see below) doesn't bleed its tiles
-- past its own box into the surrounding continent art. Numbers new
-- textures starting at startIdx+1; returns the last index used. `sublevel`
-- (within the ARTWORK layer) controls draw order among overlapping calls --
-- higher draws on top -- since insets must render over the main continent
-- tiles wherever they happen to overlap.
local function DrawTiles(continent, bx1, bx2, by1, by2, targetX1, targetY1, targetX2, targetY2, startIdx, sublevel)
    if(not Twm_WDTValidTiles[continent]) then return startIdx; end

    local mnx1, mny1 = TWM_Big2Mini_Coord(bx1, by1);
    local mnx2, mny2 = TWM_Big2Mini_Coord(bx2, by2);
    local colMin = math.floor(math.min(mnx1, mnx2));
    local colMax = math.ceil(math.max(mnx1, mnx2));
    local rowMin = math.floor(math.min(mny1, mny2));
    local rowMax = math.ceil(math.max(mny1, mny2));

    local targetW, targetH = targetX2-targetX1, targetY2-targetY1;
    local function BigToTargetPixel(bigx, bigy)
        return targetX1 + ((bx1-bigx)/(bx1-bx2))*targetW, targetY1 + ((by1-bigy)/(by1-by2))*targetH;
    end

    local idx = startIdx;
    for col = colMin, colMax - 1 do
        for row = rowMin, rowMax - 1 do
            local tilekey = format("%.2dx%.2d", col, row);
            if(Twm_WDTValidTiles[continent][tilekey]) then
                local px1, py1 = BigToTargetPixel(TWM_Mini2Big_Coord(col, row));
                local px2, py2 = BigToTargetPixel(TWM_Mini2Big_Coord(col+1, row+1));

                local tx1, tx2 = math.min(px1,px2), math.max(px1,px2);
                local ty1, ty2 = math.min(py1,py2), math.max(py1,py2);

                local ix1, ix2 = math.max(tx1, targetX1), math.min(tx2, targetX2);
                local iy1, iy2 = math.max(ty1, targetY1), math.min(ty2, targetY2);

                if(ix2 > ix1 and iy2 > iy1) then
                    idx = idx + 1;
                    local tex = AcquireTexture(idx);
                    tex:ClearAllPoints();
                    tex:SetDrawLayer("ARTWORK", sublevel or 0);
                    tex:SetPoint("TOPLEFT", overlay, "TOPLEFT", ix1, -iy1);
                    tex:SetWidth(ix2-ix1);
                    tex:SetHeight(iy2-iy1);
                    tex:SetTexture(pre..continent.."\\"..TWM_GetTileFileName(continent, col, row));
                    tex:SetTexCoord((ix1-tx1)/(tx2-tx1), (ix2-tx1)/(tx2-tx1), (iy1-ty1)/(ty2-ty1), (iy2-ty1)/(ty2-ty1));
                    tex:Show();
                end
            end
        end
    end

    return idx;
end

local function RefreshOverlay()
    if(not overlay or not overlay:IsShown()) then return; end

    local mapID = WorldMapFrame:GetMapID();
    if(not mapID) then
        ReleaseTexturesFrom(1);
        backdrop:Hide();
        ShowExplorationPins();
        return;
    end

    local frameW, frameH = overlay:GetWidth(), overlay:GetHeight();
    if(not frameW or frameW == 0 or not frameH or frameH == 0) then
        return;
    end

    -- Big-coord box of the current view: bx1/by1 = max X/Y, bx2/by2 = min
    -- X/Y, matching Twm_mapareas' own {x1,x2,y1,y2} convention. Also nil
    -- on "world" maps that group whole continents together (the "Azeroth"
    -- map showing Kalimdor + Eastern Kingdoms side by side, or the true
    -- cosmic map above that) -- those aren't themselves on any one
    -- continent's tile mosaic, so they're handled separately below.
    local continent, bx1, bx2, by1, by2 = GetViewBigBox(mapID);

    -- Capital city maps (Stormwind, Orgrimmar, etc.) aren't covered by the
    -- minimap tile mosaic at a useful scale/detail -- off by default,
    -- opt-in only. Twm_CityMapIDs is a hand-collected list (see
    -- mapdata_zones.lua) since Blizzard's map hierarchy gives no
    -- type/parent-based way to tell a city map apart from a real zone.
    if(continent and Twm_CityMapIDs[mapID] and not TWMOption.WorldMapOverlayCityMaps) then
        continent = nil;
    end

    local idx = 0;

    if(continent) then
        -- Blizzard's "explored area" pin (and Leatrix_Maps' "Show
        -- unexplored areas" option, which forces it to paint even
        -- normally-unrevealed tiles) draws its own painted map art at
        -- frame level ~2001, above our overlay (500) by design -- it would
        -- otherwise show through on top of our baked tiles wherever the
        -- player has explored. Since we're replacing Blizzard's art
        -- entirely for this map, suppress it.
        for pin in WorldMapFrame:EnumeratePinsByTemplate("MapExplorationPinTemplate") do
            pin:Hide();
        end
        backdrop:Show();

        idx = DrawTiles(continent, bx1, bx2, by1, by2, 0, 0, frameW, frameH, idx);

        -- Continent-level view: also draw any "orphan" zones that C_Map's
        -- own hierarchy nominally parents here, but whose real terrain (per
        -- Twm_UiMapID2Zone) lives on a *different* continent -- e.g.
        -- Eversong Woods/Ghostlands/Isle of Quel'Danas under Eastern
        -- Kingdoms, Azuremyst/Bloodmyst Isle under Kalimdor.
        --
        -- Grouped by foreign continent, with ONE shared transform per group
        -- (union of the zones' real boxes -> union of Blizzard's own inset
        -- rects for them), not one transform per zone: Blizzard picks each
        -- zone's inset box independently for its own little map icon, so
        -- fitting them independently would drift neighbouring zones (e.g.
        -- Eversong Woods and Isle of Quel'Danas) apart even though their
        -- real coordinates are adjacent.
        if(TWMOption.WorldMapOverlayChildMaps and mapID == Twm_ContinentMapID[continent]) then
            local groups = {};
            for _, childInfo in ipairs(C_Map.GetMapChildrenInfo(mapID) or {}) do
                local known = Twm_UiMapID2Zone[childInfo.mapID];
                if(known and known[1] ~= continent) then
                    local left, right, top, bottom = C_Map.GetMapRectOnMap(childInfo.mapID, mapID);
                    local box = left and Twm_mapareas[known[1]][known[2]];
                    if(box) then
                        local g = groups[known[1]];
                        if(not g) then
                            groups[known[1]] = { bx1=box[1], bx2=box[2], by1=box[3], by2=box[4],
                                left=left, right=right, top=top, bottom=bottom };
                        else
                            g.bx1 = math.max(g.bx1, box[1]);
                            g.bx2 = math.min(g.bx2, box[2]);
                            g.by1 = math.max(g.by1, box[3]);
                            g.by2 = math.min(g.by2, box[4]);
                            g.left = math.min(g.left, left);
                            g.right = math.max(g.right, right);
                            g.top = math.min(g.top, top);
                            g.bottom = math.max(g.bottom, bottom);
                        end
                    end
                end
            end

            for foreignContinent, g in pairs(groups) do
                idx = DrawTiles(foreignContinent, g.bx1, g.bx2, g.by1, g.by2,
                    g.left*frameW, g.top*frameH, g.right*frameW, g.bottom*frameH, idx, 1);
            end
        end
    else
        -- "World" view grouping whole continents together (e.g. the
        -- "Azeroth" map showing Kalimdor + Eastern Kingdoms side by side):
        -- draw each known continent that's a direct child here into its own
        -- rect, same GetMapRectOnMap-based placement mechanism as the
        -- orphan zones above, just one level up. Explicitly NOT the true
        -- cosmic map one level further out -- Expansion01 (and others) can
        -- show up as a direct child there too, which would draw Outland
        -- floating in space with no matching "whole world" layout for it.
        local mapInfo = C_Map.GetMapInfo(mapID);
        if(TWMOption.WorldMapOverlayWorldView and mapInfo and mapInfo.mapType == Enum.UIMapType.World) then
            for _, childInfo in ipairs(C_Map.GetMapChildrenInfo(mapID) or {}) do
                for childContinent, childContinentMapID in pairs(Twm_ContinentMapID) do
                    if(childInfo.mapID == childContinentMapID) then
                        local left, right, top, bottom = C_Map.GetMapRectOnMap(childContinentMapID, mapID);
                        if(left and right > left and bottom > top) then
                            local box = Twm_mapareas[childContinent][0];
                            idx = DrawTiles(childContinent, box[1], box[2], box[3], box[4],
                                left*frameW, top*frameH, right*frameW, bottom*frameH, idx, 0);
                        end
                    end
                end
            end
        end

        if(idx > 0) then
            for pin in WorldMapFrame:EnumeratePinsByTemplate("MapExplorationPinTemplate") do
                pin:Hide();
            end
            backdrop:Show();
        else
            backdrop:Hide();
            ShowExplorationPins();
        end
    end

    ReleaseTexturesFrom(idx+1);
end

function TWM_SetWorldMapOverlay(enabled, silent)
    TWMOption.WorldMapOverlay = enabled;

    local f = GetOverlayFrame();
    if(enabled) then
        f:Show();
        RefreshOverlay();
    else
        f:Hide();
        ShowExplorationPins();
    end

    if(worldMapButton) then
        worldMapButton:Refresh();
    end

    if(not silent) then
        print(enabled and TWM_WORLDMAP_OVERLAY_ON or TWM_WORLDMAP_OVERLAY_OFF);
    end
end

function TWM_IsWorldMapOverlayEnabled()
    return TWMOption.WorldMapOverlay;
end

function TWM_SetChildMapTiles(enabled)
    TWMOption.WorldMapOverlayChildMaps = enabled;
    RefreshOverlay();
end

function TWM_IsChildMapTilesEnabled()
    return TWMOption.WorldMapOverlayChildMaps;
end

-- Off by default: drawing every visible tile of both continents at once
-- (the "Azeroth" world view) is noticeably heavier than a single
-- continent/zone view.
function TWM_SetWorldViewTiles(enabled)
    TWMOption.WorldMapOverlayWorldView = enabled;
    RefreshOverlay();
end

function TWM_IsWorldViewTilesEnabled()
    return TWMOption.WorldMapOverlayWorldView;
end

-- Off by default: city maps aren't covered by the minimap tile mosaic at a
-- useful scale/detail.
function TWM_SetCityMapTiles(enabled)
    TWMOption.WorldMapOverlayCityMaps = enabled;
    RefreshOverlay();
end

function TWM_IsCityMapTilesEnabled()
    return TWMOption.WorldMapOverlayCityMaps;
end

-- On by default (see TerrainWorldMap.lua's VARIABLES_LOADED handler) -- only
-- ever surfaced (Settings.lua checkbox, this file's and
-- TerrainWorldMapButton.lua's right-click menus) when TWM_HasNoLiquidData()
-- is true, i.e. this flavor's data was actually generated with a minimaps
-- dir (see scripts/parse_wdt.js) and found at least one noLiquid tile
-- somewhere. Flavors without that data never show this option at all.
function TWM_SetDrawUnderwater(enabled)
    TWMOption.DrawUnderwater = enabled;
    RefreshOverlay();
    TWM_RefreshFrameTiles();
end

function TWM_IsDrawUnderwaterEnabled()
    return TWMOption.DrawUnderwater;
end

-- Icon on the stock WorldMapFrame (see WorldMapButton.xml): left-click
-- toggles this overlay, right-click opens a context menu (open TerrainWorldMap /
-- toggle child-map tiles), same as the minimap button (TWMButton.lua).
TWMWorldMapButtonMixin = {};

function TWMWorldMapButtonMixin:OnLoad()
    self:RegisterForClicks("LeftButtonUp", "RightButtonUp");
    self:Refresh();
end

function TWMWorldMapButtonMixin:OnEnter()
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
    GameTooltip:SetText(TWM_BUTTON_TOOLTIP1, 1, 1, 1);
    GameTooltip:AddLine(TWM_IsWorldMapOverlayEnabled()
        and TWM_TOOLTIP_LEFTCLICK_OVERLAY_OFF
        or  TWM_TOOLTIP_LEFTCLICK_OVERLAY_ON);
    GameTooltip:AddLine(TWM_TOOLTIP_RIGHTCLICK_MENU);
    GameTooltip:Show();
end

function TWMWorldMapButtonMixin:OnLeave()
    GameTooltip:Hide();
end

function TWMWorldMapButtonMixin:OnClick(button)
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
        TWM_SetWorldMapOverlay(not TWM_IsWorldMapOverlayEnabled(), true);
    end
    self:Refresh();
end

function TWMWorldMapButtonMixin:Refresh()
    local enabled = TWM_IsWorldMapOverlayEnabled();
    self.Icon:SetDesaturated(not enabled);
    self.Icon:SetAlpha(enabled and 1 or 0.5);
end

local initFrame = CreateFrame("Frame");
initFrame:RegisterEvent("PLAYER_LOGIN");
initFrame:SetScript("OnEvent", function()
    if(TWMOption.WorldMapOverlay == nil) then
        TWMOption.WorldMapOverlay = true;
    end
    if(TWMOption.WorldMapOverlayChildMaps == nil) then
        TWMOption.WorldMapOverlayChildMaps = true;
    end
    if(TWMOption.WorldMapOverlayWorldView == nil) then
        TWMOption.WorldMapOverlayWorldView = false;
    end
    if(TWMOption.WorldMapOverlayCityMaps == nil) then
        TWMOption.WorldMapOverlayCityMaps = false;
    end

    GetOverlayFrame();

    hooksecurefunc(WorldMapFrame, "OnMapChanged", RefreshOverlay);
    WorldMapFrame:HookScript("OnShow", RefreshOverlay);

    if(TWMOption.WorldMapOverlay) then
        overlay:Show();
        RefreshOverlay();
    end

    worldMapButton = LibStub("Krowi_WorldMapButtons-1.4"):Add("TWMWorldMapButtonTemplate", "BUTTON");
    worldMapButton:Show();
end);
