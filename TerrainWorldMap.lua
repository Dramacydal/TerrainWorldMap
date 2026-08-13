--local GatherMate = LibStub("AceAddon-3.0"):GetAddon("GatherMate")
--local pre = "textures\\Minimap\\";
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
function TWM_GetTileFileName(continent, col, row)
    if(TWM_IsDrawUnderwaterEnabled()
            and Twm_NoLiquidTiles and Twm_NoLiquidTiles[continent]
            and Twm_NoLiquidTiles[continent][format("%.2dx%.2d", col, row)]) then
        return format("noliquid_map%.2d_%.2d", col, row);
    end
    return format("map%.2d_%.2d", col, row);
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

TWM_FRAME_OPTION_DEFAULTS = {
    ["Locked"] = false,
    ["Map"] = "Kalimdor",
    ["Location"] = {31.0625, 33.250},
    ["Alpha"] = 1,
    ["IconSize"] = 1.0,
    ["PointCfg"] = {},
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

-- Twm_ContinentMapID is defined in Data_<Flavor>/mapdata_poi.lua (loads before this file).

local TWM_ContinentByMapID = {};
for h,v in pairs(Twm_ContinentMapID) do
    TWM_ContinentByMapID[v] = h;
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
        queryMapID = Twm_ContinentMapID[continent];
    end
    if(not zoneBox) then return nil; end

    local pos = C_Map.GetPlayerMapPosition(queryMapID, u);
    if(not pos) then return nil; end

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
    TWMFrame.OnEventExtra = TWMFrame_OnEventExtra;
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

    -- wrap mapnotes for updates
    if(MapNotes_DeleteNote) then
        TWM_old_MapNotes_DeleteNote = MapNotes_DeleteNote;
        MapNotes_DeleteNote = function(...)
            local v = TWM_old_MapNotes_DeleteNote(...)
            TWMPoints_ForceUpdate();
            return v;
        end
        TWM_old_MapNotes_WriteNote = MapNotes_WriteNote;
        MapNotes_WriteNote = function(...)
            local v = TWM_old_MapNotes_WriteNote(...);
            TWMPoints_ForceUpdate();
            return v;
        end
    end

    -- wrap gatherer
    --print("Test for GatherMate")
    if(GatherMate) then
        --print("Found")
         TWM_old_GatherMate = GatherMate;
         GatherMate = function(...)
            local v = TWM_old_GatherMate(...)
            TWMPoints_ForceUpdate();
            return v;
        end
    end

    -- myaddons support
    TerrainWorldMapDetails = {
        name = TWM_TITLE,
	version = TWM_VERSION,
	releaseDate = TWM_RELEASE_DATE,
	author = TWM_AUTHOR,
        website = TWM_WEBSITE,
	email = TWM_AUTHOR_EMAIL,
	category = MYADDONS_CATEGORY_MAP,
    };
    TerrainWorldMapMAHelp = TWM_HELP_TEXT;

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
    -- child Frame declared later in the same XML block.
    TWMFrameVersion:ClearAllPoints();
    TWMFrameVersion:SetPoint("RIGHT", TWMFrameLockButton, "LEFT", -6, 0);

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
function TWMFrame_OnResizeStop(self)
    if(not self.opt or self.inResizeRefresh) then return; end
    self.inResizeRefresh = true;
    self.opt.Width, self.opt.Height = self:GetSize();
    self:SetZoom(self.opt.Zoom, true);
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

    if(self.OnEventExtra) then
        self:OnEventExtra(event, ...);
    end
end

function TWMFrame_OnEventExtra(self, event, addonName)
    local framename = self:GetName();

    if(event == "ADDON_LOADED" and addonName == "TerrainWorldMap") then
        if(myAddOnsFrame_Register) then
            myAddOnsFrame_Register(TerrainWorldMapDetails, TerrainWorldMapMAHelp);
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
        UIDropDownMenu_SetSelectedID(self, 1);
        UIDropDownMenu_SetWidth(self, 150);
    end
end

function TWMFrameDropDown_Initialize()
    local i = 1;
    local info;
    for h,v in pairs(TWM_MAPS) do
            info = {
                    text = h;
                    func = TWMFrameDropDownButton_OnClick;
                    --value = _G[UIDROPDOWNMENU_INIT_MENU]:GetParent();
            };
            UIDropDownMenu_AddButton(info);
            i = i + 1;
    end
end

function TWMFrameDropDownButton_OnClick(self)
        local d = 1;
	i = self:GetID();
        for h,v in pairs(TWM_MAPS) do
            if(d == i) then
                --print(tostring(self.value).." "..tostring(v[1]))
                return _G["TWMFrame"]:SetMap(v[1]);
            end
            d = d + 1;
        end
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
    
    local mapdropdown = _G[lm.."DropDown"];
    if(mapdropdown) then
        local i = 1;
        for h,v in pairs(TWM_MAPS) do
            if(v[1] == mapname) then
                UIDropDownMenu_SetSelectedID(mapdropdown, i);
                UIDropDownMenu_SetText(mapdropdown,h);
            end
            i = i + 1;
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

    self:SetLocation(mx-(512/2)/zoom, my-(512/2)/zoom);
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

function TWMFrameTemplate:SetZoom(z, nocenter)
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

    if(_G[lm.."MapTexture"..(self.wzoom_real*self.hzoom_real)] == nil) then
        return self:SetZoom(z+4);
    elseif(z > 32 and (z > vfh or z > vfw)) then
        return self:SetZoom(z-4);
    end
    local lastzoom = self.opt.Zoom;
    self.opt.Zoom = z;

    -- allocate textures
    self.texturelayout = {};
    for hw = 1,self.wzoom_real do
        self.texturelayout[hw] = {};
        for hh = 1,self.hzoom_real do
            self.texturelayout[hw][hh] = _G[lm.."MapTexture"..textureno];
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
        self:AdjustLocation(0,0,true)
    else
        local oldcx, oldcy;
        local newcx, newcy;

        oldcy = (vf:GetHeight()/2)/lastzoom;
        oldcx = (vf:GetWidth()/2)/lastzoom;
        newcy = (vf:GetHeight()/2)/z;
        newcx = (vf:GetWidth()/2)/z;

        self:AdjustLocation(oldcx-newcx,-oldcy+newcy,true)
    end
end

function TWMFrameTemplate:GetZoom()
    return self.opt and self.opt.Zoom or 256;
end

function TWMFrameTemplate:SetLocation(x,y,forceupdate)
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
		    tex:SetTexture(pre..mymap.."\\"..v[hx][hy][1]);
                    tex:SetVertexColor(1,1,1,1);
                else
                    tex:SetTexture("Interface\\Buttons\\WHITE8X8");
                    tex:SetVertexColor(0,0,0,1);
                end

                -- debug: label this tile with its grid coordinate and the
                -- live zone name the client reports at that spot.
                if(TWM_DebugTiles) then
                    if(not tex.debugLabel) then
                        tex.debugLabel = vf:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge");
                        tex.debugLabel:SetPoint("CENTER", tex, "CENTER");
                        tex.debugLabel:SetJustifyH("CENTER");
                    end

                    tex.debugLabel:SetText(tilekey.."\n"..(livezone or "|cffff4040(none)|r"));
                    tex.debugLabel:Show();
                elseif(tex.debugLabel) then
                    tex.debugLabel:Hide();
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

    -- set zone text
    if(not vf.dragme) then
        self:UpdateDropDown2();
    end

    self.opt.Location[1] = x;
    self.opt.Location[2] = y;

    TWMPoints_OnMove(self, x,y);
end

function TWMFrameTemplate:GetLocation()
    local fm = self:GetName();

    return self.opt.Location[1],
        self.opt.Location[2];
end

function TWMFrameTemplate:AdjustLocation(dx,dy,forceupdate)
    local fm = self:GetName();

    if(self.opt == nil) then
        -- we aren't ready yet!
        return;
    end

    self:SetLocation(
        self.opt.Location[1] + dx,
        self.opt.Location[2] - dy,
                        forceupdate);
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
    f:EnableMouse(true);

    f.Icon = f:CreateTexture(nil, "OVERLAY");
    f.Icon:SetPoint("TOPLEFT", f);
    
    f.Foreground = f:CreateFontString(nil, "ARTWORK");
    f.Foreground:SetFontObject(GameFontHighlight);
    f.Foreground:SetTextColor(0, 0, 0);
    f.Foreground:SetShadowOffset(-1, 0);
    f.Foreground:SetPoint("TOPLEFT", f);

    f:SetFrameLevel(f:GetFrameLevel() + 4);
    f.Clear = YP_Clear;
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


