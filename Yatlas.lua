--local GatherMate = LibStub("AceAddon-3.0"):GetAddon("GatherMate")
--local pre = "textures\\Minimap\\";
local pre = "World\\Minimaps\\";

local MINI2BIGX = 533.3333;
local MINI2BIGY = 533.3333;

YatlasOptions = {}

YA_FRAME_OPTION_DEFAULTS = {
    ["Locked"] = true,
    ["Map"] = "Kalimdor",
    ["Location"] = {31.0625, 33.250},
    ["Alpha"] = 1,
    ["IconSize"] = 14,
    ["PointCfg"] = {},
    ["Zoom"] = 256,
};

local dummyv = nil;
local nilfunc = function() end

-- Debug: overlay each map tile with its grid-cell coordinate and the live
-- zone reported there. Toggle with "/yatlas debug".
Yatlas_DebugTiles = false;

function Yatlas_ToggleTileDebug()
    Yatlas_DebugTiles = not Yatlas_DebugTiles;
    for _, fname in ipairs({"YatlasFrame", "BigYatlasFrame"}) do
        local f = _G[fname];
        if(f and f.opt) then
            f:SetLocation(f.opt.Location[1], f.opt.Location[2], true);
        end
    end
    print("Yatlas: tile debug labels " .. (Yatlas_DebugTiles and "ON" or "OFF"));
end

-- Whether a map tile has real terrain, per this client's own WDT data
-- (Yatlas_WDTValidTiles, mapdata_tiles.lua -- ground truth extracted from
-- world/maps/<continent>/<continent>.wdt's rootADT field, since a tile's
-- minimap preview texture can exist even when no terrain does, e.g.
-- leftover Cataclysm-only art with no TBC-era ADT behind it). Used both to
-- gate map-tile rendering and for the "/yatlas debug" tile overlay, which
-- also reports the specific named zone (Yatlas_mapareas) when there is one.
function Yatlas_GetLiveZoneNameForBigCoord(map, bigx, bigy, tilekey)
    local valid = tilekey and Yatlas_WDTValidTiles[map] and Yatlas_WDTValidTiles[map][tilekey];
    if(not valid) then return nil; end

    local areas = Yatlas_mapareas[map];
    if(areas) then
        for id, box in pairs(areas) do
            if(id ~= 0 and bigx < box[1] and bigx > box[2] and bigy < box[3] and bigy > box[4]) then
                return Yatlas_areadb[id];
            end
        end
    end

    return "|cff8080ff(terrain)|r";
end

-- Yatlas_ContinentMapID is defined in mapdata_poi.lua (loads before this file).

local Yatlas_ContinentByMapID = {};
for h,v in pairs(Yatlas_ContinentMapID) do
    Yatlas_ContinentByMapID[v] = h;
end

-- Walks a uiMapID up its parent chain until it hits one of our known
-- continents (C_Map has no "give me the continent" shortcut).
function Yatlas_GetContinentForMapID(mapID)
    local guard = 0;
    while(mapID and guard < 10) do
        if(Yatlas_ContinentByMapID[mapID]) then
            return Yatlas_ContinentByMapID[mapID];
        end
        local info = C_Map.GetMapInfo(mapID);
        if(not info) then return nil; end
        mapID = info.parentMapID;
        guard = guard + 1;
    end
    return nil;
end

-- Replaces the old GetPlayerMapPosition(u); returns nil if the unit isn't on
-- one of Yatlas' 4 known continents (no WorldMapFrame navigation needed).
function Yatlas_GetUnitContinentPosition(u)
    local mapID = C_Map.GetBestMapForUnit(u);
    if(not mapID) then return nil; end

    local continent = Yatlas_GetContinentForMapID(mapID);
    if(not continent) then return nil; end

    local pos = C_Map.GetPlayerMapPosition(Yatlas_ContinentMapID[continent], u);
    if(not pos) then return nil; end

    local x, y = pos:GetXY();
    return continent, x, y;
end

YatlasFrameTemplate = {};

function YatlasFrame_Bootstrap(self, frame)
    --frame = YatlasFrame;
    if(frame == nil) then
        frame = self;
    end

    for h,v in pairs(YatlasFrameTemplate) do
        if(frame[h]) then
            frame["old_"..h] = frame[h];
        end

        frame[h] = v;
    end
    frame:OnLoad();
