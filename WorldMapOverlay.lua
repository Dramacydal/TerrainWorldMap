-- Overlays Yatlas's own baked minimap tile mosaic (World\Minimaps\<continent>\
-- mapXX_YY.blp, gated by Yatlas_WDTValidTiles ground truth) onto the stock
-- WorldMapFrame (opened with "M"), as an alternative to Blizzard's "painted"
-- continent/zone art -- for continents Yatlas knows about (Azeroth/Kalimdor/
-- Expansion01), at whatever zoom level (continent or zone) is shown.
--
-- Sits on its own frame parented to WorldMapFrame's canvas (WorldMapFrame:
-- GetCanvas(), i.e. WorldMapFrame.ScrollContainer.Child) so it automatically
-- pans/zooms in lockstep with the rest of the map. FrameLevel is set well
-- above the base map art (drawn BACKGROUND-layer, effectively level ~0) and
-- well below every POI/pin (MapCanvasPinFrameLevelsManagerMixin starts pins
-- at frame level 2000), so it renders strictly between the two.
--
-- Toggle with "/yatlas map on" / "/yatlas map off".

local pre = "World\\Minimaps\\";

local overlay;
local texturePool = {};
local worldMapButton;

local function GetOverlayFrame()
    if(overlay) then return overlay; end

    overlay = CreateFrame("Frame", "YatlasWorldMapOverlay", WorldMapFrame:GetCanvas());
    overlay:SetAllPoints(WorldMapFrame:GetCanvas());
    overlay:SetFrameLevel(500);
    overlay:Hide();

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
-- 1. Yatlas_UiMapID2Zone (mapdata_continents.lua, generated from the same
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
    local known = Yatlas_UiMapID2Zone[mapID];
    if(known) then
        local box = Yatlas_mapareas[known[1]][known[2]];
        if(box) then return known[1], box[1], box[2], box[3], box[4]; end
    end

    for continent, continentMapID in pairs(Yatlas_ContinentMapID) do
        if(mapID == continentMapID) then
            local box = Yatlas_mapareas[continent][0];
            return continent, box[1], box[2], box[3], box[4];
        end
    end

    local hint = Yatlas_GetContinentForMapID(mapID);
    local tryOrder = {};
    if(hint) then table.insert(tryOrder, hint); end
    for continent in pairs(Yatlas_ContinentMapID) do
        if(continent ~= hint) then table.insert(tryOrder, continent); end
    end

    for _, continent in ipairs(tryOrder) do
        local left, right, top, bottom = C_Map.GetMapRectOnMap(mapID, Yatlas_ContinentMapID[continent]);
        if(left) then
            local cbox = Yatlas_mapareas[continent][0];
            local cx1,cx2,cy1,cy2 = cbox[1],cbox[2],cbox[3],cbox[4];
            local bx1, by1 = (-left*(cx1-cx2) + cx1), (-top*(cy1-cy2) + cy1);
            local bx2, by2 = (-right*(cx1-cx2) + cx1), (-bottom*(cy1-cy2) + cy1);
            return continent, bx1, bx2, by1, by2;
        end
    end

    return nil;
end

local function RefreshOverlay()
    if(not overlay or not overlay:IsShown()) then return; end

    local mapID = WorldMapFrame:GetMapID();
    if(not mapID) then
        ReleaseTexturesFrom(1);
        ShowExplorationPins();
        return;
    end

    -- Big-coord box of the current view: bx1/by1 = max X/Y, bx2/by2 = min
    -- X/Y, matching Yatlas_mapareas' own {x1,x2,y1,y2} convention.
    local continent, bx1, bx2, by1, by2 = GetViewBigBox(mapID);
    if(not continent) then
        ReleaseTexturesFrom(1);
        ShowExplorationPins();
        return;
    end

    -- Blizzard's "explored area" pin (and Leatrix_Maps' "Show unexplored
    -- areas" option, which forces it to paint even normally-unrevealed
    -- tiles) draws its own painted map art at frame level ~2001, above our
    -- overlay (500) by design -- it would otherwise show through on top of
    -- our baked tiles wherever the player has explored. Since we're
    -- replacing Blizzard's art entirely for this map, suppress it.
    for pin in WorldMapFrame:EnumeratePinsByTemplate("MapExplorationPinTemplate") do
        pin:Hide();
    end

    local frameW, frameH = overlay:GetWidth(), overlay:GetHeight();
    if(not frameW or frameW == 0 or not frameH or frameH == 0) then
        return;
    end

    -- Which tile-grid cells cover the view box, and where each one lands
    -- (as a view-fraction, then a pixel rect) within the current view.
    local mnx1, mny1 = Yatlas_Big2Mini_Coord(bx1, by1);
    local mnx2, mny2 = Yatlas_Big2Mini_Coord(bx2, by2);

    local colMin = math.floor(math.min(mnx1, mnx2));
    local colMax = math.ceil(math.max(mnx1, mnx2));
    local rowMin = math.floor(math.min(mny1, mny2));
    local rowMax = math.ceil(math.max(mny1, mny2));

    local function BigToViewFrac(bigx, bigy)
        return (bx1-bigx)/(bx1-bx2), (by1-bigy)/(by1-by2);
    end

    local idx = 0;
    for col = colMin, colMax - 1 do
        for row = rowMin, rowMax - 1 do
            local tilekey = format("%.2dx%.2d", col, row);
            if(Yatlas_WDTValidTiles[continent] and Yatlas_WDTValidTiles[continent][tilekey]) then
                local vx1, vy1 = BigToViewFrac(Yatlas_Mini2Big_Coord(col, row));
                local vx2, vy2 = BigToViewFrac(Yatlas_Mini2Big_Coord(col+1, row+1));

                local px1, px2 = math.min(vx1,vx2)*frameW, math.max(vx1,vx2)*frameW;
                local py1, py2 = math.min(vy1,vy2)*frameH, math.max(vy1,vy2)*frameH;

                if(px2 >= 0 and px1 <= frameW and py2 >= 0 and py1 <= frameH) then
                    idx = idx + 1;
                    local tex = AcquireTexture(idx);
                    tex:ClearAllPoints();
                    tex:SetPoint("TOPLEFT", overlay, "TOPLEFT", px1, -py1);
                    tex:SetWidth(px2-px1);
                    tex:SetHeight(py2-py1);
                    tex:SetTexture(pre..continent.."\\"..format("map%.2d_%.2d", col, row));
                    tex:SetTexCoord(0, 1, 0, 1);
                    tex:Show();
                end
            end
        end
    end

    ReleaseTexturesFrom(idx+1);
