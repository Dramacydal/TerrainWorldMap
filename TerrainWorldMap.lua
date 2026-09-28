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

TWM_FRAME_OPTION_DEFAULTS = {
    ["Locked"] = false,
    ["Map"] = "Kalimdor",
    ["Location"] = {31.0625, 33.250},
    ["Alpha"] = 1,
    ["IconSize"] = 1.0,
    ["PointCfg"] = {},
    ["ShowWMOOverlay"] = true,
    ["Zoom"] = 256,
    ["Width"] = 539,
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
    if(not tex.debugBorder) then return; end
    tex.debugBorder.top:Hide();
    tex.debugBorder.bottom:Hide();
    tex.debugBorder.left:Hide();
    tex.debugBorder.right:Hide();
end

function TWM_ShowTileDebugBorder(border)
    border.top:Show();
    border.bottom:Show();
    border.left:Show();
    border.right:Show();
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
    for _, e in ipairs(Twm_ArenaNames) do
        TWM_ARENAS[TWM_ResolveLocaleName(e.name)] = {e.key};
    end
end

-- "Show WMO Layers" overlay: a few maps (arenas so far -- Dalaran Sewers,
-- Orgrimmar -- see Twm_WMOTiles, Data_<Flavor>/mapdata_wmo_tiles.lua,
-- scripts/gen_wmo_tiles.js; the same system will apply to dungeons/raids
-- later, hence the generic naming) have real outdoor ADT terrain but no
-- baked minimap art for it at all; the only real minimap art there is the
-- placed WMO building's own baked group tiles. Drawn as a small pool of
-- plain textures (raw FileDataIDs), positioned in the same mini-coordinate
-- space TWMPoints uses (see TWMP_SetOffset, Points.lua) so they pan/zoom in
-- sync with the rest of the view.
function TWM_WMOOverlay_EnsureTextures(frame, count)
    local lm = frame:GetName();
    local vf = _G[lm.."ViewFrame"];

    frame.wmoOverlayTextures = frame.wmoOverlayTextures or {};
    for i = #frame.wmoOverlayTextures+1, count do
        local tex = vf:CreateTexture(nil, "OVERLAY");
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
        frame.wmoOverlayTextures[i] = tex;
    end

    return frame.wmoOverlayTextures;
end

-- Tiles are generated in ascending-height order (gen_wmo_tiles.js).
-- That order alone is NOT enough to guarantee stacking, though: draw order
-- among multiple textures in the same layer AND sublevel is undefined in
-- WoW's own UI engine (confirmed -- this isn't documented or guaranteed by
-- creation order, and can visibly change when a texture is reconfigured,
-- which is exactly what happens here every time the tile pool is reused
-- for a different map). So each tile's sublevel is set explicitly below,
-- from its rank in the already-sorted list -- the actual, reliable
-- mechanism -- with the sort order only providing that rank cheaply.
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
-- small fixed pool purely by draw order (the same rank `i` that already
-- drives SetDrawLayer's sublevel above) -- cycling via modulo once the
-- tile count exceeds the pool, rather than trying to keep every tile's
-- color unique forever (real placements have at most a handful of tiles;
-- see gen_wmo_tiles.js's own comments for the highest count seen so far).
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

function TWM_WMOOverlay_Update(frame)
    local lm = frame:GetName();
    local vf = _G[lm.."ViewFrame"];
    local tiles = Twm_WMOTiles and Twm_WMOTiles[frame.opt.Map];

    if(not tiles or not frame.opt.ShowWMOOverlay) then
        if(frame.wmoOverlayTextures) then
            for _, tex in ipairs(frame.wmoOverlayTextures) do
                tex:Hide();
                TWM_HideTileDebugBorder(tex);
            end
        end
        return;
    end

    local textures = TWM_WMOOverlay_EnsureTextures(frame, #tiles);
    local Lx, Ly = frame.opt.Location[1], frame.opt.Location[2];
    local z = frame:GetZoom();
    local cutoff = frame.wmoOverlayHeightCutoff;

    for i, tile in ipairs(tiles) do
        local tex = textures[i];
        local height = tile[6];

        if(cutoff and height and height > cutoff + TWM_WMO_OVERLAY_HEIGHT_EPSILON) then
            tex:Hide();
            TWM_HideTileDebugBorder(tex);
        else
            local fileID, bx1, bx2, by1, by2 = tile[1], tile[2], tile[3], tile[4], tile[5];
            local mx1, my1 = TWM_Big2Mini_Coord(bx1, by1);
            local mx2, my2 = TWM_Big2Mini_Coord(bx2, by2);

            local left, right = math.min(mx1, mx2), math.max(mx1, mx2);
            local top, bottom = math.min(my1, my2), math.max(my1, my2);

            -- Explicit sublevel from this tile's rank in the (ascending-
            -- height-sorted) list -- the reliable way to stack a higher
            -- tile above a lower one; see this function's header comment
            -- for why relying on draw/creation order alone doesn't work.
            -- Sublevel range is only [-8,7] (16 steps); real maps have
            -- far fewer tiles than that, so clamping is just a safety net.
            tex:SetDrawLayer("OVERLAY", math.max(-8, math.min(7, i - 9)));
            tex:SetTexture(fileID);
            tex:ClearAllPoints();
            tex:SetPoint("TOPLEFT", vf, "TOPLEFT", (left-Lx)*z, (Ly-top)*z);
            tex:SetWidth((right-left)*z);
            tex:SetHeight((bottom-top)*z);
            tex:Show();

            if(TWM_DebugTiles) then
                local color = TWM_WMO_DEBUG_COLOR_POOL[((i - 1) % #TWM_WMO_DEBUG_COLOR_POOL) + 1];
                TWM_ShowTileDebugBorder(TWM_EnsureTileDebugBorder(vf, tex, color));
            else
                TWM_HideTileDebugBorder(tex);
            end
        end
    end

    for i = #tiles+1, #textures do
        textures[i]:Hide();
        TWM_HideTileDebugBorder(textures[i]);
    end
end

-- Lazily creates the vertical height-cutoff slider, anchored below the
-- checkbox. Built purely in Lua (OptionsSliderTemplate reused from
-- Settings.lua's own convention) rather than in XML -- a vertical slider
-- needs no extra art of its own beyond what that template already provides,
-- and its value range is per-map (set by TWM_UpdateWMOOverlayButton), so
-- there's nothing static worth declaring in XML.
function TWM_WMOOverlay_EnsureHeightSlider(frame)
    local lm = frame:GetName();
    local name = lm.."WMOOverlayHeightSlider";
    local slider = _G[name];
    if(slider) then return slider; end

    local button = _G[lm.."ShowWMOOverlayButton"];
    slider = CreateFrame("Slider", name, _G[lm.."ViewFrame"], "OptionsSliderTemplate");
    slider:SetOrientation("VERTICAL");
    slider:SetSize(16, 120);
    slider:SetHitRectInsets(0, 0, 0, 0);
    slider:ClearAllPoints();
    slider:SetPoint("TOP", button, "BOTTOM", 0, -12);
    slider:SetFrameLevel(button:GetFrameLevel());
    -- OptionsSliderTemplate's thumb art (UI-SliderBar-Button-Horizontal) is
    -- a wide, short grip meant to be dragged left/right -- sideways-looking
    -- on a vertical bar. Swap to the vertical counterpart and match its
    -- (taller-than-wide) proportions. Guarded: GetThumbTexture is a very
    -- old, standard Slider method, but SetReverseValues (see below) turned
    -- out to not exist on this client at all, so this codebase can no
    -- longer assume any given Slider method is present without checking.
    local thumb = slider.GetThumbTexture and slider:GetThumbTexture();
    if(thumb) then
        thumb:SetTexture("Interface\\Buttons\\UI-SliderBar-Button-Vertical");
        thumb:SetSize(16, 24);
    end
    -- OptionsSliderTemplate's baked-in Low/High/Text labels read as a
    -- horizontal min/max/title strip -- blank them rather than leave
    -- sideways-looking text next to a vertical bar.
    _G[name.."Low"]:SetText("");
    _G[name.."High"]:SetText("");
    _G[name.."Text"]:SetText("");
    -- WoW's Slider defaults a vertical orientation to max-at-bottom,
    -- min-at-top -- backwards from the natural "higher = further up"
    -- reading a height control should have. The obvious fix,
    -- SetReverseValues(true), doesn't exist as a method on this client's
    -- Slider mixin (confirmed live: "attempt to call a nil value") --
    -- flipped instead by storing/reading the NEGATED height as the
    -- slider's own value throughout (TWM_UpdateWMOOverlayButton sets
    -- SetMinMaxValues(-maxH, -minH) and SetValue(-maxH)), which puts the
    -- slider's own minimum (top, under default vertical layout) at the
    -- map's highest real height and its own maximum (bottom) at the
    -- lowest -- exactly the reversed reading needed, with no dependency on
    -- an API this client doesn't have.
    slider:SetScript("OnValueChanged", function(self, value)
        local sliderMin = self:GetMinMaxValues();
        local actualHeight = -value;
        local actualMax = -sliderMin;
        if(actualHeight >= actualMax - TWM_WMO_OVERLAY_HEIGHT_EPSILON) then
            -- Topmost position: never filter, full stop -- see this
            -- function's own header comment for why nil (not actualMax
            -- itself) is what "show everything" means here.
            frame.wmoOverlayHeightCutoff = nil;
        else
            frame.wmoOverlayHeightCutoff = actualHeight;
        end
        TWM_WMOOverlay_Update(frame);
    end);

    return slider;
end

-- Show the checkbox (and, when the current map's WMO placements actually
-- span more than one height, the height-cutoff slider) only on maps that
-- have WMO layer data; sync the checkbox to its persisted option and reset
-- the slider to "show everything" for whichever map is now selected.
function TWM_UpdateWMOOverlayButton(frame)
    local lm = frame:GetName();
    local button = _G[lm.."ShowWMOOverlayButton"];
    if(not button) then return; end

    local tiles = Twm_WMOTiles and Twm_WMOTiles[frame.opt.Map];
    if(tiles) then
        button:Show();
        button:SetChecked(frame.opt.ShowWMOOverlay);

        local minH, maxH = math.huge, -math.huge;
        for _, tile in ipairs(tiles) do
            local h = tile[6];
            if(h) then
                if(h < minH) then minH = h; end
                if(h > maxH) then maxH = h; end
            end
        end

        local slider = TWM_WMOOverlay_EnsureHeightSlider(frame);
        -- Default: show everything, regardless of what the slider below
        -- ends up reporting once shown -- see TWM_WMOOverlay_Update's
        -- header comment for why nil, not maxH itself, is what "no
        -- cutoff" means.
        frame.wmoOverlayHeightCutoff = nil;
        if(maxH > minH) then
            -- Negated -- see TWM_WMOOverlay_EnsureHeightSlider's
            -- OnValueChanged comment for why (no SetReverseValues on this
            -- client).
            slider:SetMinMaxValues(-maxH, -minH);
            slider:SetValue(-maxH);
            slider:Show();
        else
            -- Only one distinct height among this map's placements --
            -- nothing meaningful for the slider to filter.
            slider:Hide();
        end
    else
        button:Hide();
        local slider = _G[lm.."WMOOverlayHeightSlider"];
        if(slider) then slider:Hide(); end
    end
end

function TWMFrameShowWMOOverlayButton_OnClick(self)
    local frame = self:GetParent():GetParent();
    frame.opt.ShowWMOOverlay = self:GetChecked() and true or false;
    TWM_WMOOverlay_Update(frame);
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

    -- Modern tiled backdrop replacing the old fixed corner-art border, since
    -- that art can't stretch -- needed for real (non-scaled) resizing.
    TWMFrame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4},
    });
    TWMFrame:SetBackdropColor(0, 0, 0, 1);

    -- Set here (not XML) since a layer region can't forward-reference a
    -- child Frame declared later in the same XML block. Anchored to the
    -- Options button (not the lock button directly) since that button now
    -- sits between them: Version -- Options -- Lock -- Close.
    TWMFrameVersion:ClearAllPoints();
    TWMFrameVersion:SetPoint("RIGHT", TWMFrameOptionsButton, "LEFT", -6, 0);

    TWMFrame:SetResizable(true);
    -- Width floor keeps the continent/zone dropdowns and the "Goto Player"
    -- button (58+176 from the left, 176 wide, 108+6 from the right -- see
    -- TWMFrame_LayoutHeader) from ever being squeezed into overlapping
    -- each other.
    TWMFrame:SetResizeBounds(530, 300);

    -- See TWM_ResetFramePosition: a size change applied while the frame
    -- is hidden doesn't actually reach the (anchor-derived) ViewFrame until
    -- the frame is shown, so the deferred zoom/tile-grid refresh happens here.
    TWMFrame:HookScript("OnShow", function(self)
        if(self.needsZoomRefreshOnShow) then
            self.needsZoomRefreshOnShow = nil;
            RefreshZoomNextFrame(self);
        end
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
    TWMFrame_LayoutHeader(self);
    self.inResizeRefresh = false;
end

-- Keeps the continent dropdown, zone dropdown and "Goto Player" button
-- together as one tightly-spaced group (fixed gaps between them, like the
-- original fixed layout), and re-centers that whole group under the frame's
-- current width as it's resized -- rather than spreading the three apart to
-- the edges. XML anchors can't express "center this cluster within
-- whatever the current width is" on their own, so this recomputes it in
-- pixels each time.
local TWM_HEADER_GAP = 8;
function TWMFrame_LayoutHeader(self)
    local lm = self:GetName();
    local dd1 = _G[lm.."DropDown"];
    local dd2 = _G[lm.."DropDown2"];
    local jump = _G[lm.."PlayerJumpButton"];
    if(not (dd1 and dd2 and jump)) then return; end

    local groupWidth = dd1:GetWidth() + TWM_HEADER_GAP + dd2:GetWidth() + TWM_HEADER_GAP + jump:GetWidth();
    local leftMargin = (self:GetWidth() - groupWidth) / 2;

    dd1:ClearAllPoints();
    dd1:SetPoint("TOPLEFT", self, "TOPLEFT", leftMargin, -40);

    dd2:ClearAllPoints();
    dd2:SetPoint("LEFT", dd1, "RIGHT", TWM_HEADER_GAP, 0);

    jump:ClearAllPoints();
    jump:SetPoint("LEFT", dd2, "RIGHT", TWM_HEADER_GAP, 0);
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
            self:SetSize(self.opt.Width, self.opt.Height);
        end
        self:SetZoom(self.opt.Zoom);
        self:SetMap(self.opt.Map);
        TWMFrame_LayoutHeader(self);

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

function TWMFrameDropDown_OnLoad(self)
    self:RegisterEvent("VARIABLES_LOADED");
end

function TWMFrameDropDown_OnEvent(self, event)
    if(event == "VARIABLES_LOADED") then
        UIDropDownMenu_Initialize(self, TWMFrameDropDown_Initialize);
        -- No UIDropDownMenu_SetSelectedID here -- it drives its own
        -- persistent "checked" highlight on whichever button sits at that
        -- ID, independent of (and in addition to) each button's own
        -- info.checked field below. Leaving it at its leftover value from
        -- the old flat (pre-category-tree) menu meant button #1 of whatever
        -- submenu was open stayed permanently highlighted alongside the one
        -- info.checked correctly marked for the frame's actual current map.
        UIDropDownMenu_SetWidth(self, 150);
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

-- TWM_ARENAS never gets built above (stays nil) for a flavor with no
-- arenas (Vanilla, no Twm_ArenaNames at all) -- guarded the same way
-- TWM_GetSortedBattlegroundNames is.
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

-- Top-level dropdown is now a category tree (Continents/Dungeons/Raids/
-- Battlegrounds, MoP will add Scenarios) instead of a flat continent list --
-- Dungeons/Raids/Battlegrounds are deliberately empty placeholders for now,
-- ahead of the dungeon-interior map rendering feature they're meant to lead
-- into (see .claude-docs/gotchas.md's WMO-minimap-tile entries for where
-- that stands). Continents keeps working exactly as before, just one level
-- deeper -- TWMFrameDropDownButton_OnClick's use of GetID() as an index into
-- TWM_GetSortedMapNames() still works unchanged, since a submenu's buttons
-- are numbered from 1 within that submenu, same as they were at the top
-- level before this change.
function TWMFrameDropDown_Initialize()
    local info;
    local level = UIDROPDOWNMENU_MENU_LEVEL;
    if(level == 1) then
        info = {text = TWM_CATEGORY_CONTINENTS, hasArrow = true, notCheckable = true, value = "continents"};
        UIDropDownMenu_AddButton(info, level);

        -- Hidden for now -- no entries yet.
        --info = {text = TWM_CATEGORY_DUNGEONS, hasArrow = true, notCheckable = true, value = "dungeons"};
        --UIDropDownMenu_AddButton(info, level);

        --info = {text = TWM_CATEGORY_RAIDS, hasArrow = true, notCheckable = true, value = "raids"};
        --UIDropDownMenu_AddButton(info, level);

        info = {text = TWM_CATEGORY_BATTLEGROUNDS, hasArrow = true, notCheckable = true, value = "battlegrounds"};
        UIDropDownMenu_AddButton(info, level);

        if(TWM_ARENAS) then
            info = {text = TWM_CATEGORY_ARENAS, hasArrow = true, notCheckable = true, value = "arenas"};
            UIDropDownMenu_AddButton(info, level);
        end
    elseif(UIDROPDOWNMENU_MENU_VALUE == "continents") then
        local currentMap = _G["TWMFrame"].opt.Map;
        for i,h in ipairs(TWM_GetSortedMapNames()) do
            info = {
                    text = h;
                    func = TWMFrameDropDownButton_OnClick;
                    -- Without this, the checkmark falls back to comparing
                    -- each button's own ID against UIDropDownMenu_SetSelectedID
                    -- (set once, to 1, back at load time and never since --
                    -- there's no single "selected ID" that means anything once
                    -- this list lives inside a submenu) -- always checking
                    -- whichever entry sorts first, regardless of the frame's
                    -- actual current map.
                    checked = (TWM_MAPS[h][1] == currentMap);
            };
            UIDropDownMenu_AddButton(info, level);
        end
    elseif(UIDROPDOWNMENU_MENU_VALUE == "battlegrounds") then
        local currentMap = _G["TWMFrame"].opt.Map;
        for i,h in ipairs(TWM_GetSortedBattlegroundNames()) do
            info = {
                    text = h;
                    func = TWMFrameDropDownButton_Battleground_OnClick;
                    checked = (TWM_BATTLEGROUNDS[h][1] == currentMap);
            };
            UIDropDownMenu_AddButton(info, level);
        end
    elseif(UIDROPDOWNMENU_MENU_VALUE == "arenas") then
        local currentMap = _G["TWMFrame"].opt.Map;
        for i,h in ipairs(TWM_GetSortedArenaNames()) do
            info = {
                    text = h;
                    func = TWMFrameDropDownButton_Arena_OnClick;
                    checked = (TWM_ARENAS[h][1] == currentMap);
            };
            UIDropDownMenu_AddButton(info, level);
        end
    end
    -- "dungeons"/"raids": no entries yet.
end

function TWMFrameDropDownButton_OnClick(self)
        local i = self:GetID();
        local h = TWM_GetSortedMapNames()[i];
        if(h) then
            return _G["TWMFrame"]:SelectMap(TWM_MAPS[h][1]);
        end
end

function TWMFrameDropDownButton_Battleground_OnClick(self)
        local i = self:GetID();
        local h = TWM_GetSortedBattlegroundNames()[i];
        if(h) then
            return _G["TWMFrame"]:SelectMap(TWM_BATTLEGROUNDS[h][1]);
        end
end

function TWMFrameDropDownButton_Arena_OnClick(self)
        local i = self:GetID();
        local h = TWM_GetSortedArenaNames()[i];
        if(h) then
            return _G["TWMFrame"]:SelectMap(TWM_ARENAS[h][1]);
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

    TWM_UpdateWMOOverlayButton(self);

    local mapdropdown = _G[lm.."DropDown"];
    if(mapdropdown) then
        for i,h in ipairs(TWM_GetSortedMapNames()) do
            if(TWM_MAPS[h][1] == mapname) then
                -- No UIDropDownMenu_SetSelectedID here -- that tracks a
                -- checkmark against a button's position in the level it was
                -- set for, and the continent list now lives one level down
                -- (inside the "Continents" category), not at the top level
                -- this call would otherwise target. SetText below is what
                -- actually matters -- it's what keeps the closed dropdown
                -- button showing the current continent's name.
                UIDropDownMenu_SetText(mapdropdown,h);
            end
        end
        for i,h in ipairs(TWM_GetSortedBattlegroundNames()) do
            if(TWM_BATTLEGROUNDS[h][1] == mapname) then
                UIDropDownMenu_SetText(mapdropdown,h);
            end
        end
        for i,h in ipairs(TWM_GetSortedArenaNames()) do
            if(TWM_ARENAS[h][1] == mapname) then
                UIDropDownMenu_SetText(mapdropdown,h);
            end
        end
    end

    -- initialize zone pulldown
    local mapdropdown2 = _G[lm.."DropDown2"];
    if(mapdropdown2) then
        UIDropDownMenu_ClearAll(mapdropdown2);
        UIDropDownMenu_Initialize(mapdropdown2, TWMFrameDropDown2_Initialize);
    end

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

function TWMFrameDropDown2_OnLoad(self)
    self:RegisterEvent("VARIABLES_LOADED");
end

function TWMFrameDropDown2_OnEvent(self, event)
    if(event == "VARIABLES_LOADED") then
        UIDropDownMenu_SetWidth(self, 150);
    end
end

function TWMFrameDropDown2_Initialize()
    --local lm = string.gsub(UIDROPDOWNMENU_INIT_MENU,"DropDown2","");
    local lm = "TWMFrame";

    local frame = _G[lm];
    frame.zonepulldowns = {};
    local info;

    if(Twm_mapareas[frame.opt.Map] ~= nil) then
        for h,v in pairs(Twm_mapareas[frame.opt.Map]) do
            if(Twm_areadb[h]) then
                tinsert(frame.zonepulldowns, h);
            end
        end
    end

    table.sort(frame.zonepulldowns,
        function (a,b) return Twm_areadb[a] < Twm_areadb[b]; end);
    for j,v in ipairs(frame.zonepulldowns) do
        info = {
            text = Twm_areadb[v];
            value = frame;
            func = TWMFrameDropDownButton2_OnClick;
        };
        UIDropDownMenu_AddButton(info);
    end 

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

function TWMFrameDropDownButton2_OnClick(self)
    local frame = self.value;
    local lm = frame:GetName();
    local z = frame.zonepulldowns[self:GetID()];

    if(not z) then return; end

    frame:CenterOnZone(z);

    -- SetLocation() re-derives a zone from the new view's center via
    -- GetZoneIDs(), which picks the smallest-area (most specific) zone
    -- whose box contains that point -- for a zone whose own box is fully
    -- nested inside another's (e.g. a city inset), the center can still
    -- land there and get correctly reselected, but it's not guaranteed to
    -- exactly match `z` (e.g. dead center of a oddly-shaped zone can fall
    -- just outside its own box). We already know exactly which zone was
    -- picked here, so re-assert it rather than trust the recomputation.
    local dd2 = _G[lm.."DropDown2"];
    if(dd2) then
        for i,v in ipairs(frame.zonepulldowns) do
            if(v == z) then
                UIDropDownMenu_SetSelectedID(dd2, i);
                UIDropDownMenu_SetText(dd2, Twm_areadb[z]);
                break;
            end
        end
    end
end

function TWMFrameTemplate:UpdateDropDown2()
    local framename = self:GetName();
    local dd2 = _G[framename.."DropDown2"];
    if(dd2 and self.zonepulldowns) then
        local zid = self:GetZoneIDs();
        local found = false;
        for i,v in ipairs(self.zonepulldowns) do
	--print(tostring(v).." "..tostring(vid))
            if(v == zid) then
                UIDropDownMenu_SetSelectedID(dd2, i);
                UIDropDownMenu_SetText(dd2,Twm_areadb[zid]);
                found = true;
                break;
            end
        end

        -- no zone under the current view center (e.g. panned past the map
        -- edge) -- just leave the dropdown blank rather than snapping the
        -- view somewhere else out from under the player's drag.
        if(not found) then
            UIDropDownMenu_SetSelectedID(dd2, 0);
            UIDropDownMenu_SetText(dd2, "");
        end
    end
end

--

function TWMFramePlayerJumpButton_Toggle(btn)
    local f = btn:GetParent();
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
    local f = btn:GetParent();
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
    local map = TWM_GetUnitContinentPosition(unit);
    if(map and frame.opt and map == frame.opt.Map) then
        return;
    end
    TWMFramePlayerJumpButton_Seek(frame, unit);
end

function TWMFramePlayerJumpButton_Update(btn)
    if(btn:GetParent() and btn:GetParent().opt) then
        local t = btn:GetParent().opt.track;

        if(t) then
            tex = "Interface\\Buttons\\UI-Panel-Button-Down";
        else
            tex = "Interface\\Buttons\\UI-Panel-Button-Up";
        end
        btn.Left:SetTexture(tex);
        btn.Middle:SetTexture(tex);
        btn.Right:SetTexture(tex);
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

    if(z > 32 and (z > vfh or z > vfw)) then
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

function TWMFrameTemplate:SetLocation(x,y,forceupdate,forcePointsUpdate)
    local zx, zy, mymap;
    local framename = self:GetName();
    local vfname = framename.."ViewFrame";
    local vf = _G[vfname];
    local texturelayout = self.texturelayout;
    local zoom = self.opt.Zoom;
    local wzoom, hzoom = self.wzoom,self.hzoom;
    local wzoom_real,hzoom_real = self.wzoom_real, self.hzoom_real;

    zx = math.floor(x);
    zy = math.floor(y);
    mymap = self.opt.Map;

    -- offset calc
    local px, py;
    px = math.floor((x-zx)*zoom);
    py = math.floor((y-zy)*zoom);

    local needsContentRefresh = (zx ~= math.floor(self.opt.Location[1]) or forceupdate or
        zy ~= math.floor(self.opt.Location[2]) or mymap ~= self.lastmap);
    if(needsContentRefresh) then
        local v = {};
        local jx, jy, nsv;

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

                if(livezone) then
                    v[hx][hy] = { TWM_GetTileFileName(mymap, col, row) };
                else
                    v[hx][hy] = dummyv;
                end

                -- set textures
                if(v[hx][hy]) then
                    TWM_SetTileTexture(tex, TWM_GetTileTexture(mymap, v[hx][hy][1]), TWM_GetTileFilter());
                    tex:SetVertexColor(1,1,1,1);
                else
                    tex:SetTexture("Interface\\Buttons\\WHITE8X8");
                    tex:SetVertexColor(0,0,0,1);
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

    -- Do offset and clipping (:SetTexCoord and :SetHeight/Width)
    -- We do the most thinking about border textures 

    local bottomh = vf:GetHeight()-zoom*(hzoom-2)-(zoom-py);
    local rightw = vf:GetWidth()-zoom*(wzoom-2)-(zoom-px);
    local needbottom_extra = false;
    local needright_extra = false;
    local old_bottomh, old_rightw;
    if(bottomh > zoom) then
        needbottom_extra = true;
        old_bottomh = bottomh;
        bottomh = zoom;
    end
    if(rightw > zoom) then
        needright_extra = true;
        old_rightw = rightw;
        rightw = zoom;
    end

    -- center textures (easy)
    for w = 2,wzoom-1 do
        for h = 2,hzoom-1 do
            twm_raw_setoff(texturelayout[w][h],vfname,px,py);
        end
    end

    -- Upper left corner
    texturelayout[1][1]:SetTexCoord( (x-zx), 1, (y-zy), 1);
    texturelayout[1][1]:SetHeight( zoom-py);
    texturelayout[1][1]:SetWidth( zoom-px);
    twm_raw_setoff(texturelayout[1][1],vfname,0,0);

    -- Upper right corner
    if(px ~= 0 or wzoom ~= wzoom_real) then
        texturelayout[wzoom][1]:Show();
        texturelayout[wzoom][1]:SetTexCoord( 0, rightw/zoom, (y-zy), 1);
        texturelayout[wzoom][1]:SetHeight( zoom-py);
        texturelayout[wzoom][1]:SetWidth(rightw);
        twm_raw_setoff(texturelayout[wzoom][1],vfname,px,0);
    else
        texturelayout[wzoom][1]:Hide();
    end

    -- Lower left corner
    if(py ~= 0  or wzoom ~= wzoom_real) then
        texturelayout[1][hzoom]:Show();
        texturelayout[1][hzoom]:SetTexCoord( (x-zx), 1, 0, bottomh/zoom);
        texturelayout[1][hzoom]:SetWidth( zoom-px);
        texturelayout[1][hzoom]:SetHeight(bottomh);
        twm_raw_setoff(texturelayout[1][hzoom],vfname,0,py);
    else
        texturelayout[1][hzoom]:Hide();
    end

    -- lower right corner
    if((py ~= 0 and px ~= 0) or wzoom ~= wzoom_real) then
        texturelayout[wzoom][hzoom]:Show();
        texturelayout[wzoom][hzoom]:SetTexCoord( 0, rightw/zoom, 0, bottomh/zoom);
        texturelayout[wzoom][hzoom]:SetHeight(bottomh);
        texturelayout[wzoom][hzoom]:SetWidth(rightw);
        twm_raw_setoff(texturelayout[wzoom][hzoom],vfname,px,py);
    else
        texturelayout[wzoom][hzoom]:Hide();
    end

    -- top line
    for h = 2,wzoom-1 do
        texturelayout[h][1]:SetTexCoord( 0, 1, (y-zy), 1);
        texturelayout[h][1]:SetHeight( zoom-py);
        twm_raw_setoff(texturelayout[h][1],vfname,px,0);
    end

    -- bottom line
    if(py ~= 0 or wzoom ~= wzoom_real) then
        for h = 2,wzoom-1 do
            texturelayout[h][hzoom]:Show();
            texturelayout[h][hzoom]:SetTexCoord( 0, 1, 0, bottomh/zoom);
            texturelayout[h][hzoom]:SetHeight(bottomh);
            twm_raw_setoff(texturelayout[h][hzoom],vfname, px,py);
        end
    else
        for h = 2,wzoom-1 do
            texturelayout[h][hzoom]:Hide();
        end
    end

    -- left line
    for h = 2,hzoom-1 do
        texturelayout[1][h]:SetTexCoord( (x-zx), 1, 0, 1);
        texturelayout[1][h]:SetWidth( zoom-px);
        twm_raw_setoff(texturelayout[1][h],vfname,0,py);
    end

    -- right line
    if(px ~= 0 or wzoom ~= wzoom_real) then
        for h = 2,hzoom-1 do
            texturelayout[wzoom][h]:Show();
            texturelayout[wzoom][h]:SetTexCoord( 0, rightw/zoom, 0, 1);
            texturelayout[wzoom][h]:SetWidth(rightw);
            twm_raw_setoff(texturelayout[wzoom][h],vfname,px,py);
        end
    else
        for h = 2,hzoom-1 do
            texturelayout[wzoom][h]:Hide();
        end
    end

    -- if our zoom is not a multiple of our size, we have a little extra we
    -- need to worry about :X
    if(wzoom_real ~= wzoom) then
        if(needright_extra) then
            rightw = (old_rightw-zoom);
        end

        -- This whole column loop is about row hzoom_real specifically being
        -- a genuinely EXTRA row beyond the normal grid. When hzoom_real ==
        -- hzoom, there's no such extra row -- row hzoom_real IS row hzoom,
        -- already fully drawn by the corner/bottom-line code above, and
        -- must not be touched (let alone hidden) here.
        if(hzoom_real ~= hzoom) then
            if(needbottom_extra) then
                bottomh = (old_bottomh-zoom);

                -- The true last (bottom-clipped) column within this loop's range
                -- (1..wzoom_real-1, the true rightmost column wzoom_real is
                -- handled separately below): wzoom_real-1 only if that's a real
                -- "extra" column this frame (needright_extra); otherwise it's
                -- plain wzoom, which can be LESS than wzoom_real-1 when
                -- wzoom_real was structurally allocated but isn't needed now.
                local lastCol = needright_extra and (wzoom_real-1) or wzoom;

                for h = 1,wzoom_real-1 do
                    if(h > lastCol) then
                        texturelayout[h][hzoom_real]:Hide();
                    else
                        texturelayout[h][hzoom_real]:SetHeight(bottomh);
                        if(h == 1) then
                            texturelayout[h][hzoom_real]:SetTexCoord( (x-zx), 1, 0, bottomh/zoom);
                            texturelayout[h][hzoom_real]:SetWidth(zoom-px);
                            twm_raw_setoff(texturelayout[h][hzoom_real],vfname,0,py);
                        elseif(h == lastCol and not needright_extra) then
                            -- lastCol is genuinely the right edge here (wzoom)
                            -- only when there's no further column beyond it --
                            -- rightw was already reassigned above to the OTHER
                            -- column's (wzoom_real) leftover when needright_extra
                            -- is true, so it must not be used for this column then.
                            texturelayout[h][hzoom_real]:SetWidth(rightw);
                            texturelayout[h][hzoom_real]:SetTexCoord( 0, rightw/zoom, 0, bottomh/zoom);
                            twm_raw_setoff(texturelayout[h][hzoom_real],vfname,px,py);
                        else
                            texturelayout[h][hzoom_real]:SetWidth(zoom);
                            texturelayout[h][hzoom_real]:SetTexCoord( 0, 1, 0, bottomh/zoom);
                            twm_raw_setoff(texturelayout[h][hzoom_real],vfname,px,py);
                        end
                        texturelayout[h][hzoom_real]:Show();
                    end
                end

            else
                for h = 1,wzoom_real-1 do
                    texturelayout[h][hzoom_real]:Hide();
                end
            end
        end

        -- Same guard, other axis: when wzoom_real == wzoom, column wzoom_real
        -- IS column wzoom, already fully drawn by the corner/right-line code
        -- above -- must not be touched here.
        if(wzoom_real ~= wzoom) then
            if(needright_extra) then
                -- The true last (bottom-clipped) row is hzoom_real only if
                -- genuinely needed this frame (needbottom_extra); otherwise
                -- it's plain hzoom, which can be LESS than hzoom_real-1 when
                -- hzoom_real was structurally allocated but isn't needed
                -- now -- anything beyond it must be hidden instead of
                -- wrongly treated as a full-height middle row.
                local lastRow = needbottom_extra and hzoom_real or hzoom;

                for h = 1,hzoom_real do
                    if(h > lastRow) then
                        texturelayout[wzoom_real][h]:Hide();
                    else
                        texturelayout[wzoom_real][h]:SetWidth(rightw);
                        texturelayout[wzoom_real][h]:Show();
                        if(h == 1) then
                            texturelayout[wzoom_real][h]:SetTexCoord( 0, rightw/zoom, (y-zy), 1);
                            texturelayout[wzoom_real][h]:SetHeight(zoom-py);
                            twm_raw_setoff(texturelayout[wzoom_real][h],vfname,px,0);
                        elseif(h == lastRow) then
                            texturelayout[wzoom_real][h]:SetHeight(bottomh);
                            texturelayout[wzoom_real][h]:SetTexCoord( 0, rightw/zoom, 0, bottomh/zoom);
                            twm_raw_setoff(texturelayout[wzoom_real][h],vfname,px,py);
                        else
                            texturelayout[wzoom_real][h]:SetHeight(zoom);
                            texturelayout[wzoom_real][h]:SetTexCoord( 0, rightw/zoom, 0, 1);
                            twm_raw_setoff(texturelayout[wzoom_real][h],vfname,px,py);
                        end
                    end

                end
            else
                for h = 1,hzoom_real do
                    texturelayout[wzoom_real][h]:Hide();
                end
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
            -- Computed directly instead, from the same TOPLEFT formula
            -- twm_raw_setoff uses for a full (uncropped) tile at this grid
            -- slot, so the label always sits at its tile's one true
            -- center regardless of how much of the tile is actually
            -- cropped into view.
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

    -- set zone text
    if(not vf.dragme) then
        self:UpdateDropDown2();
    end

    self.opt.Location[1] = x;
    self.opt.Location[2] = y;

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
    elseif(u == self.opt.track) then
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

function twm_raw_setoff(texture, parent, px, py) 
    local zoom = _G[parent]:GetParent().opt.Zoom
    texture:ClearAllPoints();
    texture:SetPoint("TOPLEFT", parent,
            "TOPLEFT", (zoom)*(texture.hx-1) - px,
            -(zoom)*(texture.hy-1) + py);
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
        self:GetParent():AdjustLocation(twm_lastdragx - fx, twm_lastdragy - fy);
    end

    twm_lastdragx = fx;
    twm_lastdragy = fy;
end

function TWMFrameViewFrame_UpdateCursorCoord(self)
    local x, y = GetCursorPosition();
    local rx, ry = unpack(TWMFrame.opt.Location);
    local top = self:GetTop();
    local zoom = TWMFrame.opt.Zoom;
    
    if(self.lastoux == x and self.lastouy == y) then
        return;
    end
    self.lastoux = x;
    self.lastouy = y;

    x = x / self:GetEffectiveScale();
    y = y / self:GetEffectiveScale();

    rx = rx + math.floor(x - self:GetLeft())/zoom;
    ry = ry + 512/zoom-math.floor(y - self:GetBottom())/zoom;
    local bigx, bigy = TWM_Mini2Big_Coord(rx,ry);
end

function TWMFrameTemplate:OnUpdate(elapsed)
    self.update_time = self.update_time + elapsed;

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
        return self.lines[self.nextfree-1];
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
    f.Text:SetPoint("TOPLEFT", f.Icon, 24, 0);
  
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
    self:SetWidth(wid+64);
end


function TWMTooltipTemplate:Clear() 
    for h = 1,(self.nextfree-1) do
        self.lines[h]:Hide();
    end
    self.nextfree = 1;
    self:FixSize();
    self:Hide();
end