end

function YatlasFrameTemplate:OnLoad()
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

    YAPoints_RegisterFrame(self:GetName());

    self.update_time = 0;
end

function YatlasFrame_OnLoadExtra()
    YatlasFrame.OnEventExtra = YatlasFrame_OnEventExtra;
    YatlasFrame.YA_PD_allocText = "YA_PD_allocText";
    YatlasFrame.YA_PD_ResetList = "YA_PD_ResetList";
    
    SLASH_YATLAS1 = "/yatlas";
    SlashCmdList["YATLAS"] = function(msg)
        if(msg == "debug") then
            Yatlas_ToggleTileDebug();
        elseif(msg == "map on") then
            Yatlas_SetWorldMapOverlay(true);
        elseif(msg == "map off") then
            Yatlas_SetWorldMapOverlay(false);
        else
            YatlasFrame:Toggle();
        end
    end

    YatlasFrame.hoverTooltip = "YatlasTooltip";

    -- wrap mapnotes for updates
    if(MapNotes_DeleteNote) then
        YA_old_MapNotes_DeleteNote = MapNotes_DeleteNote;
        MapNotes_DeleteNote = function(...)
            local v = YA_old_MapNotes_DeleteNote(...)
            YAPoints_ForceUpdate();
            return v;
        end
        YA_old_MapNotes_WriteNote = MapNotes_WriteNote;
        MapNotes_WriteNote = function(...)
            local v = YA_old_MapNotes_WriteNote(...);
            YAPoints_ForceUpdate();
            return v;
        end
    end

    -- wrap gatherer
    --print("Test for GatherMate")
    if(GatherMate) then
        --print("Found")
         YA_old_GatherMate = GatherMate;
         GatherMate = function(...)
            local v = YA_old_GatherMate(...)
            YAPoints_ForceUpdate();
            return v;
        end
    end

    -- myaddons support
    YatlasDetails = {
        name = YATLAS_TITLE,
	version = YATLAS_VERSION,
	releaseDate = YATLAS_RELEASE_DATE,
	author = YATLAS_AUTHOR,
        website = YATLAS_WEBSITE,
	email = YATLAS_AUTHOR_EMAIL,
	category = MYADDONS_CATEGORY_MAP,
    };
    YatlasMAHelp = YATLAS_HELP_TEXT;
end

function BigYatlasFrame_OnLoadExtra()
    UIPanelWindows["BigYatlasFrame"] = { area = "full",	pushable = 0,	whileDead = 1 };

    SLASH_BIGYATLAS1 = "/bigyatlas";
    SlashCmdList["BIGYATLAS"] = function() BigYatlasFrame:Toggle() end

    BigYatlasFrame.RawBigShow = BigYatlasFrame.Show;
    BigYatlasFrame.Show = function(self)
        SetupFullscreenScale(self);
        return self:RawBigShow();
    end

    BigYatlasFrame.hoverTooltip = "BigYatlasTooltip";
end

function YatlasFrameTemplate:OnEvent(event, ...)
    local framename = self:GetName();

    if(event == "VARIABLES_LOADED") then
        if(not Yatlas_LandmarksScraped) then
            Yatlas_LandmarksScraped = true;
            Yatlas_ScrapeLandmarks();
        end

        if(YatlasOptions == nil) then
            YatlasOptions = {};
        end

        if(YatlasOptions.ShowButton == nil) then
            YatlasOptions.ShowButton = true;
        end
        if(YatlasOptions.ButtonLocation == nil) then
            YatlasOptions.ButtonLocation = 0;
        end

        self:EnsureExistingOptions();

        self.opt = YatlasOptions.Frames[framename];
        self:SetZoom(self.opt.Zoom);
        self:SetMap(self.opt.Map);

        self:UpdateLock();
        self:SetAlpha(self.opt.Alpha);

        if(self.opt.track) then
            YatlasFramePlayerJumpButton_Seek(self, self.opt.track);
        end
    end

    if(self.OnEventExtra) then
        self:OnEventExtra(event, ...);
    end
end

function YatlasFrame_OnEventExtra(self, event, addonName)
    local framename = self:GetName();

    if(event == "ADDON_LOADED" and addonName == "Yatlas") then
        if(myAddOnsFrame_Register) then
            myAddOnsFrame_Register(YatlasDetails, YatlasMAHelp);
        end
    end