end

function Yatlas_SetWorldMapOverlay(enabled, silent)
    YatlasOptions.WorldMapOverlay = enabled;

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
        print("Yatlas: world map overlay " .. (enabled and "ON" or "OFF"));
    end
end

function Yatlas_IsWorldMapOverlayEnabled()
    return YatlasOptions.WorldMapOverlay;
end

-- Icon on the stock WorldMapFrame (see WorldMapButton.xml): left-click
-- toggles this overlay, right-click opens Yatlas' own window.
YatlasWorldMapButtonMixin = {};

function YatlasWorldMapButtonMixin:OnLoad()
    self:RegisterForClicks("LeftButtonUp", "RightButtonUp");
    self:Refresh();
end

function YatlasWorldMapButtonMixin:OnEnter()
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
    GameTooltip:SetText("Yatlas", 1, 1, 1);
    GameTooltip:AddLine(Yatlas_IsWorldMapOverlayEnabled()
        and "|cff40ff40Left-click|r: disable baked map overlay"
        or  "|cff40ff40Left-click|r: enable baked map overlay");
    GameTooltip:AddLine("|cff40ff40Right-click|r: open Yatlas");
    GameTooltip:Show();
end

function YatlasWorldMapButtonMixin:OnLeave()
    GameTooltip:Hide();
end

function YatlasWorldMapButtonMixin:OnClick(button)
    if(button == "RightButton") then
        YatlasFrame:Toggle();
    else
        Yatlas_SetWorldMapOverlay(not Yatlas_IsWorldMapOverlayEnabled(), true);
    end
    self:Refresh();
end

function YatlasWorldMapButtonMixin:Refresh()
    local enabled = Yatlas_IsWorldMapOverlayEnabled();
    self.Icon:SetDesaturated(not enabled);
    self.Icon:SetAlpha(enabled and 1 or 0.5);
end

local initFrame = CreateFrame("Frame");
initFrame:RegisterEvent("PLAYER_LOGIN");
initFrame:SetScript("OnEvent", function()
    if(YatlasOptions.WorldMapOverlay == nil) then
        YatlasOptions.WorldMapOverlay = true;
    end

    GetOverlayFrame();

    hooksecurefunc(WorldMapFrame, "OnMapChanged", RefreshOverlay);
    WorldMapFrame:HookScript("OnShow", RefreshOverlay);

    if(YatlasOptions.WorldMapOverlay) then
        overlay:Show();
        RefreshOverlay();
    end

    worldMapButton = LibStub("Krowi_WorldMapButtons-1.4"):Add("YatlasWorldMapButtonTemplate", "BUTTON");
    worldMapButton:Show();
end);
