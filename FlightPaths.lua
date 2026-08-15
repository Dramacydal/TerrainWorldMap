-- Draws straight-line flight routes between flight masters (see
-- TaxiRoutes.lua for the Twm_TaxiNeighbors/Twm_TaxiRoutesByContinent lookup
-- tables this reads). Two modes, mutually exclusive:
--   - "Toggle Flight Paths" ON: every same-continent route drawn always.
--   - OFF (default): only the routes out of whichever flight master icon is
--     currently hovered (TWM_HoveredTaxiNodeID, set by Points.lua's
--     TWMFrameViewFrame_UpdatePointTooltip when it notices a "flightmasters"
--     point entering/leaving the mouseover tooltip).
--
-- Not built on the point-icon system (TWMPoints_AddPoint) -- that's for
-- fixed-size icons at a single (x,y), not line segments between two
-- arbitrary points. Uses its own small texture pool instead, following the
-- same pool-and-release pattern as WorldMapOverlay.lua's tile textures.

local linePool = {};

local function AcquireLine(viewframe, i)
    local tex = linePool[i];
    if(not tex) then
        tex = viewframe:CreateTexture(nil, "ARTWORK");
        tex:SetColorTexture(1, 1, 1, 0.6);
        linePool[i] = tex;
    end
    return tex;
end

local function ReleaseLinesFrom(fromIndex)
    for i = fromIndex, #linePool do
        linePool[i]:Hide();
    end
end

local LINE_THICKNESS = 2;

-- (mx, my) is a Mini coord (see TWM_Big2Mini_Coord); (locx, locy) is the
-- view's current top-left Mini coord and z the current zoom -- same inputs
-- and math as TWMP_SetOffset (Points.lua) uses to place a point icon,
-- just without that function's icon-centering offset.
local function MiniToOffset(mx, my, z, locx, locy)
    return (mx - locx)*z, (locy - my)*z;
end

local function DrawSegment(viewframe, idx, z, locx, locy, bigX1, bigY1, bigX2, bigY2)
    local mx1, my1 = TWM_Big2Mini_Coord(bigX1, bigY1);
    local mx2, my2 = TWM_Big2Mini_Coord(bigX2, bigY2);
    local px1, py1 = MiniToOffset(mx1, my1, z, locx, locy);
    local px2, py2 = MiniToOffset(mx2, my2, z, locx, locy);

    -- No manual clipping needed here -- ViewFrame has SetClipsChildren(true)
    -- (Templates.xml's TWMFrameViewTemplate OnLoad), so a line stretching
    -- past its edges (e.g. to an off-screen flight master) is cut off at
    -- the viewport boundary at the GPU level automatically.
    local dx, dy = px2 - px1, py2 - py1;
    local length = math.sqrt(dx*dx + dy*dy);
    if(length < 0.01) then return idx; end

    idx = idx + 1;
    local tex = AcquireLine(viewframe, idx);
    tex:ClearAllPoints();
    tex:SetSize(length, LINE_THICKNESS);
    tex:SetPoint("LEFT", viewframe, "TOPLEFT", px1, py1);
    -- Pivot must be the texture's left-center (0, 0.5), not the default
    -- center (0.5, 0.5) -- the anchor above pins the LEFT point at
    -- (px1,py1); rotating around the center instead would swing that end
    -- away from (px1,py1) too, detaching the line from its own endpoint.
    tex:SetRotation(math.atan2(dy, dx), { x = 0, y = 0.5 });
    tex:Show();
    return idx;
end

-- Which flightmaster point (if any) is currently under the mouse -- set by
-- Points.lua's TWMFrameViewFrame_UpdatePointTooltip, read here.
TWM_HoveredTaxiNodeID = nil;

-- Same rule sets/flightmasters.lua uses to decide whether to draw a
-- marker at all -- also applied here to every line endpoint, so a route
-- never gets drawn to a flight master that isn't itself shown (e.g. an
-- enemy-faction hub with "Show enemy faction Flight masters" off).
function TWM_IsFlightmasterVisible(faction)
    return faction == "Neutral" or faction == UnitFactionGroup("player") or TWMOption.ShowEnemyFlightmasters;
end

-- Called every time Points.lua redraws the point set (pan/zoom/force-update)
-- -- see the hook at the end of TWMPoints_Update.
function TWM_FlightPaths_OnPointsUpdate(frame, x, y)
    local lm = frame:GetName();
    local viewframe = _G[lm.."ViewFrame"];
    local z = frame:GetZoom();
    local map = TWMOption.Frames[lm].Map;

    local idx = 0;

    if(TWMOption.ShowFlightPaths) then
        local routes = Twm_TaxiRoutesByContinent[map];
        if(routes) then
            for _, r in ipairs(routes) do
                local fromInfo, toInfo = Twm_TaxiNodeInfo[r[5]], Twm_TaxiNodeInfo[r[6]];
                if(fromInfo and toInfo and TWM_IsFlightmasterVisible(fromInfo.faction) and TWM_IsFlightmasterVisible(toInfo.faction)) then
                    idx = DrawSegment(viewframe, idx, z, x, y, r[1], r[2], r[3], r[4]);
                end
            end
        end
    elseif(TWM_HoveredTaxiNodeID) then
        local hovered = Twm_TaxiNodeInfo[TWM_HoveredTaxiNodeID];
        local neighbors = Twm_TaxiNeighbors[TWM_HoveredTaxiNodeID];
        -- The hovered marker is, by definition, already visible (you can't
        -- hover a marker that isn't shown) -- only each neighbor's own
        -- faction needs checking here.
        if(hovered and neighbors and hovered.continent == map) then
            for _, otherID in ipairs(neighbors) do
                local other = Twm_TaxiNodeInfo[otherID];
                if(other and other.continent == map and TWM_IsFlightmasterVisible(other.faction)) then
                    idx = DrawSegment(viewframe, idx, z, x, y, hovered.x, hovered.y, other.x, other.y);
                end
            end
        end
    end

    ReleaseLinesFrom(idx + 1);
end

-- Redraws just the flight-path lines (e.g. right after a hover starts/stops)
-- without forcing a full point-set recompute, using whatever view
-- TWMPoints_Update last ran with (see TWMPoints_GetCurrentView, Points.lua).
function TWM_FlightPaths_Refresh()
    local frame, x, y = TWMPoints_GetCurrentView();
    if(frame and x) then
        TWM_FlightPaths_OnPointsUpdate(frame, x, y);
    end
end