end

function YatlasFrameTemplate:EnsureExistingOptions()
    if(YatlasOptions.Frames == nil) then
        YatlasOptions.Frames = {};
    end

    local name = self:GetName();

    if(YatlasOptions.Frames[name] == nil) then
        YatlasOptions.Frames[name] = {};
    end

    for h,v in pairs(YA_FRAME_OPTION_DEFAULTS) do
        if(YatlasOptions.Frames[name][h] ~= nil) then
            -- don't do anything!
        elseif(YatlasOptions[h] ~= nil) then
            YatlasOptions.Frames[name][h] = YatlasOptions[h];
            YatlasOptions[h] = nil;
        elseif(type(v) == "table") then
            -- don't copy reference.  copy value...unfortunately, we only 
            -- copy one level deep, which seems good enough...
            YatlasOptions.Frames[name][h] = {};
            for x,k in pairs(v) do
                YatlasOptions.Frames[name][h][x] = k;
            end
        else
            YatlasOptions.Frames[name][h] = v;
        end
    end
end

function YatlasFrameTemplate:Toggle()
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

function YatlasFrameDropDown_OnLoad(self)
    self:RegisterEvent("VARIABLES_LOADED");
end

function YatlasFrameDropDown_OnEvent(self, event)
    if(event == "VARIABLES_LOADED") then
        UIDropDownMenu_Initialize(self, YatlasFrameDropDown_Initialize);
        UIDropDownMenu_SetSelectedID(self, 1);
        UIDropDownMenu_SetWidth(self, 150);
    end
end

function YatlasFrameDropDown_Initialize()
    local i = 1;
    local info;
    for h,v in pairs(YA_MAPS) do
            info = {
                    text = h;
                    func = YatlasFrameDropDownButton_OnClick;
                    --value = _G[UIDROPDOWNMENU_INIT_MENU]:GetParent();
            };
            UIDropDownMenu_AddButton(info);
            i = i + 1;
    end
end

function YatlasFrameDropDownButton_OnClick(self)
        local d = 1;
	i = self:GetID();
        for h,v in pairs(YA_MAPS) do
            if(d == i) then
                --print(tostring(self.value).." "..tostring(v[1]))
                return _G["YatlasFrame"]:SetMap(v[1]);
            end
            d = d + 1;
        end
end

function YatlasFrameTemplate:ToggleLock()
    if(self.opt.Locked) then
        self.opt.Locked = false;
    else
        self.opt.Locked = true;
    end   
    self:UpdateLock();
end

function YatlasFrameTemplate:UpdateLock()
    local fm = self:GetName();
    local norm = _G[fm.."LockButtonNorm"];
    local push = _G[fm.."LockButtonPush"];

    if(norm and push) then
        if(self.opt.Locked) then
            norm:SetTexture("Interface\\AddOns\\Yatlas\\images\\LockButton-Locked-Up");
            push:SetTexture("Interface\\AddOns\\Yatlas\\images\\LockButton-Locked-Down");
        else
            norm:SetTexture("Interface\\AddOns\\Yatlas\\images\\LockButton-Unlocked-Up");
            push:SetTexture("Interface\\AddOns\\Yatlas\\images\\LockButton-Unlocked-Down");
        end
    end
end

function YatlasFrameTemplate:SetMap(mapname)
    local lm = self:GetName();

    self.opt.Map = mapname;
    
    local mapdropdown = _G[lm.."DropDown"];
    if(mapdropdown) then
        local i = 1;
        for h,v in pairs(YA_MAPS) do
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
        UIDropDownMenu_Initialize(mapdropdown2, YatlasFrameDropDown2_Initialize);
    end

    self:AdjustLocation(0,0,true);
    YAPoints_OnMapChange(self);
    self.lastmap = self.opt.Map;
end

function YatlasFrameDropDown2_OnLoad(self)
    self:RegisterEvent("VARIABLES_LOADED");
end

function YatlasFrameDropDown2_OnEvent(self, event)
    if(event == "VARIABLES_LOADED") then
        UIDropDownMenu_SetWidth(self, 150);
    end
end

