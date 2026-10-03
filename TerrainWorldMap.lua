local pre = "World\\Minimaps\\";

local MINI2BIGX = 533.3333;
local MINI2BIGY = 533.3333;

TWMOption = {}

-- Twm_NoLiquidTiles is only ever declared (even as an empty table) by
-- scripts/parse_wdt.js when it was run with a real minimaps directory --
-- flavors that never got this data (everything before Mists so far) leave
-- the global nil. That absence is also how the "Show underwater terrain"
-- option/menu-entry decide whether to show up at all (see Settings.lua,
-- WorldMapOverlay.lua, TerrainWorldMapButton.lua).
function TWM_HasNoLiquidData()
    return Twm_NoLiquidTiles ~= nil and next(Twm_NoLiquidTiles) ~= nil;
end

-- TWM_SetDrawUnderwater/TWM_IsDrawUnderwaterEnabled live in WorldMapOverlay.lua
-- (so the setter can force-refresh the overlay, same as the other tile
-- toggles there) even though this helper is used by both that file and this
-- one -- fine, Lua resolves the global by name at call time, not load time.

-- Picks between the normal "mapCC_RR" minimap tile and its "noliquid_mapCC_RR"
-- variant (see scripts/parse_wdt.js's findNoLiquidTiles()) purely based on
-- the "Show underwater terrain" checkbox -- no live IsSubmerged() check, no
-- automatic swapping. If the option is on and this tile has a noLiquid
-- variant, that's what gets drawn, everywhere, regardless of where the
-- player actually is.
-- Sets a tile texture with the current "Tile Filtering" option applied. See
-- TWM_SetTileFilter (WorldMapOverlay.lua) for why a filterMode-only change
-- needs a deferred second rebuild on top of calling this.
function TWM_SetTileTexture(tex, path, filter)
    tex:SetTexture(path, nil, nil, filter);
end

function TWM_GetTileFileName(continent, col, row)
    if(TWM_IsDrawUnderwaterEnabled()
            and Twm_NoLiquidTiles and Twm_NoLiquidTiles[continent]
            and Twm_NoLiquidTiles[continent][format("%.2dx%.2d", col, row)]) then
        return format("noliquid_map%.2d_%.2d", col, row);
    end
    return format("map%.2d_%.2d", col, row);
end

-- Some flavors' minimap tiles can't be loaded by a plain path string at all
-- -- confirmed on WoW: Forever/Camelot by testing SetTexture with a raw
-- "World\Minimaps\..." path against the equivalent numeric FileDataID: the
-- path silently resolves to nothing (GetTexture() -> nil after SetTexture),
-- the FileDataID works fine (see gotchas.md). Twm_TileFileID[continent]
-- [filename] (Data_<Flavor>/mapdata_tiles.lua, only baked in for flavors
-- that need it -- see parse_wdt.js's --listfile flag) holds the FileDataID
-- for exactly that case, keyed by the same filename TWM_GetTileFileName
-- already returns (so it covers the noLiquid variant too, no separate
-- table needed). Falls back to the old path string for every other
-- flavor, unaffected.
function TWM_GetTileTexture(continent, filename)
    local fileID = Twm_TileFileID and Twm_TileFileID[continent] and Twm_TileFileID[continent][filename];
    if(fileID) then return fileID; end
    return pre..continent.."\\"..filename;
end

-- Forces TWMFrame's own tile grid to rebuild with fresh texture names (e.g.
-- after toggling "Show underwater terrain") even though the view hasn't
-- actually panned/zoomed/changed map -- SetLocation()'s forceupdate param
-- already exists for exactly this ("re-derive everything, don't shortcut on
-- unchanged location"), just nothing outside of pan/zoom/zone-switch called
-- it with that flag before.
function TWM_RefreshFrameTiles()
    if(TWMFrame and TWMFrame.opt) then
        TWMFrame:SetLocation(TWMFrame.opt.Location[1], TWMFrame.opt.Location[2], true);
    end
end

-- Clears every currently-allocated tile texture in TWMFrame's own grid back
-- to unbound, without setting anything new -- see TWM_SetTileFilter
-- (WorldMapOverlay.lua) for why this needs to happen as its own pass,
-- separate from (and before) the rebuild that follows it.
function TWM_ClearFrameTileTextures()
    if(TWMFrame and TWMFrame.texturelayout) then
        for hw = 1, #TWMFrame.texturelayout do
            for hh = 1, #TWMFrame.texturelayout[hw] do
                TWMFrame.texturelayout[hw][hh]:SetTexture(nil);
            end
        end
    end
end

-- Width floor: keeps the dropdowns and "Goto Player" on the left of the
-- control strip clear of the Settings/Lock/Close buttons on the right.
TWM_FRAME_MIN_WIDTH = 460;

TWM_FRAME_OPTION_DEFAULTS = {
    ["Locked"] = false,
    ["Map"] = "Kalimdor",
    ["Location"] = {31.0625, 33.250},
    ["Alpha"] = 1,
    ["IconSize"] = 1.0,
    ["PointCfg"] = {},
    ["ShowWMOOverlay"] = true,
    ["ShowTerrain"] = true,
    ["Zoom"] = 256,
    ["Width"] = 720,
    ["Height"] = 628,
};

-- TWMFrame's on-screen position when first created (TerrainWorldMap.xml); not part
-- of TWM_FRAME_OPTION_DEFAULTS since screen position isn't stored in
-- TWMOption at all -- the client remembers it on its own via
-- SetUserPlaced(), same as any other movable frame with a stable name.
local TWM_FRAME_DEFAULT_POINT = {"TOPLEFT", "UIParent", "TOPLEFT", 64, -64};

-- SetZoom sizes/tiles the texture grid off ViewFrame's *current* anchor-
-- derived width/height, which doesn't necessarily reflect a just-applied
-- parent SetSize yet -- fine for a live resize-drag (each step is a small
-- nudge off an already-settled size), but a big one-shot jump (like this
-- reset) can catch it mid-resolve and undersize the grid, leaving gaps
-- until some later resize forces a fresh recompute against the now-settled
-- size. Deferring one frame with C_Timer.After(0, ...) lets layout settle
-- first.
local function RefreshZoomNextFrame(f)
    C_Timer.After(0, function()
        if(f.opt) then
            f:SetZoom(f.opt.Zoom, true);
        end
    end);
end

function TWM_ResetFramePosition()
    local f = TWMFrame;

    f:StopMovingOrSizing();
    f:ClearAllPoints();
    f:SetPoint(unpack(TWM_FRAME_DEFAULT_POINT));
    f:SetUserPlaced(false);

    f.opt.Zoom = TWM_FRAME_OPTION_DEFAULTS.Zoom;
    f.opt.Width = TWM_FRAME_OPTION_DEFAULTS.Width;
    f.opt.Height = TWM_FRAME_OPTION_DEFAULTS.Height;
    f.opt.Location = {TWM_FRAME_OPTION_DEFAULTS.Location[1], TWM_FRAME_OPTION_DEFAULTS.Location[2]};

    f:SetSize(f.opt.Width, f.opt.Height);

    if(f:IsShown()) then
        RefreshZoomNextFrame(f);
    else
        -- Hidden frames don't even resolve anchor-derived layout until
        -- shown -- deferred further, to the OnShow hook in
        -- TWMFrame_OnLoadExtra instead.
        f.needsZoomRefreshOnShow = true;
    end
end

local dummyv = nil;
local nilfunc = function() end

-- Debug: overlay each map tile with its grid-cell coordinate and the live
-- zone reported there. Toggle with "/twm debug".
TWM_DebugTiles = false;

function TWM_ToggleTileDebug()
    TWM_DebugTiles = not TWM_DebugTiles;
    if(not TWM_DebugTiles and TWM_HideCursorCoordLabel) then
        -- Otherwise the label sticks around showing stale coordinates
        -- until the mouse happens to leave the view -- OnUpdate simply
        -- stops refreshing it once TWM_DebugTiles is false (see
        -- Templates.xml's own gate), it doesn't hide it.
        TWM_HideCursorCoordLabel();
    end
    if(TWMFrame.opt) then
        TWMFrame:SetLocation(TWMFrame.opt.Location[1], TWMFrame.opt.Location[2], true);
    end
    print(TWM_DebugTiles and TWM_DEBUG_TILES_ON or TWM_DEBUG_TILES_OFF);
end

-- Lazily creates 4 thin border-strip textures for a pooled tile texture,
-- tracing its own current rect. Anchored with TWO points each (both
-- relevant corners of `tex`, not just one + an explicit size), so once set
-- up they keep following `tex`'s own position/size automatically through
-- every future pan/zoom/resize -- no per-call update code needed here at
-- all, unlike the tile texture itself (whose SetPoint/SetWidth/SetHeight
-- the many branches above recompute by hand every call).
-- `color` (an {r,g,b} table) is applied every call, not just at creation
-- -- cheap, and correct even if a pooled `tex` slot gets reused later for
-- something that wants a different color (e.g. a different WMO tile
-- index after the map changes).
local TWM_TILE_DEBUG_BORDER_PX = 2;
local TWM_TILE_DEBUG_BORDER_YELLOW = {1, 1, 0};
function TWM_EnsureTileDebugBorder(vf, tex, color)
    color = color or TWM_TILE_DEBUG_BORDER_YELLOW;

    if(not tex.debugBorder) then
        local border = {};
        for _, side in ipairs({"top", "bottom", "left", "right"}) do
            local btex = vf:CreateTexture(nil, "OVERLAY", nil, 7);
            btex:SetTexture("Interface\\Buttons\\WHITE8X8");
            border[side] = btex;
        end

        border.top:SetPoint("TOPLEFT", tex, "TOPLEFT", 0, 0);
        border.top:SetPoint("TOPRIGHT", tex, "TOPRIGHT", 0, 0);
        border.top:SetHeight(TWM_TILE_DEBUG_BORDER_PX);

        border.bottom:SetPoint("BOTTOMLEFT", tex, "BOTTOMLEFT", 0, 0);
        border.bottom:SetPoint("BOTTOMRIGHT", tex, "BOTTOMRIGHT", 0, 0);
        border.bottom:SetHeight(TWM_TILE_DEBUG_BORDER_PX);

        border.left:SetPoint("TOPLEFT", tex, "TOPLEFT", 0, 0);
        border.left:SetPoint("BOTTOMLEFT", tex, "BOTTOMLEFT", 0, 0);
        border.left:SetWidth(TWM_TILE_DEBUG_BORDER_PX);

        border.right:SetPoint("TOPRIGHT", tex, "TOPRIGHT", 0, 0);
        border.right:SetPoint("BOTTOMRIGHT", tex, "BOTTOMRIGHT", 0, 0);
        border.right:SetWidth(TWM_TILE_DEBUG_BORDER_PX);

        tex.debugBorder = border;
    end

    local border = tex.debugBorder;
    border.top:SetVertexColor(color[1], color[2], color[3], 1);
    border.bottom:SetVertexColor(color[1], color[2], color[3], 1);
    border.left:SetVertexColor(color[1], color[2], color[3], 1);
    border.right:SetVertexColor(color[1], color[2], color[3], 1);
    return border;
end

function TWM_HideTileDebugBorder(tex)
    if(tex.debugBorder) then
        tex.debugBorder.top:Hide();
        tex.debugBorder.bottom:Hide();
        tex.debugBorder.left:Hide();
        tex.debugBorder.right:Hide();
    end
    TWM_HideWMODebugCorners(tex);
    TWM_HideWMODebugLabel(tex);
end

function TWM_ShowTileDebugBorder(border)
    border.top:Show();
    border.bottom:Show();
    border.left:Show();
    border.right:Show();
end

-- A WMO tile's own 4 real (possibly yawed) corners, drawn via Line
-- (point-to-point, arbitrary angle -- see FlightPaths.lua's own use of
-- Frame:CreateLine for the same reason) instead of the 4-strip Texture
-- border above, which only auto-tracks an axis-aligned rect. Deliberately
-- NOT re-deriving the corners from cx/cy/width/height/yawDeg here -- the
-- data already carries the real corners (gen_wmo_tiles.js) precisely so
-- this debug view doesn't depend on the same rotation math it exists to
-- double-check.
function TWM_EnsureWMODebugCorners(host, tex, color)
    color = color or TWM_TILE_DEBUG_BORDER_YELLOW;
    if(not tex.debugCorners) then
        local lines = {};
        for i = 1, 4 do
            -- `host` is the WMO overlay's debug frame, which sits above every
            -- per-group tile frame (TWM_WMOOverlay_EnsureDebugFrame).
            -- (HIGHLIGHT was tried as the layer, but HIGHLIGHT only renders
            -- while the frame is moused over -- wrong layer for this.)
            lines[i] = host:CreateLine(nil, "OVERLAY", nil, 7);
            lines[i]:SetThickness(TWM_TILE_DEBUG_BORDER_PX);
        end
        tex.debugCorners = lines;
    end
    for _, line in ipairs(tex.debugCorners) do
        line:SetColorTexture(color[1], color[2], color[3], 1);
    end
    return tex.debugCorners;
end

function TWM_HideWMODebugCorners(tex)
    if(not tex.debugCorners) then return; end
    for _, line in ipairs(tex.debugCorners) do
        line:Hide();
    end
end

-- corners = {bigX1,bigY1, bigX2,bigY2, bigX3,bigY3, bigX4,bigY4} (Big
-- coordinates, already in the tile's own real corner order) -> the same 4
-- points, converted to on-screen (ViewFrame-relative) pixels. Shared by
-- TWM_PositionWMODebugCorners (the border) and TWM_PositionWMODebugLabel
-- (the FileDataID text, positioned at these same 4 points' average) --
-- deliberately the ONE conversion, not two independently-computed ones,
-- so the label can never visually disagree with the border it's labeling.
function TWM_WMOCornersToScreenPoints(corners, Lx, Ly, z)
    local pts = {};
    for i = 1, 4 do
        local bx, by = corners[i * 2 - 1], corners[i * 2];
        local mx, my = TWM_Big2Mini_Coord(bx, by);
        pts[i] = { (mx - Lx) * z, (Ly - my) * z };
    end
    return pts;
end

-- corners = {bigX1,bigY1, bigX2,bigY2, bigX3,bigY3, bigX4,bigY4} (Big
-- coordinates, already in the tile's own real corner order -- consecutive
-- pairs are adjacent corners, so edges are 1-2, 2-3, 3-4, 4-1). Shows each
-- line itself -- no separate TWM_ShowWMODebugCorners needed.
function TWM_PositionWMODebugCorners(lines, vf, corners, Lx, Ly, z)
    local pts = TWM_WMOCornersToScreenPoints(corners, Lx, Ly, z);
    for i = 1, 4 do
        local a, b = pts[i], pts[i % 4 + 1];
        local line = lines[i];
        line:ClearAllPoints();
        line:SetStartPoint("TOPLEFT", vf, a[1], a[2]);
        line:SetEndPoint("TOPLEFT", vf, b[1], b[2]);
        line:Show();
    end
end

-- FileDataID label, centered on the tile's own real (possibly rotated)
-- quad -- same color as its debug border, text itself never rotated (a
-- rotated frame's own center point doesn't move under its own rotation, so
-- an unrotated label at that center reads correctly regardless of yaw).
function TWM_EnsureWMODebugLabel(host, tex, color)
    color = color or TWM_TILE_DEBUG_BORDER_YELLOW;
    if(not tex.debugFileIDLabel) then
        local label = host:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
        label:SetDrawLayer("OVERLAY", 7); -- same sublevel as the border lines
        tex.debugFileIDLabel = label;
    end
    tex.debugFileIDLabel:SetTextColor(color[1], color[2], color[3], 1);
    return tex.debugFileIDLabel;
end

function TWM_HideWMODebugLabel(tex)
    if(not tex.debugFileIDLabel) then return; end
    tex.debugFileIDLabel:Hide();
end

-- Positioned at the average of the SAME 4 screen points the border itself
-- uses (TWM_WMOCornersToScreenPoints), not a separately-computed cx/cy --
-- see that function's own header for why.
function TWM_PositionWMODebugLabel(label, vf, corners, Lx, Ly, z, fileID)
    local pts = TWM_WMOCornersToScreenPoints(corners, Lx, Ly, z);
    local cx, cy = 0, 0;
    for i = 1, 4 do
        cx = cx + pts[i][1];
        cy = cy + pts[i][2];
    end
    cx, cy = cx / 4, cy / 4;
    label:SetText(tostring(fileID));
    label:ClearAllPoints();
    label:SetPoint("CENTER", vf, "TOPLEFT", cx, cy);
    label:Show();
end

-- Whether a map tile has real terrain, per this client's own WDT data
-- (Twm_WDTValidTiles, mapdata_tiles.lua -- ground truth extracted from
-- world/maps/<continent>/<continent>.wdt's rootADT field, since a tile's
-- minimap preview texture can exist even when no terrain does, e.g.
-- leftover Cataclysm-only art with no TBC-era ADT behind it). Used both to
-- gate map-tile rendering and for the "/twm debug" tile overlay, which
-- also reports the specific named zone (Twm_mapareas) when there is one.
function TWM_GetLiveZoneNameForBigCoord(map, bigx, bigy, tilekey)
    local valid = tilekey and Twm_WDTValidTiles[map] and Twm_WDTValidTiles[map][tilekey];
    if(not valid) then return nil; end

    local id = TWM_FindZoneAtBigCoord(map, bigx, bigy, tilekey);
    if(id) then
        local name = Twm_areadb[id];
        if(name and not (Twm_mapareas[map] and Twm_mapareas[map][id])) then
            -- Real AreaTable name, but not a key in Twm_mapareas -- an
            -- orphan top-level (ParentAreaID=0) entry with no real
            -- UiMapAssignment row, i.e. not a zone the game actually
            -- surfaces (e.g. Gillijim's Isle near Wetlands). Flagged in
            -- amber so it reads as "real name, don't trust it as a zone".
            return "|cffffa500"..name.."|r";
        end
        return name;
    end

    return "|cff8080ff(terrain)|r";
end

-- Which zone (Twm_mapareas areaID) a Big-coordinate point belongs to.
-- Ground truth first: Twm_WDTValidTiles[map][tilekey] holds the tile's own
-- majority-vote AreaID straight from its ADT's MCNK sub-chunks (see
-- scripts/parse_wdt.js's findAdtAreaIDs()), handling irregular real zone
-- borders that a rectangular Twm_mapareas box can't (e.g. Outland's
-- Nagrand/Terokkar Forest boxes overlap by several tiles). Falls back to
-- the smallest-area rectangular-box check for tiles that only got plain
-- `true` (no ADT data available).
function TWM_FindZoneAtBigCoord(map, bigx, bigy, tilekey)
    local fromTile = tilekey and Twm_WDTValidTiles[map] and Twm_WDTValidTiles[map][tilekey];
    if(type(fromTile) == "number") then
        return fromTile;
    end

    local areas = Twm_mapareas[map];
    if(not areas) then return nil; end

    local bestID, bestArea;
    for id, box in pairs(areas) do
        if(id ~= 0 and bigx < box[1] and bigx > box[2] and bigy < box[3] and bigy > box[4]) then
            local area = (box[1]-box[2]) * (box[3]-box[4]);
            if(not bestArea or area < bestArea) then
                bestID, bestArea = id, area;
            end
        end
    end

    return bestID;
end

-- The list tables below are keyed by the localized map name, so two maps
-- sharing a name in a locale would overwrite each other (Mists' old and new
-- Scholomance are both "Некроситет" in ruRU, also in deDE/frFR/koKR). Returns
-- the display name of every entry: all entries of a shared name get the
-- map's enUS name (its ID if that is no different) appended.
local function TWM_DisplayNames(entries)
    local names, count = {}, {};
    for i, e in ipairs(entries) do
        names[i] = TWM_ResolveLocaleName(e.name);
        count[names[i]] = (count[names[i]] or 0) + 1;
    end

    local used = {};
    for i, e in ipairs(entries) do
        local base = names[i];
        if(count[base] > 1) then
            local en = e.name.enUS;
            names[i] = base .. " (" .. ((en and en ~= base) and en or e.mapID or e.key) .. ")";
            if(used[names[i]]) then
                names[i] = base .. " (" .. (e.mapID or e.key) .. ")";
            end
        end
        used[names[i]] = true;
    end
    return names;
end

-- TWM_ARENAS (dropdown name -> {key}, same shape as TWM_BATTLEGROUNDS) is
-- built here from Twm_ArenaNames (Data_<Flavor>/mapdata_arenas.lua, when
-- that flavor has one -- see scripts/gen_arenas.js), resolving each arena's
-- name for the current client locale via TWM_ResolveLocaleName
-- (TaxiRoutes.lua, loads before this file; falls back to enUS). Arenas have
-- no live uiMapID to resolve a name from (see gen_arenas.js's header),
-- unlike Twm_BattlegroundMapID's C_Map.GetMapInfo(uiMapID).name, so this
-- baked-in table is the only source for one.
if(Twm_ArenaNames) then
    TWM_ARENAS = {};
    local names = TWM_DisplayNames(Twm_ArenaNames);
    for i, e in ipairs(Twm_ArenaNames) do
        TWM_ARENAS[names[i]] = {e.key};
    end
end

-- TWM_DUNGEONS/TWM_RAIDS/TWM_SCENARIOS -- same shape and same reason as
-- TWM_ARENAS above (Twm_DungeonNames/Twm_RaidNames/Twm_ScenarioNames come
-- from scripts/gen_instance_maps.js; Scenarios only exists on Mists, the
-- only flavor with any UI_MAP_TYPE_SCENARIO Map rows). Dungeons/Raids also
-- carry `.expansion` (Map.db2's own ExpansionID, a string like every other
-- ID in this codebase) -- used to insert an expansion-selection submenu
-- level below the Dungeons/Raids dropdown category (see
-- TWM_GetSortedExpansionIDs/TWM_GetExpansionName below).
if(Twm_DungeonNames) then
    TWM_DUNGEONS = {};
    local names = TWM_DisplayNames(Twm_DungeonNames);
    for i, e in ipairs(Twm_DungeonNames) do
        TWM_DUNGEONS[names[i]] = {e.key, expansion = e.expansion, mapID = e.mapID};
    end
end

if(Twm_RaidNames) then
    TWM_RAIDS = {};
    local names = TWM_DisplayNames(Twm_RaidNames);
    for i, e in ipairs(Twm_RaidNames) do
        TWM_RAIDS[names[i]] = {e.key, expansion = e.expansion, mapID = e.mapID};
    end
end

-- Twm_SeasonOnlyMaps (Data_Vanilla/mapdata_seasons.lua, hand-maintained; nil on
-- other flavors) = { [seasonID] = {"<Map.csv ID>", ...} }: those maps are
-- listed only while C_Seasons.GetActiveSeason() == seasonID. The season is
-- read when the menu is built, not at load, so it follows the realm.
local TWM_SeasonOfMap;
local function TWM_IsMapHiddenBySeason(mapID)
    if(not Twm_SeasonOnlyMaps or not mapID) then return false; end
    if(not TWM_SeasonOfMap) then
        TWM_SeasonOfMap = {};
        for season, ids in pairs(Twm_SeasonOnlyMaps) do
            for _, id in ipairs(ids) do TWM_SeasonOfMap[id] = season; end
        end
    end
    local season = TWM_SeasonOfMap[mapID];
    if(season == nil) then return false; end
    local active = C_Seasons and C_Seasons.HasActiveSeason() and C_Seasons.GetActiveSeason();
    return active ~= season;
end

-- Twm_DevelopmentMaps (mapdata_development.lua, all flavors) = {"<Map.csv ID>", ...}:
-- maps still in development, listed only while TWMOption.ShowDevelopmentMaps is on.
local TWM_DevelopmentMapSet;
local function TWM_IsDevelopmentMap(mapID)
    if(not mapID) then return false; end
    if(not TWM_DevelopmentMapSet) then
        TWM_DevelopmentMapSet = {};
        for _, id in ipairs(Twm_DevelopmentMaps or {}) do TWM_DevelopmentMapSet[id] = true; end
    end
    return TWM_DevelopmentMapSet[mapID] == true;
end

-- Text color of development maps in the dropdown lists (shown only while
-- "Show Development Maps" is on).
local TWM_DEV_MAP_COLOR = "|cffd9741a";

local function TWM_IsMapHidden(mapID)
    if(not mapID) then return false; end
    if(TWM_IsDevelopmentMap(mapID) and not (TWMOption and TWMOption.ShowDevelopmentMaps)) then
        return true;
    end
    return TWM_IsMapHiddenBySeason(mapID);
end

if(Twm_ScenarioNames) then
    TWM_SCENARIOS = {};
    local names = TWM_DisplayNames(Twm_ScenarioNames);
    for i, e in ipairs(Twm_ScenarioNames) do
        TWM_SCENARIOS[names[i]] = {e.key, mapID = e.mapID};
    end
end

-- "Show WMO Layers" overlay: a few maps (arenas so far -- Dalaran Sewers,
-- Orgrimmar -- see Twm_WMOTiles, Data_<Flavor>/mapdata_wmo_tiles.lua,
-- scripts/gen_wmo_tiles.js; the same system will apply to dungeons/raids
-- later, hence the generic naming) have real outdoor ADT terrain but no
-- baked minimap art for it at all; the only real minimap art there is the
-- placed WMO building's own baked group tiles. Drawn as a pool of plain
-- textures (raw FileDataIDs), positioned in the same mini-coordinate
-- space TWMPoints uses (see TWMP_SetOffset, Points.lua) so they pan/zoom in
-- sync with the rest of the view.
--
-- Stacking: one child frame of ViewFrame per WMO group (the tiles of one
-- group never overlap each other), ordered by frame level -- see
-- TWM_WMOOverlay_Update. Texture draw sublevels only give 16 steps per
-- layer, far fewer than the stacking depth real dungeons need.
function TWM_WMOOverlay_EnsureGroupFrame(frame, vf, rank)
    frame.wmoGroupFrames = frame.wmoGroupFrames or {};
    local gf = frame.wmoGroupFrames[rank];
    if(not gf) then
        gf = CreateFrame("Frame", nil, vf);
        gf:SetSize(1, 1); -- no content of its own, the tiles anchor to ViewFrame
        gf:SetPoint("TOPLEFT", vf, "TOPLEFT", 0, 0);
        gf.textures = {};
        frame.wmoGroupFrames[rank] = gf;
    end
    return gf;
end

-- Above every group frame, below the point markers/buttons/flight paths
-- (all lifted by TWM_WMO_FRAME_BAND, see Points.lua) -- hosts the debug
-- borders/labels so they always draw over the tiles.
function TWM_WMOOverlay_EnsureDebugFrame(frame, vf)
    if(not frame.wmoDebugFrame) then
        local df = CreateFrame("Frame", nil, vf);
        df:SetSize(1, 1);
        df:SetPoint("TOPLEFT", vf, "TOPLEFT", 0, 0);
        frame.wmoDebugFrame = df;
    end
    frame.wmoDebugFrame:SetFrameLevel(vf:GetFrameLevel() + TWM_WMO_FRAME_BAND);
    return frame.wmoDebugFrame;
end

function TWM_WMOOverlay_EnsureTexture(gf, k)
    local tex = gf.textures[k];
    if(not tex) then
        tex = gf:CreateTexture(nil, "OVERLAY");
        -- Blizzard's own WMO-group minimap baking pipeline has a fixed,
        -- non-arbitrary 90-degree rotation relative to world axes (already
        -- documented in gotchas.md for the separate dungeon-interior
        -- minimap feature -- this overlay uses this exact same tile-baking
        -- system, so the same correction applies here). Corrected by
        -- rotating the displayed CONTENT 90 degrees clockwise via the
        -- 8-param SetTexCoord form. The matching POSITION rotation lives
        -- in gen_wmo_tiles.js -- baked directly into how local
        -- coordinates become a world/Big position (a single, always-
        -- correct-by-construction transform, not a separate runtime step
        -- here -- see that script's own comment for the derivation). This
        -- content rotation is unrelated to the (separate, already-correct)
        -- Y-flip also in that script, which arranges which raw block goes
        -- in which grid slot -- this is a real, additional orientation fix
        -- on top of that.
        tex:SetTexCoord(0, 1, 1, 1, 0, 0, 1, 0);
        gf.textures[k] = tex;
    end

    return tex;
end

-- Draw order = wow.export's own (src/js/wmo-minimap.js): groups sorted by
-- the lowest Z of the group's bounding box, ascending, higher groups drawn
-- on top; equal keys keep their data order. Draw order among textures in
-- the same layer AND sublevel is undefined in WoW's UI engine, and a
-- sublevel only offers 16 steps (real dungeons stack 30+ groups), so each
-- group gets its own frame whose frame level is its rank in that order.
--
-- frame.wmoOverlayHeightCutoff (runtime-only, set by the height slider
-- below; not persisted -- height ranges are per-map, so a leftover
-- absolute value from a previous map wouldn't mean anything) hides any
-- tile whose own placement height is above it, letting a multi-level map's
-- upper layer be peeled back to see what's underneath. nil means "no
-- cutoff, show everything" -- deliberately not just "set to the map's own
-- max height", since a WoW Slider stores its value as a 32-bit float
-- internally while the generated height data is a full Lua double; reusing
-- the exact max-height number as the cutoff risks a tile that IS that max
-- height reading as fractionally taller than a float-rounded cutoff and
-- getting hidden at the slider's own topmost position.
-- TWM_WMO_OVERLAY_HEIGHT_EPSILON below is a second line of defense for
-- every other (non-nil) comparison.
local TWM_WMO_OVERLAY_HEIGHT_EPSILON = 0.05;

-- Debug ("/twm debug"): a colored border per WMO tile, so overlapping/
-- adjacent tiles can be told apart on sight. Color is picked from this
-- small fixed pool purely by the group's draw rank (the same rank that
-- sets its frame level), so all tiles of a group share one color -- cycling
-- via modulo once the group count exceeds the pool.
local TWM_WMO_DEBUG_COLOR_POOL = {
    {1, 0, 0},     -- red
    {0, 1, 0},     -- green
    {0.2, 0.4, 1}, -- blue
    {1, 1, 0},     -- yellow
    {1, 0, 1},     -- magenta
    {1, 1, 1},     -- white
    {1, 0.5, 0},   -- orange
    {0, 1, 1},     -- cyan
};

-- Whether `map` has any real ADT terrain at all -- Twm_WDTValidTiles[map] is
-- written (mapdata_tiles.lua, parse_wdt.js) for EVERY map this addon knows
-- about, including pure-WMO dungeons/raids, but as an EMPTY table for one of
-- those (nothing for parse_wdt.js's own tile scan to find) -- so presence
-- alone isn't enough, must check it's non-empty.
function TWM_MapHasTerrain(map)
    local tiles = Twm_WDTValidTiles[map];
    return tiles ~= nil and next(tiles) ~= nil;
end

-- Whether the base terrain tile grid (TWMFrameTemplate:SetLocation) should
-- draw for frame's current map. The "Show Terrain"/"Show WMO Layers"
-- checkbox pair (TWM_UpdateOverlayButtons) only exists, and only matters,
-- for a map that genuinely has BOTH real terrain and baked WMO tiles -- a
-- map with only one of the two always draws that one, unconditionally,
-- regardless of either persisted option.
function TWM_ShouldShowTerrain(frame)
    local map = frame.opt.Map;
    if(not TWM_MapHasTerrain(map)) then return false; end
    if(not (Twm_WMOTiles and Twm_WMOTiles[map])) then return true; end
    return frame.opt.ShowTerrain ~= false;
end

function TWM_ShouldShowWMOOverlay(frame)
    local map = frame.opt.Map;
    if(not (Twm_WMOTiles and Twm_WMOTiles[map])) then return false; end
    if(not TWM_MapHasTerrain(map)) then return true; end
    return frame.opt.ShowWMOOverlay and true or false;
end

local function TWM_WMOOverlay_HideGroupFrame(gf)
    gf:Hide();
    for _, tex in ipairs(gf.textures) do
        tex:Hide();
        TWM_HideTileDebugBorder(tex);
    end
end

function TWM_WMOOverlay_Update(frame)
    local lm = frame:GetName();
    local vf = _G[lm.."ViewFrame"];
    local groups = Twm_WMOTiles and Twm_WMOTiles[frame.opt.Map];

    if(not groups or not TWM_ShouldShowWMOOverlay(frame)) then
        for _, gf in ipairs(frame.wmoGroupFrames or {}) do
            TWM_WMOOverlay_HideGroupFrame(gf);
        end
        return;
    end

    -- Twm_WMOTiles[map] is an array of {group_id, group_name, tiles}
    -- (WMO tile group management -- TWM_IsWMOGroupEnabled/
    -- TWM_EnsureWMOGroupCheckboxes). Every ENABLED group is ranked by its
    -- own height (all tiles of a group share the same tile[7]); equal
    -- heights keep their data order, so the ranking is stable. Ranking has
    -- to happen AFTER this filter, not be baked in at generation time, since
    -- which groups are even visible depends on live checkbox state, not just
    -- the (still independent, still applied per-tile below) height cutoff.
    local ordered = {};
    for gi, group in ipairs(groups) do
        if(group.tiles[1] and TWM_IsWMOGroupEnabled(frame, group.group_id)) then
            tinsert(ordered, {group = group, z = group.tiles[1][7] or 0, order = gi});
        end
    end
    table.sort(ordered, function(a, b)
        if(a.z ~= b.z) then return a.z < b.z; end
        return a.order < b.order;
    end);

    local Lx, Ly = frame.viewX or frame.opt.Location[1], frame.viewY or frame.opt.Location[2];
    local z = frame:GetZoom();
    local cutoff = frame.wmoOverlayHeightCutoff;
    local baseLevel = vf:GetFrameLevel() + 1;
    local debugFrame = TWM_DebugTiles and TWM_WMOOverlay_EnsureDebugFrame(frame, vf) or nil;

    for rank, entry in ipairs(ordered) do
      local gf = TWM_WMOOverlay_EnsureGroupFrame(frame, vf, rank);
      -- Stays below the debug frame (vf + TWM_WMO_FRAME_BAND) whatever the group count.
      gf:SetFrameLevel(baseLevel + math.min(rank - 1, TWM_WMO_FRAME_BAND - 3));
      gf:Show();
      local tiles = entry.group.tiles;
      for k, tile in ipairs(tiles) do
        local tex = TWM_WMOOverlay_EnsureTexture(gf, k);
        local zval = tile[7];

        if(cutoff and zval and zval > cutoff + TWM_WMO_OVERLAY_HEIGHT_EPSILON) then
            tex:Hide();
            TWM_HideTileDebugBorder(tex);
        else
            -- {fileID, cx, cy, width, height, yawDeg, z} -- see
            -- scripts/gen_wmo_tiles.js's header for the tuple shape and the
            -- yawDeg sign derivation. width/height are the tile's true
            -- on-screen (map-space) footprint, i.e. the RAW BLP's own
            -- width/height converted to map units (unswapped -- confirmed by
            -- construction: each is a hypot between two corners differing in
            -- only one local axis, and rotation preserves that magnitude
            -- regardless of yaw).
            local fileID, cx, cy, w, h, yawDeg = tile[1], tile[2], tile[3], tile[4], tile[5], tile[6];
            local mx, my = TWM_Big2Mini_Coord(cx, cy);
            local mw, mh = w/MINI2BIGX, h/MINI2BIGY;
            -- TWM_WMOOverlay_EnsureTexture's fixed SetTexCoord(0,1, 1,1,
            -- 0,0, 1,0) doesn't just rotate the displayed content 90 degrees
            -- -- it also TRANSPOSES which frame axis samples which raw-image
            -- axis (frame width <- raw image's own HEIGHT/V axis, frame
            -- height <- raw image's own WIDTH/U axis). Invisible for years
            -- because every tile used to be a full, always-square 256x256
            -- block (mw == mh); the first non-square (real BLP-cropped) tile
            -- -- Tol'Viron Arena's bridge -- is what exposed it: the
            -- Line-based debug border (built straight from world-space
            -- corners, untouched by this) matched, but the actual texture
            -- content was stretched into the wrong (unswapped) box. Swap
            -- here to match SetTexCoord's own transpose.
            mw, mh = mh, mw;

            -- Stacking comes from the group frame's level (see above), not
            -- from this texture's own draw layer.
            tex:SetTexture(fileID);
            tex:ClearAllPoints();
            tex:SetPoint("CENTER", vf, "TOPLEFT", (mx-Lx)*z, (Ly-my)*z);
            tex:SetWidth(mw*z);
            tex:SetHeight(mh*z);
            -- Negated relative to yawDeg: the mini->screen Y conversion
            -- ((Ly-my)*z, the only asymmetric/reflecting step in the whole
            -- Big->screen chain) inverts the direction of any further
            -- rotation applied after it. yawDeg was already negated once so
            -- the tile's CORNERS (computed before that reflection, then
            -- carried through it) land in the right place; SetRotation
            -- rotates the texture directly in already-reflected screen
            -- space, so it needs the opposite sign to end up matching those
            -- same corners.
            tex:SetRotation(math.rad(-(yawDeg or 0)), {x = 0.5, y = 0.5});
            tex:Show();

            if(TWM_DebugTiles) then
                -- Drawn from the tile's own real corners (tile[8..15]),
                -- independent of the SetPoint/SetRotation call above -- see
                -- TWM_PositionWMODebugCorners' own header for why.
                local color = TWM_WMO_DEBUG_COLOR_POOL[((rank - 1) % #TWM_WMO_DEBUG_COLOR_POOL) + 1];
                local corners = { tile[8], tile[9], tile[10], tile[11], tile[12], tile[13], tile[14], tile[15] };
                local lines = TWM_EnsureWMODebugCorners(debugFrame, tex, color);
                TWM_PositionWMODebugCorners(lines, vf, corners, Lx, Ly, z);
                local label = TWM_EnsureWMODebugLabel(debugFrame, tex, color);
                TWM_PositionWMODebugLabel(label, vf, corners, Lx, Ly, z, fileID);
            else
                TWM_HideWMODebugCorners(tex);
                TWM_HideWMODebugLabel(tex);
            end
        end
      end

      for k = #tiles + 1, #gf.textures do
        gf.textures[k]:Hide();
        TWM_HideTileDebugBorder(gf.textures[k]);
      end
    end

    for rank = #ordered + 1, #(frame.wmoGroupFrames or {}) do
        TWM_WMOOverlay_HideGroupFrame(frame.wmoGroupFrames[rank]);
    end
end

-- Lazily creates the horizontal height-cutoff slider, anchored to the left
-- of the ViewFrame's BOTTOMRIGHT corner, above the resize grip -- a fixed
-- position, independent of the WMO group checkbox
-- list's own height. Built purely in Lua (OptionsSliderTemplate reused
-- from Settings.lua's own convention) since its value range is per-map
-- (set by TWM_UpdateOverlayButtons).
--
-- Parented to `frame` (TWMFrame), not the ViewFrame, strata "DIALOG" --
-- ViewFrame's own SetClipsChildren(true) would otherwise clip it.
--
-- Horizontal, not vertical: a horizontal Slider's own default already puts
-- its minimum at the LEFT and maximum at the RIGHT, so "rightmost =
-- tallest" needs no value negation (SetReverseValues doesn't exist on this
-- client, and a vertical Slider defaults the opposite way).
function TWM_WMOOverlay_EnsureHeightSlider(frame)
    local lm = frame:GetName();
    local name = lm.."WMOOverlayHeightSlider";
    local slider = _G[name];
    if(not slider) then
        slider = CreateFrame("Slider", name, frame, "OptionsSliderTemplate");
        slider:SetFrameStrata("DIALOG");
        slider:SetOrientation("HORIZONTAL");
        slider:SetSize(120, 16);
        slider:SetHitRectInsets(0, 0, 0, 0);
        -- OptionsSliderTemplate's own default thumb art
        -- (UI-SliderBar-Button-Horizontal) is already the right shape for a
        -- horizontal bar -- no texture swap needed here (that swap only
        -- existed because this used to be a vertical slider).
        --
        -- Its baked-in Low/High labels would read as plain min/max numbers
        -- either side of the thumb -- blanked; the name shows as a tooltip.
        _G[name.."Low"]:SetText("");
        _G[name.."High"]:SetText("");
        _G[name.."Text"]:SetText("");

        slider:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP");
            GameTooltip:SetText(TWM_WMO_HEIGHT_CUTOFF);
            GameTooltip:Show();
        end);
        slider:SetScript("OnLeave", function()
            GameTooltip:Hide();
        end);

        slider:SetScript("OnValueChanged", function(self, value)
            local _, sliderMax = self:GetMinMaxValues();
            if(value >= sliderMax - TWM_WMO_OVERLAY_HEIGHT_EPSILON) then
                -- Rightmost position: never filter, full stop -- see this
                -- function's own header comment for why nil (not sliderMax
                -- itself) is what "show everything" means here.
                frame.wmoOverlayHeightCutoff = nil;
            else
                frame.wmoOverlayHeightCutoff = value;
            end
            TWM_WMOOverlay_Update(frame);
        end);
    end

    slider:ClearAllPoints();
    -- Right end of the footer strip, clear of the resize grip, centered vertically.
    slider:SetPoint("RIGHT", _G[lm.."Footer"], "RIGHT", -24, 0);

    return slider;
end

-- Whether the given WMO group (group_id, a string) is enabled for `frame`'s
-- current map -- runtime-only, never persisted, reset to "every group
-- enabled" on every map switch and on the frame being shown again (see its
-- OnShow hook). Absence from the table means enabled -- a freshly-reset
-- empty table already reads as "everything checked".
function TWM_IsWMOGroupEnabled(frame, groupId)
    return not (frame.wmoGroupEnabled and frame.wmoGroupEnabled[groupId] == false);
end

function TWMFrameWMOGroupButton_OnClick(self)
    local frame = self.twmFrame;
    frame.wmoGroupEnabled[self.groupId] = self:GetChecked() and true or false;
    TWM_WMOOverlay_Update(frame);
end

-- Fixed viewport height for the WMO group checkbox list (below) -- a map
-- with many WMO placements can have dozens of groups; capping this keeps
-- the height-cutoff slider anchored elsewhere from ever depending on the
-- list's own length. No backdrop/border on the scroll frame or its
-- content -- reads as a plain checkbox list, not a bordered panel.
local TWM_WMO_GROUP_LIST_MAX_HEIGHT = 180;
local TWM_WMO_GROUP_ROW_HEIGHT = 24;
local TWM_WMO_GROUP_CONTENT_WIDTH = 220;
-- The list hangs from the ViewFrame's TOPRIGHT corner, below the header
-- strip (TWM_WMO_GROUP_LIST_TOP), shifted left by this amount (plus an 8px
-- margin) so the checkbox column and scrollbar stay inside the window.
local TWM_WMO_GROUP_LIST_RIGHT_INSET = 24;
local TWM_WMO_GROUP_LIST_TOP = 40;

-- Lazily creates the scrollable list's own frames (scroll frame + content +
-- scrollbar) -- pooled per `frame`, same convention as everything else
-- here. Parented to `frame` (TWMFrame), not the ViewFrame, strata "DIALOG"
-- -- ViewFrame's own SetClipsChildren(true) would otherwise clip it. The
-- ScrollFrame's own clipping (built into the frame type) is what hides
-- scrolled-out rows.
--
-- Scrollbar is `UIPanelScrollBarTemplate` (a real vertical scrollbar, not
-- `OptionsSliderTemplate` reused vertically -- that one's groove art is a
-- fixed-size, CENTER-anchored texture that never stretches to fit a tall
-- narrow bar). Its own up/down arrow buttons are anchored OUTSIDE the
-- slider's declared rect (up button's BOTTOM == slider's TOP, down
-- button's TOP == slider's BOTTOM) -- they extend the control above/below
-- whatever height the slider is given, not consume space within it.
-- TWM_WMO_GROUP_SCROLLBAR_ARROW_HEIGHT reserves room for both, so the
-- whole control (arrows + track) fits inside TWM_WMO_GROUP_LIST_MAX_HEIGHT
-- instead of the up-arrow overlapping the row above.
local TWM_WMO_GROUP_SCROLLBAR_ARROW_HEIGHT = 16;

function TWM_EnsureWMOGroupScrollFrame(frame)
    if(frame.wmoGroupScroll) then return frame.wmoGroupScroll, frame.wmoGroupScrollContent, frame.wmoGroupScrollBar; end
    local lm = frame:GetName();

    local scroll = CreateFrame("ScrollFrame", lm.."WMOGroupScrollFrame", frame);
    scroll:SetFrameStrata("DIALOG");
    scroll:SetWidth(TWM_WMO_GROUP_CONTENT_WIDTH);

    local content = CreateFrame("Frame", lm.."WMOGroupScrollContent", scroll);
    content:SetWidth(TWM_WMO_GROUP_CONTENT_WIDTH);
    content:SetHeight(1);
    content:SetPoint("TOPLEFT");
    scroll:SetScrollChild(content);

    local scrollbar = CreateFrame("Slider", lm.."WMOGroupScrollBar", frame, "UIPanelScrollBarTemplate");
    scrollbar:SetFrameStrata("DIALOG");
    scrollbar:SetValueStep(TWM_WMO_GROUP_ROW_HEIGHT);
    scrollbar:SetScript("OnValueChanged", function(self, value)
        scroll:SetVerticalScroll(value);
    end);
    scroll:EnableMouseWheel(true);
    scroll:SetScript("OnMouseWheel", function(self, delta)
        local lo, hi = scrollbar:GetMinMaxValues();
        scrollbar:SetValue(math.max(lo, math.min(hi, scrollbar:GetValue() - delta * TWM_WMO_GROUP_ROW_HEIGHT)));
    end);

    frame.wmoGroupScroll = scroll;
    frame.wmoGroupScrollContent = content;
    frame.wmoGroupScrollBar = scrollbar;
    return scroll, content, scrollbar;
end

-- Hides the group checkbox list entirely -- every pooled checkbox, plus
-- the scroll frame and its scrollbar (which, unlike the checkboxes, aren't
-- created at all until the first time the list has something to show, so
-- both are guarded with their own nil-checks).
function TWM_HideWMOGroupCheckboxes(frame)
    if(frame.wmoGroupButtons) then
        for _, cb in ipairs(frame.wmoGroupButtons) do cb:Hide(); end
    end
    if(frame.wmoGroupScroll) then frame.wmoGroupScroll:Hide(); end
    if(frame.wmoGroupScrollBar) then frame.wmoGroupScrollBar:Hide(); end
end

-- One checkbox per WMO group ("<group_id>: <group_name>"), inside the
-- scrollable, height-capped list above -- pooled the same way
-- TWM_WMOOverlay_EnsureGroupFrame/EnsureTexture pool the tile textures. `groups` is already
-- group_id-ascending (gen_wmo_tiles.js's own sort), so no runtime sort
-- needed here. Returns the scroll frame (fixed height regardless of group
-- count) for the height slider to anchor below.
--
-- Checkboxes/labels are children of the scroll CONTENT frame, not `frame`
-- directly -- positioned within content's own declared width (checkbox at
-- its own right edge, label to its left, same convention as "Show
-- Terrain"/"Show WMO Layers") so the ScrollFrame's own clip (to CONTENT's
-- bounds, not `frame`'s) doesn't cut either of them off.
function TWM_EnsureWMOGroupCheckboxes(frame, groups, anchor)
    local lm = frame:GetName();
    local scroll, content, scrollbar = TWM_EnsureWMOGroupScrollFrame(frame);

    frame.wmoGroupButtons = frame.wmoGroupButtons or {};
    for i = #frame.wmoGroupButtons + 1, #groups do
        local cb = CreateFrame("CheckButton", lm.."WMOGroupButton"..i, content, "UICheckButtonTemplate");
        cb:SetFrameStrata("DIALOG");
        cb:SetSize(20, 20);
        local label = cb:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall");
        label:SetJustifyH("RIGHT");
        label:SetWidth(TWM_WMO_GROUP_CONTENT_WIDTH - 30);
        label:SetPoint("RIGHT", cb, "LEFT", -4, 1);
        cb.label = label;
        cb.twmFrame = frame;
        cb:SetScript("OnClick", TWMFrameWMOGroupButton_OnClick);
        frame.wmoGroupButtons[i] = cb;
    end

    for i, group in ipairs(groups) do
        local cb = frame.wmoGroupButtons[i];
        cb.groupId = group.group_id;
        cb.label:SetText(group.group_id..": "..group.group_name);
        cb:SetChecked(TWM_IsWMOGroupEnabled(frame, group.group_id));
        cb:ClearAllPoints();
        cb:SetPoint("TOPRIGHT", content, "TOPRIGHT", -4, -(i - 1) * TWM_WMO_GROUP_ROW_HEIGHT);
        cb:Show();
    end
    for i = #groups + 1, #frame.wmoGroupButtons do
        frame.wmoGroupButtons[i]:Hide();
    end

    local contentHeight = #groups * TWM_WMO_GROUP_ROW_HEIGHT;
    content:SetHeight(math.max(contentHeight, 1));

    scroll:ClearAllPoints();
    scroll:SetPoint("TOPRIGHT", _G[lm.."ViewFrame"], "TOPRIGHT", -(8 + TWM_WMO_GROUP_LIST_RIGHT_INSET), -TWM_WMO_GROUP_LIST_TOP);
    scroll:SetHeight(math.min(contentHeight, TWM_WMO_GROUP_LIST_MAX_HEIGHT));
    scroll:SetVerticalScroll(0);
    scroll:Show();

    -- Scrollbar only appears once the real content actually overflows the
    -- capped viewport -- not Blizzard's usual "always visible, just
    -- disabled" look.
    local overflow = contentHeight - TWM_WMO_GROUP_LIST_MAX_HEIGHT;
    if(overflow > 0) then
        scrollbar:ClearAllPoints();
        -- Offset down by one arrow-button height -- see
        -- TWM_EnsureWMOGroupScrollFrame's own header for why.
        scrollbar:SetPoint("TOPLEFT", scroll, "TOPRIGHT", 4, -TWM_WMO_GROUP_SCROLLBAR_ARROW_HEIGHT);
        scrollbar:SetHeight(TWM_WMO_GROUP_LIST_MAX_HEIGHT - 2 * TWM_WMO_GROUP_SCROLLBAR_ARROW_HEIGHT);
        scrollbar:SetMinMaxValues(0, overflow);
        scrollbar:SetValue(0);
        scrollbar:Show();
    else
        scrollbar:Hide();
    end

    return scroll;
end

-- Lays the visible footer checkboxes out left to right after the zoom button:
-- each visible one is anchored to the end of the previous visible one's
-- label, so a hidden checkbox leaves no gap.
local TWM_FOOTER_CHECK_GAP = 10;

function TWM_LayoutFooterChecks(frame)
    local lm = frame:GetName();
    local anchor, offset = _G[lm.."ZoomButton"], 4;

    for _, name in ipairs({"ShowTerrainButton", "ShowWMOOverlayButton"}) do
        local button = _G[lm..name];
        if(button:IsShown()) then
            button:ClearAllPoints();
            button:SetPoint("LEFT", anchor, "RIGHT", offset, 0);
            anchor, offset = _G[button:GetName().."Label"], TWM_FOOTER_CHECK_GAP;
        end
    end
end

-- Shows the "Show Terrain"/"Show WMO Layers" checkbox pair -- always
-- together, never one without the other -- only when the current map
-- genuinely has BOTH real ADT terrain and baked WMO tiles; only then is
-- there an actual choice to make (a map with just one of the two always
-- draws that one, unconditionally -- see TWM_ShouldShowTerrain/
-- TWM_ShouldShowWMOOverlay). Syncs each checkbox to its own persisted
-- option. The height-cutoff slider is independent of whether the
-- checkboxes are shown -- a pure-WMO map (no terrain at all) still needs
-- it whenever its own placements span more than one height, even with no
-- checkbox visible above it (it anchors below the WMO group checkbox list,
-- or the WMO checkbox itself when that list is empty/hidden, regardless of
-- whether the Show Terrain/Show WMO Layers pair itself is currently shown).
function TWM_UpdateOverlayButtons(frame)
    local lm = frame:GetName();
    local terrainButton = _G[lm.."ShowTerrainButton"];
    local wmoButton = _G[lm.."ShowWMOOverlayButton"];
    if(not terrainButton or not wmoButton) then return; end

    local map = frame.opt.Map;
    local groups = Twm_WMOTiles and Twm_WMOTiles[map];
    local hybrid = groups and TWM_MapHasTerrain(map);

    if(hybrid) then
        terrainButton:Show();
        terrainButton:SetChecked(frame.opt.ShowTerrain);
        wmoButton:Show();
        wmoButton:SetChecked(frame.opt.ShowWMOOverlay);
    else
        terrainButton:Hide();
        wmoButton:Hide();
    end
    TWM_LayoutFooterChecks(frame);

    -- Runtime-only per-group checkbox state, reset here -- see
    -- TWM_IsWMOGroupEnabled's own header for the full "when"/"why".
    frame.wmoGroupEnabled = {};

    if(groups) then
        local minH, maxH = math.huge, -math.huge;
        for _, group in ipairs(groups) do
            for _, tile in ipairs(group.tiles) do
                -- {fileID, cx, cy, width, height, yawDeg, z} -- z (world
                -- height, tile[7]) is what the cutoff slider itself
                -- filters on (TWM_WMOOverlay_Update); this used to read
                -- tile[6] (yawDeg) instead -- a real, separate bug, fixed
                -- here while touching this loop for group support anyway.
                local h = tile[7];
                if(h) then
                    if(h < minH) then minH = h; end
                    if(h > maxH) then maxH = h; end
                end
            end
        end

        if(TWMOption.WMOTileManagement) then
            TWM_EnsureWMOGroupCheckboxes(frame, groups, wmoButton);
        else
            TWM_HideWMOGroupCheckboxes(frame);
        end

        local slider = TWM_WMOOverlay_EnsureHeightSlider(frame);
        -- Default: show everything, regardless of what the slider below
        -- ends up reporting once shown -- see TWM_WMOOverlay_Update's
        -- header comment for why nil, not maxH itself, is what "no
        -- cutoff" means.
        frame.wmoOverlayHeightCutoff = nil;
        if(maxH > minH) then
            -- Horizontal slider, min at LEFT/max at RIGHT (its own real
            -- default -- see TWM_WMOOverlay_EnsureHeightSlider's own header
            -- for why that needs no negation trick here, unlike the
            -- vertical version this used to be), so this is the plain,
            -- un-negated range/value directly.
            slider:SetMinMaxValues(minH, maxH);
            slider:SetValue(maxH);
            slider:Show();
        else
            -- Only one distinct height among this map's placements --
            -- nothing meaningful for the slider to filter.
            slider:Hide();
        end
    else
        TWM_HideWMOGroupCheckboxes(frame);
        local slider = _G[lm.."WMOOverlayHeightSlider"];
        if(slider) then slider:Hide(); end
    end
end

function TWMFrameShowWMOOverlayButton_OnClick(self)
    local frame = self:GetParent():GetParent();
    frame.opt.ShowWMOOverlay = self:GetChecked() and true or false;
    TWM_WMOOverlay_Update(frame);
end

function TWMFrameShowTerrainButton_OnClick(self)
    local frame = self:GetParent():GetParent();
    frame.opt.ShowTerrain = self:GetChecked() and true or false;
    -- Terrain tile content is decided inside SetLocation's own
    -- needsContentRefresh gate (position/map/forceupdate only) -- force it
    -- so the toggle takes effect immediately instead of waiting for the
    -- next real pan/zoom.
    frame:AdjustLocation(0, 0, true);
end

-- Twm_ContinentMapID is defined in Data_<Flavor>/mapdata_poi.lua (loads before
-- this file); Twm_BattlegroundMapID (same shape, separate table -- see
-- scripts/gen_battlegrounds.js) in Data_<Flavor>/mapdata_poi_battlegrounds.lua,
-- when that flavor has one. Both feed the same reverse-index below --
-- TWM_GetContinentForMapID's parent-chain walk (and so
-- TWM_GetUnitContinentPosition's "Goto Player"/live tracking) doesn't care
-- which table a given top-level map came from, only that Twm_mapareas has a
-- [0] box for it. Battlegrounds are real, position-trackable outdoor zones
-- (unlike dungeon/raid interiors, which have no live position API at all --
-- see .claude-docs/gotchas.md), so they plug into this exactly like a
-- continent does.
local TWM_ContinentByMapID = {};
for h,v in pairs(Twm_ContinentMapID) do
    TWM_ContinentByMapID[v] = h;
end
if(Twm_BattlegroundMapID) then
    for h,v in pairs(Twm_BattlegroundMapID) do
        TWM_ContinentByMapID[v] = h;
    end
end

-- The UiMapID a top-level map name (continent OR battleground -- whichever
-- table actually has it) resolves to. Twm_ContinentMapID/Twm_BattlegroundMapID
-- stay separate data-wise (see scripts/gen_battlegrounds.js's header for why),
-- but every runtime consumer that needs "the UiMapID for this known map name"
-- -- not just TWM_ContinentByMapID's reverse direction above -- has to check
-- both, or a battleground name resolved via TWM_GetContinentForMapID ends up
-- indexing straight into Twm_ContinentMapID and quietly getting nil (this
-- exact bug, twice -- see WorldMapOverlay.lua's GetViewBigBox and this file's
-- own TWM_GetUnitContinentPosition).
function TWM_GetTopLevelMapUiMapID(name)
    local id = Twm_ContinentMapID[name];
    if(id) then return id; end
    if(Twm_BattlegroundMapID) then
        return Twm_BattlegroundMapID[name];
    end
    return nil;
end

-- Walks a uiMapID up its parent chain until it hits one of our known
-- continents (C_Map has no "give me the continent" shortcut).
function TWM_GetContinentForMapID(mapID)
    local guard = 0;
    while(mapID and guard < 10) do
        if(TWM_ContinentByMapID[mapID]) then
            return TWM_ContinentByMapID[mapID];
        end
        local info = C_Map.GetMapInfo(mapID);
        if(not info) then return nil; end
        mapID = info.parentMapID;
        guard = guard + 1;
    end
    return nil;
end

-- Our map key (Twm_DungeonNames/RaidNames/ScenarioNames key) of the
-- dungeon/raid/scenario the player is inside, or nil. GetInstanceInfo's
-- instanceID is the Map.csv ID, which the lists carry as `.mapID`.
local TWM_InstanceKeyByMapID;
local function TWM_GetInstanceMapKey(mapID)
    if(not TWM_InstanceKeyByMapID) then
        TWM_InstanceKeyByMapID = {};
        for _, list in ipairs({TWM_DUNGEONS or {}, TWM_RAIDS or {}, TWM_SCENARIOS or {}}) do
            for _, e in pairs(list) do
                if(e.mapID) then TWM_InstanceKeyByMapID[e.mapID] = e[1]; end
            end
        end
    end
    return mapID and TWM_InstanceKeyByMapID[tostring(mapID)] or nil;
end

function TWM_GetPlayerInstanceMap()
    if(not IsInInstance()) then return nil; end
    return TWM_GetInstanceMapKey((select(8, GetInstanceInfo())));
end

-- Map key of the dungeon/raid with Map.csv ID `mapID`, nil when we have no
-- visible map for it.
function TWM_GetOpenableInstanceMap(mapID)
    local key = TWM_GetInstanceMapKey(mapID);
    if(not key or TWM_IsMapHidden(tostring(mapID))) then return nil; end
    return key;
end

function TWM_OpenInstanceMap(frame, mapID)
    local key = TWM_GetOpenableInstanceMap(mapID);
    if(key) then frame:SelectMap(key); end
end

-- Replaces the old GetPlayerMapPosition(u); returns nil if the unit isn't on
-- one of TerrainWorldMap's 3 known continents (no WorldMapFrame navigation needed).
-- Returns (continent, x, y) where x/y are normalized [0,1] *within that
-- continent's own Twm_mapareas[continent][0] box* -- callers (TerrainWorldMap.lua's
-- "Goto Player", sets/players.lua) both convert via that box directly.
--
-- A few zones (Draenei/Blood Elf starting isles) are filed under a
-- *different* continent's DBC MapID than where C_Map's own uiMap hierarchy
-- nominally parents them for world-map navigation -- e.g. Azuremyst Isle is
-- a "child" of Kalimdor in C_Map's tree, but its real UiMapAssignment row
-- (Twm_UiMapID2Zone, ground truth) -- and its real WDT terrain -- is
-- filed under Expansion01/Outland. Querying GetPlayerMapPosition against
-- the hierarchy-hinted continent for these returns Blizzard's compressed
-- inset-icon position instead of a real location, which TerrainWorldMap's own terrain
-- transform then maps to nonsense (e.g. open ocean on Kalimdor). So: query
-- the immediate zone's own position when we have ground truth for it, and
-- convert through its own real box instead of blindly trusting the hint.
function TWM_GetUnitContinentPosition(u)
    local mapID = C_Map.GetBestMapForUnit(u);
    if(not mapID) then return nil; end

    local continent, zoneBox, queryMapID;

    local known = Twm_UiMapID2Zone[mapID];
    if(known) then
        continent = known[1];
        zoneBox = Twm_mapareas[continent][known[2]];
        queryMapID = mapID;
    else
        continent = TWM_GetContinentForMapID(mapID);
        if(not continent) then return nil; end
        zoneBox = Twm_mapareas[continent][0];
        queryMapID = TWM_GetTopLevelMapUiMapID(continent);
    end
    if(not zoneBox) then return nil; end

    -- Some battlegrounds (Alterac Valley, confirmed live -- unlike Warsong
    -- Gulch) have no live position data at all, same category as dungeons/
    -- raids. Still return `continent` alone (x/y nil) instead of bailing
    -- out entirely -- callers that only need "which map is the unit on"
    -- (OnWorldMapUpdateU's auto-follow, SelectMap's == comparison) can use
    -- that to at least switch to the right map; only actual dot-plotting
    -- needs to keep checking x/y for nil.
    local pos = C_Map.GetPlayerMapPosition(queryMapID, u);
    if(not pos) then return continent; end

    local nx, ny = pos:GetXY();
    local zx1,zx2,zy1,zy2 = zoneBox[1],zoneBox[2],zoneBox[3],zoneBox[4];
    local bigx = -nx*(zx1-zx2) + zx1;
    local bigy = -ny*(zy1-zy2) + zy1;

    local cbox = Twm_mapareas[continent][0];
    local cx1,cx2,cy1,cy2 = cbox[1],cbox[2],cbox[3],cbox[4];
    return continent, (cx1-bigx)/(cx1-cx2), (cy1-bigy)/(cy1-cy2);
end

TWMFrameTemplate = {};

function TWMFrame_Bootstrap(self, frame)
    --frame = TWMFrame;
    if(frame == nil) then
        frame = self;
    end

    for h,v in pairs(TWMFrameTemplate) do
        if(frame[h]) then
            frame["old_"..h] = frame[h];
        end

        frame[h] = v;
    end
    frame:OnLoad();
end

function TWMFrameTemplate:OnLoad()
    local lm = self:GetName();
    local viewframe = _G[lm.."ViewFrame"];

    self.texturelayout = {};
    self.wzoom = 3;
    self.hzoom = 3;
    self.wzoom_real = 3;
    self.hzoom_real = 3;
    self.points = {};
    self.pointframes = {};

    self:RegisterForDrag("LeftButton");
    self:RegisterEvent("VARIABLES_LOADED");
    self:RegisterEvent("ADDON_LOADED");
    viewframe:RegisterForDrag("RightButton","LeftButton");
    viewframe:EnableMouseWheel(true);

    -- Dedicated solid-black fill behind the tile grid, shown through
    -- whichever cells have no live-zone texture (see SetLocation's
    -- "no live zone" branch). BACKGROUND layer on `self`, same frame as
    -- the map tiles themselves (ARTWORK) -- that guarantees it always
    -- renders strictly below them, unlike TWMFrame's own chrome backdrop
    -- (SetBackdropColor in TWMFrame_OnLoadExtra), which is a different,
    -- unrelated region and turned out NOT to reliably show through here.
    local emptyBg = self:CreateTexture(nil, "BACKGROUND");
    emptyBg:SetColorTexture(0, 0, 0, 1);
    emptyBg:SetPoint("TOPLEFT", viewframe, "TOPLEFT", 0, 0);
    emptyBg:SetPoint("BOTTOMRIGHT", viewframe, "BOTTOMRIGHT", 0, 0);

    TWMPoints_RegisterFrame(self:GetName());

    self.update_time = 0;
end

function TWMFrame_OnLoadExtra()
    TWMFrame.TWM_PD_allocText = "TWM_PD_allocText";
    TWMFrame.TWM_PD_ResetList = "TWM_PD_ResetList";
    
    SLASH_TWM1 = "/twm";
    SlashCmdList["TWM"] = function(msg)
        if(msg == "debug") then
            TWM_ToggleTileDebug();
        elseif(msg == "map on") then
            TWM_SetWorldMapOverlay(true);
        elseif(msg == "map off") then
            TWM_SetWorldMapOverlay(false);
        else
            TWMFrame:Toggle();
        end
    end

    TWMFrame.hoverTooltip = "TWMTooltip";

    -- Thin flat border; the map view covers the rest of the frame.
    TWMFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
        insets = {left = 1, right = 1, top = 1, bottom = 1},
    });
    TWMFrame:SetBackdropColor(0, 0, 0, 1);
    TWMFrame:SetBackdropBorderColor(0.3, 0.3, 0.3, 1);

    -- The control strip and its buttons sit over the map, above everything
    -- the map hosts (see TWM_WMO_FRAME_BAND).
    TWMFrameHeader:SetFrameLevel(TWMFrameViewFrame:GetFrameLevel() + TWM_WMO_FRAME_BAND + 40);
    TWMFrameFooter:SetFrameLevel(TWMFrameViewFrame:GetFrameLevel() + TWM_WMO_FRAME_BAND + 40);
    -- The resize grip overlaps the footer's right end: above it and its children.
    TWMFrameResizeButton:SetFrameLevel(TWMFrameFooter:GetFrameLevel() + 10);

    TWMFrame:SetResizable(true);
    TWMFrame:SetResizeBounds(TWM_FRAME_MIN_WIDTH, 300);

    -- See TWM_ResetFramePosition: a size change applied while the frame
    -- is hidden doesn't actually reach the (anchor-derived) ViewFrame until
    -- the frame is shown, so the deferred zoom/tile-grid refresh happens here.
    TWMFrame:HookScript("OnShow", function(self)
        if(self.needsZoomRefreshOnShow) then
            self.needsZoomRefreshOnShow = nil;
            RefreshZoomNextFrame(self);
        end
        -- WMO tile group checkbox state is runtime-only, never persisted --
        -- resets here too (not just on an actual map switch, SetMap's own
        -- call), so closing the frame and reopening it back to the SAME
        -- map still comes back with every group checked, per spec (see
        -- TWM_IsWMOGroupEnabled).
        TWM_UpdateOverlayButtons(self);
    end);
end

-- Hooked to OnSizeChanged (fires continuously while the resize grip is
-- being dragged, not just on release) so the tile grid updates live along
-- with the frame instead of only snapping into place on mouse-up. Persists
-- the new size and recomputes the tile grid for it (SetZoom already reads
-- the view frame's live pixel size, so this is all that's needed -- no
-- separate "layout refresh" step required). Guarded against firing before
-- VARIABLES_LOADED has set up self.opt, and against reentrancy: SetZoom's
-- own GetWidth()/GetHeight() calls can force a pending layout to resolve
-- and fire ANOTHER OnSizeChanged while this call is still on the stack,
-- which without this guard recurses without end ("script ran too long").
-- The POI viewport re-cull (TWMPoints_Update, via SetZoom's points-refresh
-- path) is much pricier than the tile-grid refresh above it -- it walks
-- every visible point across every set -- so forcing it on every single
-- OnSizeChanged tick of a live drag visibly lags the resize. Instead, it
-- only actually runs once the size has moved by TWM_POINTS_RESIZE_REFRESH_STEP
-- pixels (in either dimension) since the last time it ran, plus always on
-- isFinal (the resize button's OnMouseUp) so the very last size is never
-- left stale. The tile grid still updates live every tick either way.
local TWM_POINTS_RESIZE_REFRESH_STEP = 40;
function TWMFrame_OnResizeStop(self, isFinal)
    if(not self.opt or self.inResizeRefresh) then return; end
    self.inResizeRefresh = true;
    self.opt.Width, self.opt.Height = self:GetSize();

    -- No `or w`/`or h` fallback here: that would make the very first resize
    -- of the session (lastPointsRefreshW/H still nil) always compute a 0
    -- delta against itself and never force a refresh until mouse-up --
    -- "never refreshed before" must force immediately, same as crossing the
    -- pixel threshold.
    local w, h = self.opt.Width, self.opt.Height;
    local neverRefreshed = self.lastPointsRefreshW == nil;
    local dw = not neverRefreshed and math.abs(w - self.lastPointsRefreshW) or 0;
    local dh = not neverRefreshed and math.abs(h - self.lastPointsRefreshH) or 0;
    local forcePoints = isFinal or neverRefreshed or dw >= TWM_POINTS_RESIZE_REFRESH_STEP or dh >= TWM_POINTS_RESIZE_REFRESH_STEP;
    if(forcePoints) then
        self.lastPointsRefreshW = w;
        self.lastPointsRefreshH = h;
    end

    self:SetZoom(self.opt.Zoom, true, not forcePoints);
    self.inResizeRefresh = false;
end

function TWMFrameTemplate:OnEvent(event, ...)
    local framename = self:GetName();

    if(event == "VARIABLES_LOADED") then
        if(TWMOption == nil) then
            TWMOption = {};
        end

        if(TWMOption.ShowButton == nil) then
            TWMOption.ShowButton = true;
        end

        if(TWMOption.DrawUnderwater == nil) then
            TWMOption.DrawUnderwater = true;
        end

        if(TWMOption.TileFilter == nil) then
            TWMOption.TileFilter = "NEAREST";
        end

        -- Stale saved data from before BigTWMFrame was removed.
        if(TWMOption.Frames) then
            TWMOption.Frames["BigTWMFrame"] = nil;
        end

        self:EnsureExistingOptions();

        self.opt = TWMOption.Frames[framename];

        -- Stale saved data from before IconSize became a 0.1-3.0 multiplier (was an absolute pixel size).
        if(self.opt.IconSize == nil or self.opt.IconSize > 3.5) then
            self.opt.IconSize = 1.0;
        end

        if(self.opt.Width and self.opt.Height) then
            self:SetSize(math.max(self.opt.Width, TWM_FRAME_MIN_WIDTH), self.opt.Height);
        end
        self:SetZoom(self.opt.Zoom);
        TWM_SetupDropdowns(self);
        self:SetMap(self.opt.Map);

        self:UpdateLock();
        self:SetAlpha(self.opt.Alpha);

        if(self.opt.track) then
            TWMFramePlayerJumpButton_Seek(self, self.opt.track);
        end
    end
end

function TWMFrameTemplate:EnsureExistingOptions()
    if(TWMOption.Frames == nil) then
        TWMOption.Frames = {};
    end

    local name = self:GetName();

    if(TWMOption.Frames[name] == nil) then
        TWMOption.Frames[name] = {};
    end

    for h,v in pairs(TWM_FRAME_OPTION_DEFAULTS) do
        if(TWMOption.Frames[name][h] ~= nil) then
            -- don't do anything!
        elseif(TWMOption[h] ~= nil) then
            TWMOption.Frames[name][h] = TWMOption[h];
            TWMOption[h] = nil;
        elseif(type(v) == "table") then
            -- don't copy reference.  copy value...unfortunately, we only 
            -- copy one level deep, which seems good enough...
            TWMOption.Frames[name][h] = {};
            for x,k in pairs(v) do
                TWMOption.Frames[name][h][x] = k;
            end
        else
            TWMOption.Frames[name][h] = v;
        end
    end
end

function TWMFrameTemplate:Toggle()
    local lm = self:GetName();

    if(UIPanelWindows[lm] == nil) then
        if(self:IsShown()) then
            self:Hide();
        else
            self:Show();
        end
    else
	if (self:IsVisible() ) then
	    HideUIPanel(self);
	else
            -- SetupWorldMapScale();
            ShowUIPanel(self);
	end
    end
end

function TWM_GetSortedMapNames()
    local names = {};
    for h in pairs(TWM_MAPS) do
        tinsert(names, h);
    end
    table.sort(names);
    return names;
end

-- TWM_BATTLEGROUNDS (Data_<Flavor>/mapdata_poi_battlegrounds.lua) doesn't
-- exist at all for a flavor with no generated battleground data yet --
-- guarded the same way TWM_HasNoLiquidData-style optional tables are
-- elsewhere in this addon.
function TWM_GetSortedBattlegroundNames()
    local names = {};
    if(TWM_BATTLEGROUNDS) then
        for h in pairs(TWM_BATTLEGROUNDS) do
            tinsert(names, h);
        end
        table.sort(names);
    end
    return names;
end

-- TWM_ARENAS/TWM_DUNGEONS/TWM_RAIDS/TWM_SCENARIOS never get built above
-- (stay nil) for a flavor/category with no entries (e.g. Vanilla has no
-- Twm_ArenaNames at all; only Mists has Twm_ScenarioNames) -- all four
-- guarded the same way.
function TWM_GetSortedArenaNames()
    local names = {};
    if(TWM_ARENAS) then
        for h in pairs(TWM_ARENAS) do
            tinsert(names, h);
        end
        table.sort(names);
    end
    return names;
end

function TWM_GetSortedDungeonNames()
    local names = {};
    if(TWM_DUNGEONS) then
        for h, e in pairs(TWM_DUNGEONS) do
            if(not TWM_IsMapHidden(e.mapID)) then tinsert(names, h); end
        end
        table.sort(names);
    end
    return names;
end

function TWM_GetSortedRaidNames()
    local names = {};
    if(TWM_RAIDS) then
        for h, e in pairs(TWM_RAIDS) do
            if(not TWM_IsMapHidden(e.mapID)) then tinsert(names, h); end
        end
        table.sort(names);
    end
    return names;
end

function TWM_GetSortedScenarioNames()
    local names = {};
    if(TWM_SCENARIOS) then
        for h, e in pairs(TWM_SCENARIOS) do
            if(not TWM_IsMapHidden(e.mapID)) then tinsert(names, h); end
        end
        table.sort(names);
    end
    return names;
end

-- Distinct .expansion values actually present in `list` (TWM_DUNGEONS/
-- TWM_RAIDS), sorted numerically -- Map.db2's ExpansionID is release order
-- by construction (0=Classic, 1=The Burning Crusade, ...), and a numeric
-- sort (not a string one) keeps that true once an ID reaches double digits.
function TWM_GetSortedExpansionIDs(list)
    local seen, ids = {}, {};
    if(list) then
        for _, entry in pairs(list) do
            local expID = entry.expansion;
            if(expID and not seen[expID] and not TWM_IsMapHidden(entry.mapID)) then
                seen[expID] = true;
                tinsert(ids, expID);
            end
        end
        table.sort(ids, function(a, b) return tonumber(a) < tonumber(b); end);
    end
    return ids;
end

-- TWM_EXPANSION_<N> (Locale/*.lua) is the official expansion title as it
-- actually appears in this client's own data (confirmed via Achievement_Category,
-- not guessed/fan-translated) -- most locales keep the English title
-- untranslated (Blizzard's own convention, e.g. ruRU/deDE), falls back to a
-- plain "Expansion N" for an ID this addon hasn't got a name for yet.
function TWM_GetExpansionName(expID)
    return _G["TWM_EXPANSION_" .. tostring(expID)] or ("Expansion " .. tostring(expID));
end

-- The left dropdown's category tree (Dungeons > <expansion> > map, ...) for
-- non-continent maps: `tiered` categories have the expansion level when the
-- flavor has more than one expansion.
local TWM_MAP_GROUPS = {
    {list = "TWM_DUNGEONS", names = TWM_GetSortedDungeonNames, title = "TWM_CATEGORY_DUNGEONS", tiered = true},
    {list = "TWM_RAIDS", names = TWM_GetSortedRaidNames, title = "TWM_CATEGORY_RAIDS", tiered = true},
    {list = "TWM_SCENARIOS", names = TWM_GetSortedScenarioNames, title = "TWM_CATEGORY_SCENARIOS"},
    {list = "TWM_BATTLEGROUNDS", names = TWM_GetSortedBattlegroundNames, title = "TWM_CATEGORY_BATTLEGROUNDS"},
    {list = "TWM_ARENAS", names = TWM_GetSortedArenaNames, title = "TWM_CATEGORY_ARENAS"},
};

-- For a non-continent map: the text the left dropdown shows ("Dungeons" or
-- "Dungeons: Vanilla") and the maps of that same group, as {name=, key=}
-- sorted by name (they fill the right dropdown). nil for continents.
function TWM_GetMapGroup(mapname)
    for _, c in ipairs(TWM_MAP_GROUPS) do
        local list = _G[c.list];
        for _, e in pairs(list or {}) do
            if(e[1] == mapname) then
                local text, group = _G[c.title], {};
                local exp = c.tiered and e.expansion or nil;
                for _, name in ipairs(c.names()) do
                    local ne = list[name];
                    if(not exp or ne.expansion == exp) then
                        tinsert(group, {name = name, key = ne[1], mapID = ne.mapID});
                    end
                end
                if(exp and #TWM_GetSortedExpansionIDs(list) > 1) then
                    text = text .. ": " .. TWM_GetExpansionName(exp);
                end
                return text, group;
            end
        end
    end
    return nil;
end

-- The header dropdowns are Blizzard_Menu DropdownButtons (WowStyle1Dropdown).
-- Their displayed text is always set explicitly (TWM_SetDropdownText), never
-- derived from the selected radio.
local TWM_MENU_MAX_HEIGHT = 400;

-- OverrideText ignores selection state; skip the redundant calls made on every pan.
local function TWM_SetDropdownText(dropdown, text)
    if(dropdown:GetText() ~= text) then
        dropdown:OverrideText(text);
    end
end

local function TWM_PickMap(mapname)
    _G["TWMFrame"]:SelectMap(mapname);
end

local function TWM_IsCurrentMap(mapname)
    return _G["TWMFrame"].opt.Map == mapname;
end

local function TWM_AddMapRadio(menu, text, mapname, mapID, onPick)
    if(TWM_IsDevelopmentMap(mapID)) then
        text = TWM_DEV_MAP_COLOR .. text .. "|r";
    end
    return menu:CreateRadio(text, TWM_IsCurrentMap, onPick or TWM_PickMap, mapname);
end

-- Submenu with one radio per map of `list` (names = sorted keys of it).
-- `expID` restricts it to one expansion.
local function TWM_FillMapMenu(menu, names, list, expID)
    menu:SetScrollMode(TWM_MENU_MAX_HEIGHT);
    for _, h in ipairs(names) do
        local e = list[h];
        if(not expID or e.expansion == expID) then
            TWM_AddMapRadio(menu, h, e[1], e.mapID);
        end
    end
end

-- Blizzard_Menu opens a submenu 0.33s (hardcoded, private) after the cursor
-- enters its button. A submenu button opens it itself after this shorter delay;
-- the delay keeps a diagonal move across sibling rows from opening them.
local TWM_SUBMENU_OPEN_DELAY = 0.1;

local function TWM_CreateSubmenuButton(menu, title)
    local button = menu:CreateButton(title);
    button:SetOnEnter(function(frame, description)
        C_Timer.After(TWM_SUBMENU_OPEN_DELAY, function()
            if(frame:IsVisible() and frame:IsMouseOver()) then
                description:ForceOpenSubmenu();
            end
        end);
    end);
    return button;
end

local function TWM_AddMapCategory(root, title, names, list)
    if(#names == 0) then return; end
    TWM_FillMapMenu(TWM_CreateSubmenuButton(root, title), names, list);
end

-- Dungeons/raids: an expansion level first (Map.db2's ExpansionID, see
-- TWM_GetSortedExpansionIDs), skipped when the flavor has only one expansion.
local function TWM_AddInstanceCategory(root, title, names, list)
    local expIDs = TWM_GetSortedExpansionIDs(list);
    if(#expIDs == 0) then return; end

    local menu = TWM_CreateSubmenuButton(root, title);
    if(#expIDs == 1) then
        TWM_FillMapMenu(menu, names, list, expIDs[1]);
    else
        for _, expID in ipairs(expIDs) do
            TWM_FillMapMenu(TWM_CreateSubmenuButton(menu, TWM_GetExpansionName(expID)), names, list, expID);
        end
    end
end

-- Left dropdown: the category tree (Continents / Dungeons / Raids /
-- Scenarios / Battlegrounds / Arenas).
local function TWM_GenerateMapMenu(dropdown, root)
    TWM_AddMapCategory(root, TWM_CATEGORY_CONTINENTS, TWM_GetSortedMapNames(), TWM_MAPS);
    if(TWM_DUNGEONS) then
        TWM_AddInstanceCategory(root, TWM_CATEGORY_DUNGEONS, TWM_GetSortedDungeonNames(), TWM_DUNGEONS);
    end
    if(TWM_RAIDS) then
        TWM_AddInstanceCategory(root, TWM_CATEGORY_RAIDS, TWM_GetSortedRaidNames(), TWM_RAIDS);
    end
    if(TWM_SCENARIOS) then
        TWM_AddMapCategory(root, TWM_CATEGORY_SCENARIOS, TWM_GetSortedScenarioNames(), TWM_SCENARIOS);
    end
    if(TWM_BATTLEGROUNDS) then
        TWM_AddMapCategory(root, TWM_CATEGORY_BATTLEGROUNDS, TWM_GetSortedBattlegroundNames(), TWM_BATTLEGROUNDS);
    end
    if(TWM_ARENAS) then
        TWM_AddMapCategory(root, TWM_CATEGORY_ARENAS, TWM_GetSortedArenaNames(), TWM_ARENAS);
    end
end

-- What actually runs when a map is picked from the dropdown -- as opposed to
-- SetMap's other callers (e.g. OnWorldMapUpdateU's own player-centering
-- flow), which already know exactly where they want to end up and shouldn't
-- be second-guessed here. If the player is actually on the map just picked
-- *and* "Zoom to Player on Show" is enabled for this window, centers on the
-- player (the same jump the Goto Player button does); otherwise fits the
-- map's first registered zone if it has any (a continent), or the whole
-- map otherwise (a battleground) -- the previous zoom/position was tuned
-- for whatever map was showing before, and can leave the new one too tiny
-- or scrolled off-screen to find.
function TWMFrameTemplate:SelectMap(mapname)
    self:SetMap(mapname);

    local opt = TWMOption.Frames[self:GetName()];
    if(opt and opt.trackonshow and TWM_GetUnitContinentPosition("player") == mapname) then
        self.trackseek = "player";
        self:OnWorldMapUpdateU("player");
    else
        -- Not tracking the player here -- fit whatever box gives the most
        -- useful view. A map with real registered zones (a continent) fits
        -- its first one (self.zonepulldowns, same "first zone" used by
        -- SetMap's own jump-to-first-zone fallback below) rather than the
        -- whole continent zoomed all the way out; a flat map with none (a
        -- battleground) falls back to its own [0] whole-map box.
        self:FitMapToViewport(mapname, self.zonepulldowns and self.zonepulldowns[1]);
    end
end

-- Zooms/centers so `zoneKey`'s box (default: the map's own [0] whole-map
-- box) fills the viewport, with a little margin so its edges aren't flush
-- against the window's own border.
function TWMFrameTemplate:FitMapToViewport(mapname, zoneKey)
    local box = Twm_mapareas[mapname] and Twm_mapareas[mapname][zoneKey or 0];
    if(not box) then return; end

    local lm = self:GetName();
    local viewframe = _G[lm.."ViewFrame"];
    local vw, vh = viewframe:GetWidth(), viewframe:GetHeight();
    if(vw <= 0 or vh <= 0) then return; end

    local bigWidth, bigHeight = box[1]-box[2], box[3]-box[4];
    local miniWidth, miniHeight = bigWidth/MINI2BIGX, bigHeight/MINI2BIGY;
    if(miniWidth <= 0 or miniHeight <= 0) then return; end

    local MARGIN = 0.9; -- a little breathing room around the map's own edges
    local wantedZoom = math.min(vw/miniWidth, vh/miniHeight) * MARGIN;

    self:SetZoom(wantedZoom, true);
    -- SetZoom can clamp/adjust what we asked for (the ~32 hard floor, or its
    -- own "too zoomed in for this viewport size" recursion) -- read back
    -- whatever it actually settled on instead of trusting wantedZoom, or the
    -- position math below would be centered for a zoom level that isn't the
    -- one actually applied.
    local zoom = self:GetZoom();
    local cx, cy = TWM_Big2Mini_Coord((box[1]+box[2])/2, (box[3]+box[4])/2);
    self:SetLocation(cx-(vw/2)/zoom, cy-(vh/2)/zoom);
end

function TWMFrameTemplate:ToggleLock()
    if(self.opt.Locked) then
        self.opt.Locked = false;
    else
        self.opt.Locked = true;
    end   
    self:UpdateLock();
end

function TWMFrameTemplate:UpdateLock()
    local fm = self:GetName();
    local norm = _G[fm.."LockButtonNorm"];
    local push = _G[fm.."LockButtonPush"];

    if(norm and push) then
        if(self.opt.Locked) then
            norm:SetTexture("Interface\\AddOns\\TerrainWorldMap\\images\\LockButton-Locked-Up");
            push:SetTexture("Interface\\AddOns\\TerrainWorldMap\\images\\LockButton-Locked-Down");
        else
            norm:SetTexture("Interface\\AddOns\\TerrainWorldMap\\images\\LockButton-Unlocked-Up");
            push:SetTexture("Interface\\AddOns\\TerrainWorldMap\\images\\LockButton-Unlocked-Down");
        end
    end
end

function TWMFrameTemplate:SetMap(mapname)
    local lm = self:GetName();

    self.opt.Map = mapname;
    self.mapGroupText, self.mapGroup = TWM_GetMapGroup(mapname);

    TWM_UpdateOverlayButtons(self);

    -- The left dropdown shows the continent, or for any other map the group
    -- (category and expansion); the right one lists the continent's zones or
    -- the group's maps.
    local mapdropdown = _G[lm.."DropDown"];
    if(mapdropdown) then
        local caption = self.mapGroupText;
        if(not caption) then
            for h in pairs(TWM_MAPS) do
                if(TWM_MAPS[h][1] == mapname) then caption = h; end
            end
        end
        if(caption) then
            TWM_SetDropdownText(mapdropdown, caption);
        end
    end

    -- Recomputed here for the map being switched to: SelectMap's
    -- FitMapToViewport and the jump-to-first-zone fallback below read it.
    self.zonepulldowns = TWM_BuildZonePulldowns(mapname);

    self:AdjustLocation(0,0,true);

    -- the previous view location likely doesn't correspond to anything on
    -- the new continent; if so, jump to the first zone instead of leaving
    -- the view (and zone dropdown) sitting on empty space.
    if(self.zonepulldowns and self.zonepulldowns[1]) then
        local zid = self:GetZoneIDs();
        local found = false;
        for i,v in ipairs(self.zonepulldowns) do
            if(v == zid) then
                found = true;
                break;
            end
        end

        if(not found) then
            self:CenterOnZone(self.zonepulldowns[1]);
        end
    end

    TWMPoints_OnMapChange(self);
    self.lastmap = self.opt.Map;
end

-- Sorted list of Twm_areadb zone IDs registered for `map` in Twm_mapareas
-- (real named sub-zones, e.g. a continent's -- dungeons/raids/scenarios/
-- arenas/battlegrounds have none). Shared by the zone menu and SetMap.
function TWM_BuildZonePulldowns(map)
    local list = {};
    if(Twm_mapareas[map] ~= nil) then
        for h,v in pairs(Twm_mapareas[map]) do
            if(Twm_areadb[h]) then
                tinsert(list, h);
            end
        end
    end
    table.sort(list, function (a,b) return Twm_areadb[a] < Twm_areadb[b]; end);
    return list;
end


function TWMFrameTemplate:CenterOnZone(z)
    local map = self.opt.Map;
    local zoom = self:GetZoom();

    if(not z or not Twm_mapareas[map] or
            type(Twm_mapareas[map][z]) ~= "table") then
        return;
    end

    local x = (Twm_mapareas[map][z][1]+
       Twm_mapareas[map][z][2])/2;
    local y = (Twm_mapareas[map][z][3]+
       Twm_mapareas[map][z][4])/2;

    local mx, my = TWM_Big2Mini_Coord(x,y);

    local viewframe = _G[self:GetName().."ViewFrame"];
    local vw, vh = viewframe:GetWidth(), viewframe:GetHeight();

    self:SetLocation(mx-(vw/2)/zoom, my-(vh/2)/zoom);
end

local function TWM_PickZone(zoneID)
    local frame = _G["TWMFrame"];
    frame:CenterOnZone(zoneID);

    -- SetLocation() re-derives the zone from the new view's center
    -- (GetZoneIDs picks the smallest box containing it), which isn't
    -- guaranteed to be the zone just picked; show the picked one.
    TWM_SetDropdownText(_G[frame:GetName().."DropDown2"], Twm_areadb[zoneID]);
end

-- Right dropdown: the zones of a continent, or for any other map the maps of
-- its group.
local function TWM_GenerateZoneMenu(dropdown, root)
    local frame = _G["TWMFrame"];
    root:SetScrollMode(TWM_MENU_MAX_HEIGHT);

    if(frame.mapGroup) then
        for _, g in ipairs(frame.mapGroup) do
            TWM_AddMapRadio(root, g.name, g.key, g.mapID, function(key)
                if(key ~= frame.opt.Map) then TWM_PickMap(key); end
            end);
        end
        return;
    end

    frame.zonepulldowns = TWM_BuildZonePulldowns(frame.opt.Map);
    local currentZone = frame:GetZoneIDs();
    for _, z in ipairs(frame.zonepulldowns) do
        root:CreateRadio(Twm_areadb[z], function(id) return id == currentZone; end, TWM_PickZone, z);
    end
end

function TWM_SetupDropdowns(frame)
    local lm = frame:GetName();
    _G[lm.."DropDown"]:SetupMenu(TWM_GenerateMapMenu);
    _G[lm.."DropDown2"]:SetupMenu(TWM_GenerateZoneMenu);
end

function TWMFrameTemplate:UpdateDropDown2()
    local dd2 = _G[self:GetName().."DropDown2"];
    if(not (dd2 and self.zonepulldowns)) then return; end

    -- Non-continent map: this map within its group. Continent: the zone
    -- under the view center; blank when there is none (e.g. panned past the
    -- map edge) rather than snapping the view somewhere else mid-drag.
    local text = "";
    if(self.mapGroup) then
        for _, g in ipairs(self.mapGroup) do
            if(g.key == self.opt.Map) then text = g.name; break; end
        end
    else
        local zid = self:GetZoneIDs();
        for _, v in ipairs(self.zonepulldowns) do
            if(v == zid) then text = Twm_areadb[zid]; break; end
        end
    end
    TWM_SetDropdownText(dd2, text);
end

--

-- Common setup of the control strip's icon buttons (TWMHeaderIconButtonTemplate).
function TWM_HeaderIconButton_OnLoad(self)
    self:GetPushedTexture():SetVertexColor(0.6, 0.6, 0.6);
end

-- The button sits in the header strip, whose parent is the map frame.
local function TWMFramePlayerJumpButton_GetFrame(btn)
    return btn:GetParent():GetParent();
end

function TWMFramePlayerJumpButton_Toggle(btn)
    local f = TWMFramePlayerJumpButton_GetFrame(btn);
    local o = f.opt;
    if(o.track) then
        o.track = nil;
    else
        o.track = "player";
        TWMFramePlayerJumpButton_Seek(f, "player");
    end

    TWMFramePlayerJumpButton_Update(btn)
end

function TWMFramePlayerJumpButton_Jump(btn)
    local f = TWMFramePlayerJumpButton_GetFrame(btn);
    local o = f.opt;
    
    o.track = nil;
    TWMFramePlayerJumpButton_Seek(f, "player");
    
    TWMFramePlayerJumpButton_Update(btn)
end

function TWMFramePlayerJumpButton_Seek(frame, unit)
    frame.trackseek = unit;
    frame:OnWorldMapUpdateU(unit);
end

-- Only re-seeks (switch map + recenter/fit, discarding whatever the player
-- panned/zoomed to) when the unit's current map actually differs from what
-- this frame is already showing -- otherwise a mere close/reopen with
-- "track"/"trackonshow" enabled would reset the view every time even though
-- nothing about the player's location changed. An explicit "Jump to player"
-- button click (TWMFramePlayerJumpButton_Jump/_Toggle) bypasses this and
-- always seeks -- that's the whole point of clicking it.
function TWMFrame_SeekOnShow(frame, unit)
    local map = unit == "player" and TWM_GetPlayerInstanceMap() or TWM_GetUnitContinentPosition(unit);
    if(map and frame.opt and map == frame.opt.Map) then
        return;
    end
    TWMFramePlayerJumpButton_Seek(frame, unit);
end

function TWMFramePlayerJumpButton_Update(btn)
    local f = TWMFramePlayerJumpButton_GetFrame(btn);
    if(f and f.opt) then
        -- Follow mode on = the button stays pushed.
        if(f.opt.track) then
            btn:SetButtonState("PUSHED", true);
        else
            btn:SetButtonState("NORMAL");
        end
    end
end

function TWMFrameTemplate:GetMap()
    return self.opt.Map;
end

-- Every MapTexture region is created here, lazily, the first time
-- SetZoom's allocation loop needs it -- Templates.xml no longer
-- pre-declares any $parentMapTextureN regions at all. Same create-once-
-- and-reuse pattern as Points.lua's icon pool and FlightPaths.lua's line
-- pool: once created, a texture is never destroyed, only Hidden when the
-- current zoom doesn't need it (see the loop right below SetZoom's
-- allocation loop). No ceiling on how far you can zoom out as a result --
-- only the ~32px hard floor a couple lines down.
local function EnsureMapTexture(self, lm, index)
    local name = lm.."MapTexture"..index;
    local tex = _G[name];
    if(not tex) then
        tex = self:CreateTexture(name, "ARTWORK", "TWMMapTextureTemplate");
    end
    return tex;
end

function TWMFrameTemplate:SetZoom(z, nocenter, skipPointsRefresh)
    local textureno = 1;
    local lm = self:GetName();
    local vf = _G[lm.."ViewFrame"];

    -- ViewFrame briefly reports 0 (or reads back a stale/degenerate size)
    -- while the frame's layout is still settling -- e.g. right after a
    -- programmatic SetSize, or mid-way through a live resize drag. Bail out
    -- rather than dividing by z below 32: without this floor, the z-4/z+4
    -- recursion below can drive z to 0 (division by zero -> nan/inf) and
    -- then oscillate between its two branches forever ("script ran too
    -- long").
    local vfw, vfh = vf:GetWidth(), vf:GetHeight();
    if(vfw <= 0 or vfh <= 0) then
        return;
    end
    z = math.max(z, 32);

    self.wzoom = math.floor(vfw/z)+1;
    self.hzoom = math.floor(vfh/z)+1;
    self.wzoom_real = math.ceil(vfw/z)+1;
    self.hzoom_real = math.ceil(vfh/z)+1;

    -- Max zoom: at least HALF a tile must still fit in the viewport on
    -- both axes (z <= 2*vfh and z <= 2*vfw), not a full one -- a real tile
    -- (533.33 world units) is plenty wide for this to still show useful
    -- detail even that zoomed in. Was `z > vfh or z > vfw` (a whole tile
    -- had to fit); doubling the right-hand side is the whole change.
    if(z > 32 and (z > vfh*2 or z > vfw*2)) then
        return self:SetZoom(z-4);
    end
    local lastzoom = self.opt.Zoom;
    self.opt.Zoom = z;

    -- allocate textures
    self.texturelayout = {};
    for hw = 1,self.wzoom_real do
        self.texturelayout[hw] = {};
        for hh = 1,self.hzoom_real do
            self.texturelayout[hw][hh] = EnsureMapTexture(self, lm, textureno);
            self.texturelayout[hw][hh].hx = hw;
            self.texturelayout[hw][hh].hy = hh;
            -- tiled adjacent map textures show a seam under the client's
            -- default pixel/texel snapping; disable it for edge-to-edge tiling.
            self.texturelayout[hw][hh]:SetSnapToPixelGrid(false);
            self.texturelayout[hw][hh]:SetTexelSnappingBias(0);
            textureno = textureno + 1;
        end
    end
    while(_G[lm.."MapTexture"..textureno]) do
        local extratex = _G[lm.."MapTexture"..textureno];
        extratex:Hide();
        if(extratex.debugLabel) then
            extratex.debugLabel:Hide();
        end
        TWM_HideTileDebugBorder(extratex);
        textureno = textureno + 1;
    end

    -- unclip all textures now, ESPECIALLY the middle textures
    for hw = 1,self.wzoom_real do
        for hh = 1,self.hzoom_real do
            self.texturelayout[hw][hh]:Show();
            self.texturelayout[hw][hh]:SetTexCoord(0, 1, 0, 1);
            self.texturelayout[hw][hh]:SetHeight(z);
            self.texturelayout[hw][hh]:SetWidth(z);
        end
    end

    if(nocenter or lastzoom == z) then
        self:AdjustLocation(0,0,true,not skipPointsRefresh)
    else
        local oldcx, oldcy;
        local newcx, newcy;

        oldcy = (vf:GetHeight()/2)/lastzoom;
        oldcx = (vf:GetWidth()/2)/lastzoom;
        newcy = (vf:GetHeight()/2)/z;
        newcx = (vf:GetWidth()/2)/z;

        self:AdjustLocation(oldcx-newcx,-oldcy+newcy,true,not skipPointsRefresh)
    end
end

function TWMFrameTemplate:GetZoom()
    return self.opt and self.opt.Zoom or 256;
end

-- Builds the ordered list of texture-pool slots needed along ONE axis
-- (columns for X, rows for Y) to cover the viewport at the current zoom
-- and pan offset. Slot 1 always starts flush against the viewport's own
-- edge, cropped on its OWN leading side by `panPx` (however much of that
-- tile has already been scrolled past); every following slot is a full
-- tile UNLESS it's the last one needed, which is cropped on its trailing
-- side to whatever remains. Produces exactly as many slots as are
-- actually needed: 1 if a single tile (possibly bigger than the
-- viewport, frame-clipped -- see TWMFrameViewTemplate's SetClipsChildren)
-- already covers everything, up to `normalCount` (the pre-existing
-- floor()-based `wzoom`/`hzoom`) if none of them need the one spare
-- pre-allocated slot, or exactly `normalCount + 1` (using `extraIndex`,
-- the pre-existing `wzoom_real`/`hzoom_real`) if they do.
--
-- Positions are pixel offsets from the viewport's own TOPLEFT ("rightward
-- distance" for X, "downward distance" for Y -- callers negate the Y one
-- when calling SetPoint, matching WoW's own positive-Y-is-up convention;
-- X needs no such flip), tracked as a running sum of each earlier slot's
-- own size -- NOT the closed form `zoom*(k-1)-panPx` a first pass at this
-- used: that matches slot 1's own SIZE (zoom-panPx) but not its POSITION
-- (always exactly 0, flush against the viewport edge, regardless of
-- panPx -- confirmed against the old scheme's own "upper-left corner"
-- code, which special-cased its position as a literal `(0,0)` for
-- exactly this reason). The running sum
-- naturally gives slot 1 position 0 (nothing summed yet) while still
-- reproducing the closed form exactly for every slot after it.
--
-- Replaces the old fixed "corner + middle-run + edge-line + one spare
-- slot" scheme, which hard-assumed at least 2 DISTINCT slots always
-- existed per axis (slot 1 and a DIFFERENT slot `normalCount`) -- an
-- assumption a big enough zoom breaks (a single tile can be bigger than
-- the whole viewport, collapsing what used to be 2+ distinct slots into
-- 1; confirmed live: the old code wrote "left corner" cropping into a
-- slot, then unconditionally overwrote the SAME slot with "right corner"
-- cropping right after, since both used to be different slots but now
-- weren't). Building an explicit list first, then assigning texture
-- slots from it, handles 1, 2, or N slots uniformly, by construction,
-- with no risk of two different branches writing into the same pooled
-- texture object.
local function TWM_BuildAxisSlots(viewportSize, zoomStep, panPx, fracStart, normalCount, extraIndex)
    local slots = {};
    local remaining = viewportSize;
    local pos = 0;
    local k = 1;
    while(remaining > 0) do
        local isFirst = (k == 1);
        local available = isFirst and (zoomStep - panPx) or zoomStep;
        local size = math.min(remaining, available);
        local uMin = isFirst and fracStart or 0;
        slots[k] = {
            index = (k <= normalCount) and k or extraIndex,
            pos = pos,
            size = size,
            uMin = uMin,
            uMax = uMin + size/zoomStep,
        };
        pos = pos + size;
        remaining = remaining - size;
        k = k + 1;
    end
    return slots;
end

function TWMFrameTemplate:SetLocation(x,y,forceupdate,forcePointsUpdate)
    local zx, zy, mymap;
    local framename = self:GetName();
    local vfname = framename.."ViewFrame";
    local vf = _G[vfname];
    local texturelayout = self.texturelayout;
    local zoom = self.opt.Zoom;
    local wzoom, hzoom = self.wzoom,self.hzoom;
    local wzoom_real,hzoom_real = self.wzoom_real, self.hzoom_real;

    -- opt.Location keeps the exact position (a drag adds deltas to it); what
    -- is drawn is that position on the physical pixel grid, so tiles and
    -- icons (pixel-aligned, see Points.lua) always move by whole pixels.
    local exactX, exactY = x, y;
    local pixel = TWM_GetPixelSize(vf);
    if(pixel) then
        x = math.floor(x*zoom/pixel + 0.5)*pixel/zoom;
        y = math.floor(y*zoom/pixel + 0.5)*pixel/zoom;
    end

    zx = math.floor(x);
    zy = math.floor(y);
    mymap = self.opt.Map;

    -- offset calc: exact, not floored -- tile 1's texcoord start uses the
    -- exact fraction, so a floored offset would shift the following tiles
    -- relative to it whenever the view isn't on a whole unit
    local px, py;
    px = (x-zx)*zoom;
    py = (y-zy)*zoom;

    local needsContentRefresh = (zx ~= math.floor(self.viewX or self.opt.Location[1]) or forceupdate or
        zy ~= math.floor(self.viewY or self.opt.Location[2]) or mymap ~= self.lastmap);
    if(needsContentRefresh) then
        local v = {};
        local jx, jy, nsv;
        local showTerrain = TWM_ShouldShowTerrain(self);

        for hx = 1,wzoom_real do
            v[hx] = {};
            for hy = 1,hzoom_real do
                local tex = texturelayout[hx][hy];

                -- get info: the tile's texture filename is derived
                -- directly from its grid coordinate (e.g. "11x09" ->
                -- "map11_09" under World\Minimaps\<continent>\) -- that
                -- convention holds for the vast majority of tiles. We only
                -- draw it if this spot falls inside a known TBC-era zone
                -- (see TWM_GetLiveZoneNameForBigCoord), which skips
                -- Cataclysm-only terrain that doesn't exist on this client
                -- without needing a hand-maintained tile table at all.
                local col, row = zx+hx-1, zy+hy-1;
                local tilekey = format("%.2dx%.2d", col, row);
                local cbx, cby = TWM_Mini2Big_Coord(col+0.5, row+0.5);
                local livezone = TWM_GetLiveZoneNameForBigCoord(mymap, cbx, cby, tilekey);

                if(livezone and showTerrain) then
                    v[hx][hy] = { TWM_GetTileFileName(mymap, col, row) };
                else
                    v[hx][hy] = dummyv;
                end

                -- set textures
                if(v[hx][hy]) then
                    TWM_SetTileTexture(tex, TWM_GetTileTexture(mymap, v[hx][hy][1]), TWM_GetTileFilter());
                    tex:SetVertexColor(1,1,1,1);
                else
                    -- No live zone here -- leave the tile transparent
                    -- instead of manually painting it black. self.emptyBg
                    -- (TWMFrameTemplate:OnLoad) sits on this same frame's
                    -- BACKGROUND layer, below these tiles' own ARTWORK
                    -- layer, so an empty (no-texture) cell shows that
                    -- black through on its own -- no need to paint it a
                    -- second time here.
                    tex:SetTexture(nil);
                end

                -- debug: label this tile with its grid coordinate and the
                -- live zone name the client reports at that spot. Only the
                -- TEXT is set here (cheap to skip when nothing changed) --
                -- position and Show/Hide are handled once, unconditionally,
                -- at the end of this function (see the comment there for
                -- why: both used to be wrong when handled only here).
                if(TWM_DebugTiles) then
                    if(not tex.debugLabel) then
                        tex.debugLabel = vf:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge");
                        tex.debugLabel:SetJustifyH("CENTER");
                    end

                    tex.debugLabel:SetText(tilekey.."\n"..(livezone or "|cffff4040(none)|r"));
                end
            end
        end
    end

    -- Do offset and clipping (:SetTexCoord and :SetHeight/Width) --
    -- see TWM_BuildAxisSlots' own header comment for the full design.
    local colSlots = TWM_BuildAxisSlots(vf:GetWidth(), zoom, px, x-zx, wzoom, wzoom_real);
    local rowSlots = TWM_BuildAxisSlots(vf:GetHeight(), zoom, py, y-zy, hzoom, hzoom_real);

    local usedCols, usedRows = {}, {};
    for _, col in ipairs(colSlots) do
        for _, row in ipairs(rowSlots) do
            local tex = texturelayout[col.index][row.index];
            tex:SetTexCoord(col.uMin, col.uMax, row.uMin, row.uMax);
            tex:SetWidth(col.size);
            tex:SetHeight(row.size);
            tex:ClearAllPoints();
            tex:SetPoint("TOPLEFT", vfname, "TOPLEFT", col.pos, -row.pos);
            tex:Show();
        end
        usedCols[col.index] = true;
    end
    for _, row in ipairs(rowSlots) do
        usedRows[row.index] = true;
    end

    -- Every pooled slot this call's column/row lists don't cover gets
    -- explicitly hidden -- happens whenever wzoom_real/hzoom_real (SetZoom
    -- always allocates one spare column and one spare row defensively)
    -- aren't actually needed at the current pan offset/zoom.
    for hw = 1, wzoom_real do
        for hh = 1, hzoom_real do
            if(not (usedCols[hw] and usedRows[hh])) then
                texturelayout[hw][hh]:Hide();
            end
        end
    end

    -- Debug tile grid ("/twm debug"): a yellow border on every currently-
    -- shown pooled tile texture, real map art or the plain black "no live
    -- zone" filler alike -- keyed on whether the pooled texture itself is
    -- shown, not on whether it has real art, so it covers both. A single
    -- pass over the whole pool, run every call (not just on content
    -- refresh), since panning/zooming/resizing can change which cells are
    -- shown/hidden and how they're cropped without necessarily touching
    -- their tile art.
    for hw = 1, wzoom_real do
        for hh = 1, hzoom_real do
            local tex = texturelayout[hw][hh];
            if(TWM_DebugTiles and tex:IsShown()) then
                TWM_ShowTileDebugBorder(TWM_EnsureTileDebugBorder(vf, tex));
            else
                TWM_HideTileDebugBorder(tex);
            end

            -- debugLabel's TEXT is set above (content-refresh only); its
            -- position and Show/Hide belong here instead, for two reasons:
            -- (1) `tex` itself can Show/Hide on EVERY call (edge/corner
            -- tiles do, as panning slides them in/out), not just when
            -- content refreshes, so gating the label's own Show/Hide on
            -- content-refresh-only left it stale/stuck relative to its own
            -- tile. (2) anchoring the label to `tex`'s own CENTER anchored
            -- it to whatever's currently VISIBLE of that tile -- for a
            -- cropped edge/corner tile (only partially panned into view),
            -- that visible sub-rect's center drifts away from the tile's
            -- true, full-size center as more of it gets cropped off,
            -- reading as the label "pushing away" from the map's edge.
            -- Computed directly instead, as this grid slot's own FULL
            -- (uncropped) tile center -- deliberately NOT the same
            -- position math TWM_BuildAxisSlots uses for rendering (that
            -- one clamps slot 1 to the viewport's own edge, by design);
            -- the label wants the tile's true nominal center even when
            -- that's partly or fully off-screen, so it always sits at
            -- its tile's one true center regardless of how much of the
            -- tile is actually cropped into view.
            if(tex.debugLabel) then
                if(TWM_DebugTiles and tex:IsShown()) then
                    local centerX = zoom*(hw-1) - px + zoom/2;
                    local centerY = -zoom*(hh-1) + py - zoom/2;
                    tex.debugLabel:ClearAllPoints();
                    tex.debugLabel:SetPoint("CENTER", vf, "TOPLEFT", centerX, centerY);
                    tex.debugLabel:Show();
                else
                    tex.debugLabel:Hide();
                end
            end
        end
    end

    self.opt.Location[1] = exactX;
    self.opt.Location[2] = exactY;
    self.viewX = x;
    self.viewY = y;

    -- set zone text (reads opt.Location, so after it is updated; follow mode
    -- refreshes it on its own slower timer)
    if(not vf.dragme and not self.followMoving) then
        self:UpdateDropDown2();
    end

    -- forcePointsUpdate defaults to forceupdate when not given explicitly,
    -- so every other caller keeps its old all-or-nothing behavior -- only
    -- the resize-drag path (SetZoom's skipPointsRefresh) actually needs to
    -- force the (cheap) tile refresh without also forcing the (pricier) POI
    -- re-cull on every intermediate tick.
    if(forcePointsUpdate == nil) then
        forcePointsUpdate = forceupdate;
    end
    TWMPoints_OnMove(self, x, y, forcePointsUpdate);
    TWM_WMOOverlay_Update(self);
end

function TWMFrameTemplate:GetLocation()
    local fm = self:GetName();

    return self.opt.Location[1],
        self.opt.Location[2];
end

function TWMFrameTemplate:AdjustLocation(dx,dy,forceupdate,forcePointsUpdate)
    local fm = self:GetName();

    if(self.opt == nil) then
        -- we aren't ready yet!
        return;
    end

    self:SetLocation(
        self.opt.Location[1] + dx,
        self.opt.Location[2] - dy,
                        forceupdate, forcePointsUpdate);
end

-- Which zone (Twm_mapareas areaID) the view's current center point falls
-- inside -- see TWM_FindZoneAtBigCoord for the ground-truth-first, box-
-- fallback lookup rule.
function TWMFrameTemplate:GetZoneIDs()
    local fm = self:GetName();
    local x, y = unpack(self.opt.Location);
    local zoom = self:GetZoom();
    local viewframe = _G[fm.."ViewFrame"];

    local cx = x+(viewframe:GetWidth()/2)/zoom
    local cy = y+(viewframe:GetHeight()/2)/zoom

    local cbx, cby = TWM_Mini2Big_Coord(cx, cy)
    local tilekey = format("%.2dx%.2d", math.floor(cx), math.floor(cy));

    return TWM_FindZoneAtBigCoord(self.opt.Map, cbx, cby, tilekey);
end

function TWMFrameTemplate:OnWorldMapUpdate()
    if(self.trackseek or (self.opt and self.opt.track)) then
        self:OnWorldMapUpdateU(self.trackseek or self.opt.track)
    end
end

function TWMFrameTemplate:OnWorldMapUpdateU(u)
    -- The player is inside a dungeon/raid/scenario we have a map for: only
    -- switch to that map, no positioning. Checked before the continent
    -- lookup, whose C_Map parent walk can return the outdoor continent for an
    -- instance.
    if(u == "player") then
        local inst = TWM_GetPlayerInstanceMap();
        if(inst) then
            if(u == self.trackseek) then
                self.trackseek = nil;
                self:SelectMap(inst);
            elseif(u == self.opt.track and self.opt.Map ~= inst) then
                self:SelectMap(inst);
            end
            return;
        end
    end

    local map, x, y = TWM_GetUnitContinentPosition(u);
    local lm = self:GetName();
    local viewframe = _G[lm.."ViewFrame"];
    local zoom = self.opt.Zoom

    if(map == nil or Twm_mapareas[map] == nil) then
        return;
    end

    -- No live position on this map (e.g. Alterac Valley) -- still switch to
    -- it so the frame doesn't stay stuck on whatever was open before, just
    -- can't center/follow the player without x/y, so fit the whole map
    -- instead. Guard opt.track against re-fitting every OnUpdate tick once
    -- we're already showing the right map (would fight manual pan/zoom).
    if(x == nil) then
        if(u == self.trackseek) then
            self:SetMap(map);
            self:FitMapToViewport(map);
            self.trackseek = nil;
        elseif(u == self.opt.track and self.opt.Map ~= map) then
            self:SetMap(map);
            self:FitMapToViewport(map);
        end
        return;
    end

    local x1,x2,y1,y2;
    if(Twm_mapareas[map][0] ~= nil) then
        x1 = Twm_mapareas[map][0][1];
        x2 = Twm_mapareas[map][0][2];
        y1 = Twm_mapareas[map][0][3];
        y2 = Twm_mapareas[map][0][4];
    else
        local _,va = next(Twm_mapareas[map]);  
        x1 = va[1];
        x2 = va[2];
        y1 = va[3];
        y2 = va[4];
    end

    local unitx, unity = (-x*(x1-x2) + x1), (-y*(y1-y2) + y1);

    if(u == self.trackseek) then
        local zx,zy = TWM_Big2Mini_Coord(unitx, unity);

        self:SetMap(map);
        self:SetLocation(zx-(viewframe:GetWidth()/2)/zoom,
                    zy-(viewframe:GetHeight()/2)/zoom);

        self.trackseek = nil;
    elseif(u == self.opt.track and not self.followMode) then
        local rx,ry = self:GetLocation();
        local zx,zy = TWM_Big2Mini_Coord(unitx, unity);
        local whaffzoom = (viewframe:GetWidth()/2)/zoom;
        local hhaffzoom = (viewframe:GetHeight()/2)/zoom;

        rx = rx+whaffzoom;
        ry = ry+hhaffzoom;

        zx = zx-whaffzoom;
        zy = zy-hhaffzoom;

        if(zx > rx or zx + whaffzoom*2 < rx  or
                zy > ry or zy + hhaffzoom*2 < ry) then
            self:SetMap(map);
            self:SetLocation(zx, zy);
        end
    end
end


twm_lastdragx, twm_lastdragy = nil, nil;
function TWMFrameViewFrame_OnDrag(self)
    -- A drag started from a point icon (see TWMP_EnableDragThrough,
    -- Points.lua) has no OnDragStop of its own to clear self.dragme -- that
    -- icon frame may get recycled for a different point mid-pan, and its
    -- events can't be relied on to still fire. Polling the real mouse
    -- button state here instead makes stopping the drag independent of
    -- which frame (if any) originally started it.
    if(not (IsMouseButtonDown("LeftButton") or IsMouseButtonDown("RightButton"))) then
        if(self.dragme) then
            self.dragme = false;
            self:GetParent():UpdateDropDown2();
        end
        return;
    end

    local x,y = GetCursorPosition();
    local fx, fy;
    local zoom = self:GetParent().opt.Zoom;

    x = x / self:GetEffectiveScale();
    y = y / self:GetEffectiveScale();

    fx = math.floor(x - self:GetLeft())/(zoom);
    fy = math.floor(y - self:GetBottom())/(zoom);
    if(twm_lastdragx ~= nil) then
        local ddx, ddy = twm_lastdragx - fx, twm_lastdragy - fy;
        -- manual panning cancels follow mode, which would fight the drag
        if(self:GetParent().followMode and (ddx ~= 0 or ddy ~= 0)) then
            TWMFrame_StopTracking(self:GetParent());
        end
        self:GetParent():AdjustLocation(ddx, ddy);
    end

    twm_lastdragx = fx;
    twm_lastdragy = fy;
end

-- Lazily creates the cursor-following world-coordinate label used by
-- TWMFrameViewFrame_UpdateCursorCoord ("/twm debug", TWMFrame's own
-- standalone window only -- see Templates.xml's OnUpdate gate,
-- `self:GetParent() == TWMFrame`). Parented to UIParent (not the
-- ViewFrame) and positioned the same "follow the raw cursor" way
-- Points.lua's own tooltip is (TWMFrameViewFrame_UpdatePointTooltip) --
-- avoids TWMFrameViewTemplate's SetClipsChildren cutting it off near an
-- edge, since a coordinate readout is most useful right at the edge where
-- a tile boundary is.
local function TWM_EnsureCursorCoordLabel()
    if(TWM_CursorCoordLabel) then return TWM_CursorCoordLabel; end
    local f = CreateFrame("Frame", "TWMFrameCursorCoordLabel", UIParent);
    f:SetFrameStrata("TOOLTIP");
    f:SetSize(1, 1);
    f.text = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
    f.text:SetPoint("TOPLEFT");
    TWM_CursorCoordLabel = f;
    return f;
end

-- Copy-to-clipboard for the coordinate label above. Lua has no direct
-- OS-clipboard-write API at all -- the only way any WoW addon reaches the
-- real clipboard is indirectly, via an EditBox: a native Ctrl+C keystroke
-- while an EditBox is focused with its text highlighted is handled by the
-- game client itself (same native path as copying a chat link), not by
-- this addon. So this doesn't "detect Ctrl+C" and copy on that event --
-- it just keeps this EditBox focused+highlighted with the current
-- coordinate text FOR AS LONG AS Ctrl is held, so the user's own physical
-- Ctrl+C, whenever they press it, lands on an already-ready EditBox.
-- Deliberately not focused all the time (only while Ctrl is actually held)
-- -- an EditBox with focus swallows other keyboard input (WASD movement,
-- etc.), which would be a surprising side effect of merely hovering the
-- mouse over the debug view.
local function TWM_EnsureCursorCoordCopyBox()
    if(TWM_CursorCoordCopyBox) then return TWM_CursorCoordCopyBox; end
    local eb = CreateFrame("EditBox", "TWMFrameCursorCoordCopyBox", UIParent);
    eb:SetFrameStrata("TOOLTIP");
    eb:SetAutoFocus(false);
    eb:SetFontObject("GameFontNormalSmall");
    eb:SetSize(160, 16);
    eb:SetMultiLine(false);
    eb:Hide();
    TWM_CursorCoordCopyBox = eb;
    return eb;
end

function TWM_HideCursorCoordCopyBox()
    if(not TWM_CursorCoordCopyBox) then return; end
    TWM_CursorCoordCopyBox:ClearFocus();
    TWM_CursorCoordCopyBox:Hide();
end

function TWM_HideCursorCoordLabel()
    if(TWM_CursorCoordLabel) then TWM_CursorCoordLabel:Hide(); end
    TWM_HideCursorCoordCopyBox();
end

function TWMFrameViewFrame_UpdateCursorCoord(self)
    local x, y = GetCursorPosition();

    if(self.lastoux ~= x or self.lastouy ~= y) then
        self.lastoux = x;
        self.lastouy = y;

        local rx, ry = unpack(TWMFrame.opt.Location);
        local zoom = TWMFrame.opt.Zoom;
        local scale = self:GetEffectiveScale();
        local sx = x / scale;
        local sy = y / scale;

        -- Screen pixels -> mini coordinate at the cursor, not the viewport's
        -- own center (contrast TWMFrameTemplate:GetZoneIDs, which does the
        -- same conversion for the CENTER). x increases rightward same as
        -- screen space; y is the opposite of WoW's own bottom-up screen axis
        -- (mini-y increases downward, matching Location's own convention --
        -- see TWM_WMOOverlay_Update's (Ly-my)*z for the same relationship used
        -- the other direction). This used to read a hardcoded `512` here
        -- instead of the ViewFrame's own real (user-resizable) height -- wrong
        -- for any window not left at its exact original size.
        rx = rx + (sx - self:GetLeft())/zoom;
        ry = ry + (self:GetTop() - sy)/zoom;
        local bigx, bigy = TWM_Mini2Big_Coord(rx, ry);

        local label = TWM_EnsureCursorCoordLabel();
        label.text:SetText(format("%.1f, %.1f", bigx, bigy));
        local uiscale = UIParent:GetEffectiveScale();
        label:ClearAllPoints();
        label:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x/uiscale + 16, y/uiscale - 16);
        label:Show();
    end

    -- Checked every tick, independent of the mouse-moved gate above (the
    -- user holding Ctrl with the cursor perfectly still must still work) --
    -- see TWM_EnsureCursorCoordCopyBox's own header for the mechanism.
    if(TWM_CursorCoordLabel and TWM_CursorCoordLabel:IsShown()) then
        if(IsControlKeyDown()) then
            local copyBox = TWM_EnsureCursorCoordCopyBox();
            copyBox:SetText(TWM_CursorCoordLabel.text:GetText());
            copyBox:ClearAllPoints();
            copyBox:SetPoint("TOPLEFT", TWM_CursorCoordLabel, "TOPLEFT", 0, 0);
            copyBox:Show();
            copyBox:HighlightText();
            copyBox:SetFocus();
        else
            TWM_HideCursorCoordCopyBox();
        end
    end
end

-- Follow mode (Goto Player toggled on, view on a continent): the view is
-- re-centered on the unit every FOLLOW_INTERVAL seconds. Tiles move with the
-- view; icons ride the pan anchor and are re-laid out only after a larger
-- drift (TWMPoints_Pan, Points.lua); the zone dropdown refreshes on its own
-- slower timer.
local TWM_FOLLOW_INTERVAL = 1/30;
local TWM_FOLLOW_ZONE_INTERVAL = 1;

local function TWM_SetFollowMode(frame, on)
    if((frame.followMode == true) == on) then return; end
    frame.followMode = on or nil;
    -- next TWMPoints_OnMove does a full layout (with/without the cull margin)
    frame.yap_lastx = nil;
    frame.yap_lasty = nil;
end

function TWMFrame_StopTracking(frame)
    frame.opt.track = nil;
    TWM_SetFollowMode(frame, false);
    local btn = _G[frame:GetName().."PlayerJumpButton"];
    if(btn) then TWMFramePlayerJumpButton_Update(btn); end
end

-- Returns false when follow doesn't apply (not a continent / no live
-- position), leaving the regular tracking in OnWorldMapUpdateU to handle it.
function TWMFrameTemplate:FollowTick(unit, dt)
    local map, nx, ny = TWM_GetUnitContinentPosition(unit);
    local area = map and Twm_ContinentMapID[map] and Twm_mapareas[map] and Twm_mapareas[map][0];
    if(not (area and nx)) then return false; end

    if(map ~= self.opt.Map) then
        self:SetMap(map);
    end

    local bigx = -nx*(area[1]-area[2]) + area[1];
    local bigy = -ny*(area[3]-area[4]) + area[3];
    local mx, my = TWM_Big2Mini_Coord(bigx, bigy);

    local vf = _G[self:GetName().."ViewFrame"];
    local zoom = self.opt.Zoom;

    local tx, ty = mx - vf:GetWidth()/2/zoom, my - vf:GetHeight()/2/zoom;
    -- whole physical pixels, so tiles and icons (pixel-aligned, see Points.lua)
    -- step by the same amount
    local pixel = TWM_GetPixelSize(vf);
    if(pixel) then
        tx = math.floor(tx*zoom/pixel + 0.5)*pixel/zoom;
        ty = math.floor(ty*zoom/pixel + 0.5)*pixel/zoom;
    end
    local loc = self.opt.Location;

    TWM_SetFollowMode(self, true);
    if(tx ~= loc[1] or ty ~= loc[2]) then
        self.followMoving = true;
        self:SetLocation(tx, ty);
        self.followMoving = nil;
    end

    -- the unit's own marker is otherwise refreshed only every 0.5s
    local mp = self.mobilepoints and self.mobilepoints["players:"..unit];
    if(mp) then
        mp.locx, mp.locy, mp.locmap = mx, my, map;
        mp:Update(self);
    end

    self.followZoneTime = (self.followZoneTime or 0) + dt;
    if(self.followZoneTime >= TWM_FOLLOW_ZONE_INTERVAL) then
        self.followZoneTime = 0;
        self:UpdateDropDown2();
    end
    return true;
end

function TWMFrameTemplate:OnUpdate(elapsed)
    self.update_time = self.update_time + elapsed;

    local followed = false;
    if(self.opt and self.opt.track) then
        self.follow_time = (self.follow_time or 0) + elapsed;
        if(self.follow_time >= TWM_FOLLOW_INTERVAL) then
            followed = self:FollowTick(self.opt.track, self.follow_time);
            self.follow_time = 0;
        else
            followed = self.followMode == true;
        end
    end
    if(not followed) then
        TWM_SetFollowMode(self, false);
    end

    if(self.update_time > 0.5) then
       TWMPoints_OnUpdate(self, self.update_time);
       self:OnWorldMapUpdate();
       self.update_time = 0;
   end
end

function TWM_Mini2Big_Coord(x,y)
    return (x - 32)*-MINI2BIGX,(y-32)*-MINI2BIGY;
end

function TWM_Big2Mini_Coord(x,y)
    return (x/-MINI2BIGX + 32),(y/-MINI2BIGY + 32);
end

-- TWMTooltip
TWMTooltipTemplate = {};

function TWMTooltipTemplate:OnLoad()
    self:SetBackdrop{
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        edgeSize = 16,
        tileSize = 16,
        insets = { left = 5, right = 5, top = 5, bottom = 5 },
    };
    self:SetBackdropBorderColor(TOOLTIP_DEFAULT_COLOR.r,
                                TOOLTIP_DEFAULT_COLOR.g,
                                TOOLTIP_DEFAULT_COLOR.b);
    self:SetBackdropColor(TOOLTIP_DEFAULT_BACKGROUND_COLOR.r,
                          TOOLTIP_DEFAULT_BACKGROUND_COLOR.g,
                          TOOLTIP_DEFAULT_BACKGROUND_COLOR.b);
    self.lines = {};
    self.nextnew = 1;
    self.nextfree = 1;
end

function TWMTooltipTemplate:Show()
    local r = getmetatable(self).__index.Show(self);
    self:FixSize();
    return r;
end

function TWMTooltipTemplate:GetNext()
    if(self.nextfree < self.nextnew) then
        self.nextfree = self.nextfree + 1;
        -- Pooled row: drop the tint/coords the previous legend left on the icon.
        local row = self.lines[self.nextfree-1];
        row.Icon:SetVertexColor(1, 1, 1, 1);
        row.Icon:SetTexCoord(0, 1, 0, 1);
        return row;
    end

    if(self.nextnew > 32) then
        return;
    end

    local f = CreateFrame("Button");

    f:SetHeight(16);
    f:SetWidth(16);
    f:SetParent(self);
    -- No EnableMouse -- these rows have no OnEnter/OnClick of their own
    -- (visibility in the tooltip is driven by Region:IsMouseOver(), which is
    -- a pure geometry check and doesn't need mouse input enabled). Enabling
    -- it here only made this row swallow clicks that land on the tooltip
    -- -- e.g. a map-drag that happens to start on top of the tooltip box.

    f.Icon = f:CreateTexture(nil, "OVERLAY");
    f.Icon:SetPoint("TOPLEFT", f);
    
    f.Foreground = f:CreateFontString(nil, "ARTWORK");
    f.Foreground:SetFontObject(GameFontHighlight);
    f.Foreground:SetTextColor(0, 0, 0);
    f.Foreground:SetShadowOffset(-1, 0);
    f.Foreground:SetPoint("TOPLEFT", f);

    f:SetFrameLevel(f:GetFrameLevel() + 4);
    f.Clear = TWMP_Clear;
    f.SetOffset = nilfunc;

    f.Text = f:CreateFontString(nil, "ARTWORK");
    f.Text:SetFontObject(GameFontHighlight);
    f.Text:SetPoint("LEFT", f.Icon, "LEFT", 24, 0);
  
    if(self.nextnew == 1) then
        f:SetPoint("TOPLEFT", self, "TOPLEFT", 8, -8);
    else
        f:SetPoint("TOPLEFT", self.lines[self.nextnew-1], "BOTTOMLEFT", 0, -2);
    end

    tinsert(self.lines, f);
    self.nextnew = self.nextnew + 1;
    self.nextfree = self.nextfree + 1;
    return f;
end

-- Row layout (see GetNext): 8px left margin, 24px icon column, then the text.
local TWM_TOOLTIP_TEXT_OFFSET = 8 + 24;
local TWM_TOOLTIP_RIGHT_MARGIN = 8;

function TWMTooltipTemplate:FixSize()
    local hei = 16;
    local wid = 4;

    for h = 1,(self.nextfree-1) do
        hei = hei + self.lines[h]:GetHeight() + 2;
        if(self.lines[h].Text:GetWidth() > wid) then
            wid = self.lines[h].Text:GetWidth();
        end
    end
    self:SetHeight(hei);
    self:SetWidth(TWM_TOOLTIP_TEXT_OFFSET + wid + TWM_TOOLTIP_RIGHT_MARGIN);
end


function TWMTooltipTemplate:Clear() 
    for h = 1,(self.nextfree-1) do
        self.lines[h]:Hide();
    end
    self.nextfree = 1;
    self:FixSize();
    self:Hide();
end


