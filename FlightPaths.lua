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
-- arbitrary points. Uses Frame:CreateLine's native Line UIObject (the same
-- one Blizzard's own talent tree UI draws its connector lines with) instead
-- of the older rotated-stretched-Texture trick.
--
-- Positioning is NOT recomputed per-line on every pan/zoom tick, unlike the
-- tile grid and point icons. Instead, every line is anchored ONCE (in
-- Big/Mini-coordinate-derived local units) to a single shared "world" frame
-- (see GetWorldFrame) parented to the ViewFrame; panning/zooming just
-- repositions and rescales that ONE frame (SetPoint + SetScale, O(1)
-- regardless of how many lines exist) and WoW's own anchor system carries
-- every line along for free. This works for lines specifically because
-- there are only ever a few hundred of them at most (unlike the tile grid
-- or the full POI set, which use a small reused texture/frame pool instead
-- specifically to avoid ever having a whole continent's worth of objects
-- alive at once -- that pooling approach doesn't fit this "reposition one
-- parent" trick, since the pooled objects' identity changes on every pan).
--
-- SetThickness is also in the world frame's local units, so it'd get scaled
-- by the same SetScale as everything else and render thicker/thinner with
-- zoom -- countered by re-setting every active line's thickness to
-- PX / z on every tick (UpdateLineThickness), which is still O(n) but much
-- cheaper than the position/data recompute it replaces (no Big->Mini
-- conversion, no faction/spline lookups -- just a SetThickness call per
-- already-existing Line).

local outlinePool = {};
local linePool = {};
local worldFrame;

-- The one frame whose SetPoint/SetScale stands in for every line's own
-- per-tick reposition. Lazily created since ViewFrame might not exist yet
-- at file load time.
local function GetWorldFrame(viewframe)
    if(not worldFrame) then
        worldFrame = CreateFrame("Frame", nil, viewframe);
        worldFrame:SetSize(1, 1); -- no visible content of its own, size is irrelevant
    end
    return worldFrame;
end

local function AcquireLinePair(wf, i)
    local outline, line = outlinePool[i], linePool[i];
    if(not outline) then
        outline = wf:CreateLine(nil, "ARTWORK", nil, 0);
        outline:SetColorTexture(0, 0, 0, 0.55);
        outlinePool[i] = outline;
    end
    if(not line) then
        line = wf:CreateLine(nil, "ARTWORK", nil, 1);
        line:SetColorTexture(1, 1, 1, 0.6);
        linePool[i] = line;
    end
    return outline, line;
end

local function ReleaseLinesFrom(fromIndex)
    for i = fromIndex, #linePool do
        outlinePool[i]:Hide();
        linePool[i]:Hide();
    end
end

-- Desired constant ON-SCREEN thickness, in real pixels -- see
-- UpdateLineThickness for how this stays constant regardless of zoom.
-- Default (and Settings.lua slider's neutral value) -- outline is always
-- 2px more than the line itself, at any thickness the slider picks.
local DEFAULT_LINE_THICKNESS_PX = 2;

function TWM_GetFlightPathThickness()
    return TWMOption.FlightPathThickness or DEFAULT_LINE_THICKNESS_PX;
end

-- How many of the pooled line pairs (1..activeLineCount) are currently
-- actually in use -- set at the end of a rebuild, read by
-- UpdateLineThickness so it only touches lines that are actually shown.
local activeLineCount = 0;

-- Last zoom UpdateLineThickness actually ran for -- a pure pan (drag) calls
-- TWM_FlightPaths_OnPointsUpdate on every tick with an unchanged z, and
-- re-running the O(n) SetThickness loop every one of those ticks visibly
-- lagged dragging; thickness only ever needs to change when z itself does
-- (or TWM_SetFlightPathThickness forces it, by clearing this to nil).
local lastZoom;

-- Re-applies the current zoom's thickness to every active line -- called
-- every tick (even when the line SET itself didn't change) so thickness
-- stays a constant screen-pixel width instead of scaling with the world
-- frame's own SetScale(z).
local function UpdateLineThickness(z)
    local pxLine = TWM_GetFlightPathThickness();
    local lineT, outlineT = pxLine / z, (pxLine + 2) / z;
    for i = 1, activeLineCount do
        outlinePool[i]:SetThickness(outlineT);
        linePool[i]:SetThickness(lineT);
    end
end

-- Settings.lua's slider calls this on every value change -- forces
-- UpdateLineThickness to actually re-run (bypassing the lastZoom check
-- below, which otherwise assumes thickness only ever needs to change
-- when zoom does).
function TWM_SetFlightPathThickness(px)
    TWMOption.FlightPathThickness = px;
    lastZoom = nil;
    TWM_FlightPaths_Refresh();
end

-- (bigX, bigY) -> the world frame's own local anchor units. Big->Mini is
-- the usual conversion; Mini's Y needs negating because WoW's SetPoint
-- offsets treat +Y as up, while Mini's Y (like screen row/column) increases
-- downward -- see MiniToOffset's old per-tick version (Points.lua's
-- TWMP_SetOffset) for the same sign flip done the old way.
local function BigToWorldOffset(bigX, bigY)
    local mx, my = TWM_Big2Mini_Coord(bigX, bigY);
    return mx, -my;
end

local function DrawSegment(wf, idx, bigX1, bigY1, bigX2, bigY2)
    local lx1, ly1 = BigToWorldOffset(bigX1, bigY1);
    local lx2, ly2 = BigToWorldOffset(bigX2, bigY2);
    local dx, dy = lx2 - lx1, ly2 - ly1;
    if(dx*dx + dy*dy < 0.0001) then return idx; end

    idx = idx + 1;
    local outline, line = AcquireLinePair(wf, idx);

    -- No manual clipping needed here -- ViewFrame has SetClipsChildren(true)
    -- (Templates.xml's TWMFrameViewTemplate OnLoad), which also covers this
    -- nested world frame's own children, so a line stretching past the
    -- viewport's edges (e.g. to an off-screen flight master) is cut off at
    -- the GPU level automatically.
    -- Thickness is set by UpdateLineThickness (every tick, keyed off
    -- activeLineCount), not here -- see this file's header.
    outline:ClearAllPoints();
    outline:SetStartPoint("TOPLEFT", wf, lx1, ly1);
    outline:SetEndPoint("TOPLEFT", wf, lx2, ly2);
    outline:Show();

    line:ClearAllPoints();
    line:SetStartPoint("TOPLEFT", wf, lx1, ly1);
    line:SetEndPoint("TOPLEFT", wf, lx2, ly2);
    line:Show();

    return idx;
end

-- Draws the real curved TaxiPathNode spline (Twm_taxipathnodes, generated by
-- scripts/gen_poi_flightmasters.js) instead of a straight line, but only
-- while Shift is held -- TWM_FlightPaths_PollShiftKey below keeps this in
-- sync even when nothing else about the route changed. Straight lines are
-- the default (both for "always show" and hover-preview) since a route can
-- expand into dozens of spline segments -- keeping every route curved all
-- the time multiplies how many Line children the shared world frame has,
-- and repositioning/rescaling that frame during a live pan/zoom costs the
-- client proportionally more the more children it has (see
-- .claude-docs/gotchas.md) -- noticeably laggy dragging with Shift held
-- during "always show", fine as an on-demand glance instead.
local function DrawRoute(wf, idx, fromID, toID, fromBigX, fromBigY, toBigX, toBigY)
    if(IsShiftKeyDown()) then
        local pathID = Twm_TaxiPathIDByPair and Twm_TaxiPathIDByPair[fromID .. "->" .. toID];
        local spline = pathID and Twm_taxipathnodes and Twm_taxipathnodes[pathID];
        if(spline and #spline >= 2) then
            for i = 1, #spline - 1 do
                idx = DrawSegment(wf, idx, spline[i][1], spline[i][2], spline[i+1][1], spline[i+1][2]);
            end
            return idx;
        end
    end
    return DrawSegment(wf, idx, fromBigX, fromBigY, toBigX, toBigY);
end

-- Last known Shift state; TWM_FlightPaths_PollShiftKey (called every tick
-- from TWMFrameViewTemplate's OnUpdate, Templates.xml) forces a line
-- rebuild the instant Shift is pressed/released, instead of waiting for an
-- unrelated pan/zoom/hover event to happen to also refresh it.
local lastShiftDown = false;

function TWM_FlightPaths_PollShiftKey()
    local down = IsShiftKeyDown();
    if(down ~= lastShiftDown) then
        lastShiftDown = down;
        TWM_FlightPaths_Refresh();
    end
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

-- Captures every input that actually changes which lines should exist --
-- NOT pan/zoom (the world frame reposition below handles that for free).
-- Rebuilding the line set is the one part of this that's still O(n), so
-- it's skipped whenever nothing relevant has actually changed.
local lastSignature;

-- Called every time Points.lua redraws the point set (pan/zoom/force-update)
-- -- see the hook at the end of TWMPoints_Update. Cheap on every call
-- (just repositions/rescales the shared world frame); only rebuilds the
-- actual line set when `lastSignature` shows something relevant changed.
function TWM_FlightPaths_OnPointsUpdate(frame, x, y)
    local lm = frame:GetName();
    local viewframe = _G[lm.."ViewFrame"];
    local z = frame:GetZoom();
    local map = TWMOption.Frames[lm].Map;
    local wf = GetWorldFrame(viewframe);

    -- SetPoint offsets on a frame are interpreted in THAT FRAME'S OWN
    -- (already-scaled) coordinate space -- since wf:SetScale(z) is applied
    -- below^, passing -x*z/y*z here would double-apply the zoom factor and
    -- fling wf thousands of pixels off-screen (confirmed: that's exactly
    -- what happened -- lines invisible in every mode, not a layering bug).
    -- Passing the raw, unscaled -x/y lets wf's own scale do that
    -- multiplication for us, matching how each line's own local offset
    -- (BigToWorldOffset) is likewise expressed in pre-scale units.
    wf:SetScale(z);
    wf:ClearAllPoints();
    wf:SetPoint("TOPLEFT", viewframe, "TOPLEFT", -x, y);
    if(z ~= lastZoom) then
        lastZoom = z;
        UpdateLineThickness(z);
    end

    local signature = map .. "|" .. tostring(TWMOption.ShowFlightPaths) .. "|"
        .. tostring(TWMOption.ShowEnemyFlightmasters) .. "|" .. tostring(TWM_HoveredTaxiNodeID)
        .. "|" .. tostring(IsShiftKeyDown()); -- straight vs. curved (DrawRoute)
    if(signature == lastSignature) then return; end
    lastSignature = signature;

    local idx = 0;

    if(TWMOption.ShowFlightPaths) then
        local routes = Twm_TaxiRoutesByContinent[map];
        if(routes) then
            for _, r in ipairs(routes) do
                local fromInfo, toInfo = Twm_TaxiNodeInfo[r[5]], Twm_TaxiNodeInfo[r[6]];
                if(fromInfo and toInfo and TWM_IsFlightmasterVisible(fromInfo.faction) and TWM_IsFlightmasterVisible(toInfo.faction)) then
                    idx = DrawRoute(wf, idx, r[5], r[6], r[1], r[2], r[3], r[4]);
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
                    idx = DrawRoute(wf, idx, TWM_HoveredTaxiNodeID, otherID, hovered.x, hovered.y, other.x, other.y);
                end
            end
        end
    end

    activeLineCount = idx;
    ReleaseLinesFrom(idx + 1);
    UpdateLineThickness(z);
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