function YatlasFrameDropDown2_Initialize()
    --local lm = string.gsub(UIDROPDOWNMENU_INIT_MENU,"DropDown2","");
    local lm = "YatlasFrame";

    local frame = _G[lm];
    frame.zonepulldowns = {};
    local info;

    if(Yatlas_mapareas[frame.opt.Map] ~= nil) then
        for h,v in pairs(Yatlas_mapareas[frame.opt.Map]) do
            if(Yatlas_areadb[h]) then
                tinsert(frame.zonepulldowns, h);
            end
        end
    end

    table.sort(frame.zonepulldowns,
        function (a,b) return Yatlas_areadb[a] < Yatlas_areadb[b]; end);
    for j,v in ipairs(frame.zonepulldowns) do
        info = {
            text = Yatlas_areadb[v];
            value = frame;
            func = YatlasFrameDropDownButton2_OnClick;
        };
        UIDropDownMenu_AddButton(info);
    end 

end

function YatlasFrameDropDownButton2_OnClick(self)
    local frame = self.value;
    local lm = frame:GetName();
    local z = frame.zonepulldowns[self:GetID()];
    local map = frame.opt.Map;
    local zoom = frame:GetZoom();

    if(not z or not Yatlas_mapareas[map]) then return; end
    
    if(type(Yatlas_mapareas[map][z]) == "table") then
        local x, y, mx, my;

        x = (Yatlas_mapareas[map][z][1]+
           Yatlas_mapareas[map][z][2])/2;
        y = (Yatlas_mapareas[map][z][3]+
           Yatlas_mapareas[map][z][4])/2;

        mx, my = Yatlas_Big2Mini_Coord(x,y);

        frame:SetLocation(mx-(512/2)/zoom, my-(512/2)/zoom);

        -- SetLocation() re-derives a zone from the new view's center via
        -- GetZoneIDs(), which picks whichever zone's (overlapping)
        -- bounding box it happens to hit first -- that can silently
        -- relabel the dropdown to a neighboring zone. We already know
        -- exactly which zone was picked, so re-assert it here.
        local dd2 = _G[lm.."DropDown2"];
        if(dd2) then
            for i,v in ipairs(frame.zonepulldowns) do
                if(v == z) then
                    UIDropDownMenu_SetSelectedID(dd2, i);
                    UIDropDownMenu_SetText(dd2, Yatlas_areadb[z]);
                    break;
                end
            end
        end
    end
end

function YatlasFrameTemplate:UpdateDropDown2()
    local framename = self:GetName();
    local vfname = framename.."ViewFrame";
    local vf = _G[vfname];
    local zoom = self.opt.Zoom;
    local dd2 = _G[framename.."DropDown2"];
--print(tostring(framename).." "..tostring(vfname).." "..tostring(zoom).." "..tostring(dd2))
    if(dd2 and self.zonepulldowns) then
        -- FIXME this isn't quite right somehow!! (besides height/width being flipped)
        local zid = self:GetZoneIDs((vf:GetHeight()/zoom/2),(vf:GetWidth()/zoom/2));
        for i,v in ipairs(self.zonepulldowns) do
	--print(tostring(v).." "..tostring(vid))
            if(v == zid) then
                UIDropDownMenu_SetSelectedID(dd2, i);
                UIDropDownMenu_SetText(dd2,Yatlas_areadb[zid]);
                break;
            end
        end
    end
end

--

function YatlasFramePlayerJumpButton_Toggle(btn)
    local f = btn:GetParent();
    local o = f.opt;
    if(o.track) then
        o.track = nil;
    else
        o.track = "player";
        YatlasFramePlayerJumpButton_Seek(f, "player");
    end

    YatlasFramePlayerJumpButton_Update(btn)
end

function YatlasFramePlayerJumpButton_Jump(btn)
    local f = btn:GetParent();
    local o = f.opt;
    
    o.track = nil;
    YatlasFramePlayerJumpButton_Seek(f, "player");
    
    YatlasFramePlayerJumpButton_Update(btn)
end

function YatlasFramePlayerJumpButton_Seek(frame, unit)
    frame.trackseek = unit;
    frame:OnWorldMapUpdateU(unit);
end

function YatlasFramePlayerJumpButton_Update(btn)
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

function YatlasFrameTemplate:GetMap()
    return self.opt.Map;
end

function YatlasFrameTemplate:SetZoom(z, nocenter)
    local textureno = 1;
    local lm = self:GetName();
    local vf = _G[lm.."ViewFrame"];

    self.wzoom = math.floor(vf:GetWidth()/z)+1;
    self.hzoom = math.floor(vf:GetHeight()/z)+1;
    self.wzoom_real = math.ceil(vf:GetWidth()/z)+1;
    self.hzoom_real = math.ceil(vf:GetHeight()/z)+1;

    if(_G[lm.."MapTexture"..(self.wzoom_real*self.hzoom_real)] == nil) then
        return self:SetZoom(z+4);
    elseif(z > vf:GetHeight() or z > vf:GetWidth()) then
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

function YatlasFrameTemplate:GetZoom()
    return self.opt and self.opt.Zoom or 256;
end

function YatlasFrameTemplate:SetLocation(x,y,forceupdate)
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

    if(zx ~= math.floor(self.opt.Location[1]) or forceupdate or
        zy ~= math.floor(self.opt.Location[2]) or mymap ~= self.lastmap) then
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
                -- (see Yatlas_GetLiveZoneNameForBigCoord), which skips
                -- Cataclysm-only terrain that doesn't exist on this client
                -- without needing a hand-maintained tile table at all.
                local col, row = zx+hx-1, zy+hy-1;
                local tilekey = format("%.2dx%.2d", col, row);
                local cbx, cby = Yatlas_Mini2Big_Coord(col+0.5, row+0.5);
                local livezone = Yatlas_GetLiveZoneNameForBigCoord(mymap, cbx, cby, tilekey);

                if(livezone) then
                    v[hx][hy] = { format("map%.2d_%.2d", col, row) };
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
                if(Yatlas_DebugTiles) then
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
            ya_raw_setoff(texturelayout[w][h],vfname,px,py);
        end
    end

    -- Upper left corner
    texturelayout[1][1]:SetTexCoord( (x-zx), 1, (y-zy), 1);
    texturelayout[1][1]:SetHeight( zoom-py);
    texturelayout[1][1]:SetWidth( zoom-px);
    ya_raw_setoff(texturelayout[1][1],vfname,0,0);

    -- Upper right corner
    if(px ~= 0 or wzoom ~= wzoom_real) then
        texturelayout[wzoom][1]:Show();
        texturelayout[wzoom][1]:SetTexCoord( 0, rightw/zoom, (y-zy), 1);
        texturelayout[wzoom][1]:SetHeight( zoom-py);
        texturelayout[wzoom][1]:SetWidth(rightw);
        ya_raw_setoff(texturelayout[wzoom][1],vfname,px,0);
    else
        texturelayout[wzoom][1]:Hide();
    end

    -- Lower left corner
    if(py ~= 0  or wzoom ~= wzoom_real) then
        texturelayout[1][hzoom]:Show();
        texturelayout[1][hzoom]:SetTexCoord( (x-zx), 1, 0, bottomh/zoom);
        texturelayout[1][hzoom]:SetWidth( zoom-px);
        texturelayout[1][hzoom]:SetHeight(bottomh);
        ya_raw_setoff(texturelayout[1][hzoom],vfname,0,py);
    else
        texturelayout[1][hzoom]:Hide();
    end

    -- lower right corner
    if((py ~= 0 and px ~= 0) or wzoom ~= wzoom_real) then
        texturelayout[wzoom][hzoom]:Show();
        texturelayout[wzoom][hzoom]:SetTexCoord( 0, rightw/zoom, 0, bottomh/zoom);
        texturelayout[wzoom][hzoom]:SetHeight(bottomh);
        texturelayout[wzoom][hzoom]:SetWidth(rightw);
        ya_raw_setoff(texturelayout[wzoom][hzoom],vfname,px,py);
    else
        texturelayout[wzoom][hzoom]:Hide();
    end

    -- top line
    for h = 2,wzoom-1 do
        texturelayout[h][1]:SetTexCoord( 0, 1, (y-zy), 1);
        texturelayout[h][1]:SetHeight( zoom-py);
        ya_raw_setoff(texturelayout[h][1],vfname,px,0);
    end

    -- bottom line
    if(py ~= 0 or wzoom ~= wzoom_real) then
        for h = 2,wzoom-1 do
            texturelayout[h][hzoom]:Show();
            texturelayout[h][hzoom]:SetTexCoord( 0, 1, 0, bottomh/zoom);
            texturelayout[h][hzoom]:SetHeight(bottomh);
            ya_raw_setoff(texturelayout[h][hzoom],vfname, px,py);
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
        ya_raw_setoff(texturelayout[1][h],vfname,0,py);
    end

    -- right line
    if(px ~= 0 or wzoom ~= wzoom_real) then
        for h = 2,hzoom-1 do
            texturelayout[wzoom][h]:Show();
            texturelayout[wzoom][h]:SetTexCoord( 0, rightw/zoom, 0, 1);
            texturelayout[wzoom][h]:SetWidth(rightw);
            ya_raw_setoff(texturelayout[wzoom][h],vfname,px,py);
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

        if(needbottom_extra) then
            bottomh = (old_bottomh-zoom);

            for h = 1,wzoom_real-1 do
                texturelayout[h][hzoom_real]:SetHeight(bottomh);
                if(h == 1) then
                    texturelayout[h][hzoom_real]:SetTexCoord( (x-zx), 1, 0, bottomh/zoom);
                    texturelayout[h][hzoom_real]:SetWidth(zoom-px);
                    ya_raw_setoff(texturelayout[h][hzoom_real],vfname,0,py);
                elseif(not needright_extra and h == wzoom_real-1) then
                    texturelayout[h][hzoom_real]:SetWidth(rightw);
                    texturelayout[h][hzoom_real]:SetTexCoord( 0, rightw/zoom, 0, bottomh/zoom);
                    ya_raw_setoff(texturelayout[h][hzoom_real],vfname,px,py);                    
                else
                    texturelayout[h][hzoom_real]:SetWidth(zoom);
                    texturelayout[h][hzoom_real]:SetTexCoord( 0, 1, 0, bottomh/zoom);
                    ya_raw_setoff(texturelayout[h][hzoom_real],vfname,px,py);
                end
                texturelayout[h][hzoom_real]:Show();
            end
            
        else
            for h = 1,wzoom_real-1 do
                texturelayout[h][hzoom_real]:Hide();
            end
        end

        if(needright_extra) then
            for h = 1,hzoom_real do
                texturelayout[wzoom_real][h]:SetWidth(rightw);
                texturelayout[wzoom_real][h]:Show();
                if(h == 1) then
                    texturelayout[wzoom_real][h]:SetTexCoord( 0, rightw/zoom, (y-zy), 1);
                    texturelayout[wzoom_real][h]:SetHeight(zoom-py);
                    ya_raw_setoff(texturelayout[wzoom_real][h],vfname,px,0);
                elseif(not needbottom_extra and h == hzoom_real-1) then
                    texturelayout[wzoom_real][h]:SetHeight(bottomh);
                    texturelayout[wzoom_real][h]:SetTexCoord( 0, rightw/zoom, 0, bottomh/zoom);
                    ya_raw_setoff(texturelayout[wzoom_real][h],vfname,px,py);    
                elseif(h == hzoom_real) then
                    if(needbottom_extra) then
                        texturelayout[wzoom_real][h]:SetHeight(bottomh);
                        texturelayout[wzoom_real][h]:SetTexCoord( 0, rightw/zoom, 0, bottomh/zoom);
                        ya_raw_setoff(texturelayout[wzoom_real][h],vfname,px,py);
                    else
                        texturelayout[wzoom_real][h]:Hide();
                    end
                else
                    texturelayout[wzoom_real][h]:SetHeight(zoom);
                    texturelayout[wzoom_real][h]:SetTexCoord( 0, rightw/zoom, 0, 1);
                    ya_raw_setoff(texturelayout[wzoom_real][h],vfname,px,py);
                end
                
            end
        else
            for h = 1,hzoom_real do
                texturelayout[wzoom_real][h]:Hide();
            end
        end

    end

    -- set zone text
    if(not vf.dragme) then
        self:UpdateDropDown2();
    end

    self.opt.Location[1] = x;
    self.opt.Location[2] = y;

    YAPoints_OnMove(self, x,y);
end

function YatlasFrameTemplate:GetLocation()
    local fm = self:GetName();

    return self.opt.Location[1],
        self.opt.Location[2];
end

function YatlasFrameTemplate:AdjustLocation(dx,dy,forceupdate)
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

function YatlasFrameTemplate:GetZoneText(offx, offy)
    -- untested?
    local f = {YF_GetZoneIDs(offx, offy)};

    if(#f < 1) then
        return YATLAS_UNKNOWN_ZONE;
    end

    local r = {};
    for h,v in pairs(f) do
        r[h] = Yatlas_areadb[v];
    end

    return unpack(r);
end

function YatlasFrameTemplate:GetZoneIDs(offx, offy)
    local fm = self:GetName();
    local x, y = unpack(self.opt.Location);
    local zoom = self:GetZoom();
    local viewframe = _G[fm.."ViewFrame"];

    local cx = x+(viewframe:GetWidth()/2)/zoom
    local cy = y+(viewframe:GetHeight()/2)/zoom

    local cbx, cby = Yatlas_Mini2Big_Coord(cx, cy)

    -- TODO: this isn't very accurate
    local maparea = Yatlas_mapareas[self.opt.Map];
    for h,k in pairs(maparea) do
        if(h ~= 0 and cbx < k[1] and cbx > k[2] and cby < k[3] and cby > k[4])then
            return h
        end
    end
end

function YatlasFrameTemplate:OnWorldMapUpdate()
    if(self.trackseek or (self.opt and self.opt.track)) then
        self:OnWorldMapUpdateU(self.trackseek or self.opt.track)
    end
end

-- One-time landmark scrape for all 4 known continents. Doesn't need the
-- WorldMapFrame to be shown/navigated (unlike the old GetNumMapLandmarks
-- API, which only reported landmarks for whatever page WorldMapFrame had
-- open at the time).
function Yatlas_ScrapeLandmarks()
    for mapname, uiMapID in pairs(Yatlas_ContinentMapID) do
        if(Yatlas_Landmarks[mapname] == nil and Yatlas_mapareas[mapname]) then
            local x1,x2,y1,y2;
            if(Yatlas_mapareas[mapname][0] ~= nil) then
                x1 = Yatlas_mapareas[mapname][0][1];
                x2 = Yatlas_mapareas[mapname][0][2];
                y1 = Yatlas_mapareas[mapname][0][3];
                y2 = Yatlas_mapareas[mapname][0][4];
            else
                local _,va = next(Yatlas_mapareas[mapname]);
                x1 = va[1];
                x2 = va[2];
                y1 = va[3];
                y2 = va[4];
            end

            Yatlas_Landmarks[mapname] = {};

            local pois = C_AreaPoiInfo.GetAreaPOIForMap(uiMapID);
            if(pois) then
                for _, poiID in ipairs(pois) do
                    local info = C_AreaPoiInfo.GetAreaPOIInfo(uiMapID, poiID);
                    if(info and info.position) then
                        local px, py = info.position:GetXY();
                        local x = (-px*(x1-x2) + x1);
                        local y = (-py*(y1-y2) + y1);
                        tinsert(Yatlas_Landmarks[mapname],
                                {x, y, info.name, info.description, info.atlasName});
                    end
                end
            end
        end
    end

    YAPoints_ForceUpdate();
end

function YatlasFrameTemplate:OnWorldMapUpdateU(u)
    local map, x, y = Yatlas_GetUnitContinentPosition(u);
    local lm = self:GetName();
    local viewframe = _G[lm.."ViewFrame"];
    local zoom = self.opt.Zoom

    if(map == nil or Yatlas_mapareas[map] == nil) then
        return;
    end

    local x1,x2,y1,y2;
    if(Yatlas_mapareas[map][0] ~= nil) then
        x1 = Yatlas_mapareas[map][0][1];
        x2 = Yatlas_mapareas[map][0][2];
        y1 = Yatlas_mapareas[map][0][3];
        y2 = Yatlas_mapareas[map][0][4];
    else
        local _,va = next(Yatlas_mapareas[map]);  
        x1 = va[1];
        x2 = va[2];
        y1 = va[3];
        y2 = va[4];
    end

    local unitx, unity = (-x*(x1-x2) + x1), (-y*(y1-y2) + y1);

    if(u == self.trackseek) then
        local zx,zy = Yatlas_Big2Mini_Coord(unitx, unity);

        self:SetMap(map);
        self:SetLocation(zx-(viewframe:GetWidth()/2)/zoom,
                    zy-(viewframe:GetHeight()/2)/zoom);

        self.trackseek = nil;
    elseif(u == self.opt.track) then
        local rx,ry = self:GetLocation();
        local zx,zy = Yatlas_Big2Mini_Coord(unitx, unity);
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

function ya_raw_setoff(texture, parent, px, py) 
    local zoom = _G[parent]:GetParent().opt.Zoom
    texture:ClearAllPoints();
    texture:SetPoint("TOPLEFT", parent,
            "TOPLEFT", (zoom)*(texture.hx-1) - px,
            -(zoom)*(texture.hy-1) + py);
end

ya_lastdragx, ya_lastdragy = nil, nil;
function YatlasFrameViewFrame_OnDrag(self)
    local x,y = GetCursorPosition();
    local fx, fy;
    local zoom = self:GetParent().opt.Zoom;

    x = x / self:GetEffectiveScale();
    y = y / self:GetEffectiveScale();

    fx = math.floor(x - self:GetLeft())/(zoom);
    fy = math.floor(y - self:GetBottom())/(zoom);
    if(ya_lastdragx ~= nil) then
        self:GetParent():AdjustLocation(ya_lastdragx - fx, ya_lastdragy - fy);
    end

    ya_lastdragx = fx;
    ya_lastdragy = fy;
end

function YatlasFrameViewFrame_UpdateCursorCoord(self)
    local x, y = GetCursorPosition();
    local rx, ry = unpack(YatlasFrame.opt.Location);
    local top = self:GetTop();
    local zoom = YatlasFrame.opt.Zoom;
    
    if(self.lastoux == x and self.lastouy == y) then
        return;
    end
    self.lastoux = x;
    self.lastouy = y;

    x = x / self:GetEffectiveScale();
    y = y / self:GetEffectiveScale();

    rx = rx + math.floor(x - self:GetLeft())/zoom;
    ry = ry + 512/zoom-math.floor(y - self:GetBottom())/zoom;
    local bigx, bigy = Yatlas_Mini2Big_Coord(rx,ry);
end

function YatlasFrameTemplate:OnUpdate(elapsed)
    self.update_time = self.update_time + elapsed;

    if(self.update_time > 0.5) then
       YAPoints_OnUpdate(self, self.update_time);
       self:OnWorldMapUpdate();
       self.update_time = 0;
   end
end

function Yatlas_Mini2Big_Coord(x,y)
    return (x - 32)*-MINI2BIGX,(y-32)*-MINI2BIGY;
end

function Yatlas_Big2Mini_Coord(x,y)
    return (x/-MINI2BIGX + 32),(y/-MINI2BIGY + 32);
end

-- YatlasOptionsFrame

function YatlasOptionsFrameSelect_Initialize() 
    local i = 1;
    local info;
    for h,v in pairs(YatlasOptions.Frames) do
            info = {
                    text = h;
                    func = YatlasOptionsFrameSelect_OnClick;
                    value = _G[h];
            };
            UIDropDownMenu_AddButton(info);
            if(i == 1 and YatlasOptionsFrameSelect.currFrame == nil) then
                YatlasOptionsFrameSelect.currFrame = _G[h];
            end
            i = i + 1;
    end
end

function YatlasOptionsFrameSelect_OnClick(self) 
    UIDropDownMenu_SetSelectedID(YatlasOptionsFrameSelect, self:GetID());
    YatlasOptionsFrameSelect.currFrame = self.value;
    YatlasOptionsFrame_Update();
end

function YatlasOptionsFrame_Update()
    local frame = YatlasOptionsFrameSelect.currFrame;
    if(frame) then
        local lm = frame:GetName();
        local opt = YatlasOptions.Frames[lm];

        YatlasOptionsAlphaSlider:SetValue(opt.Alpha);
        YatlasOptionsIconSizeSlider:SetValue(opt.IconSize);
    end
end

-- YatlasTooltip
YatlasTooltipTemplate = {};

function YatlasTooltipTemplate:OnLoad()
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

function YatlasTooltipTemplate:Show()
    local r = getmetatable(self).__index.Show(self);
    self:FixSize();
    return r;
end

function YatlasTooltipTemplate:GetNext()
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

function YatlasTooltipTemplate:FixSize() 
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


function YatlasTooltipTemplate:Clear() 
    for h = 1,(self.nextfree-1) do
        self.lines[h]:Hide();
    end
    self.nextfree = 1;
    self:FixSize();
    self:Hide();
end


function YatlasOptions_Toggle()
	if(YatlasOptionsFrame:IsShown()) then
		YatlasOptionsFrame:Hide()
	else
		YatlasOptionsFrame:Show();
	end
end