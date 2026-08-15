
local sets = {};
local frames = {};

-- state function
local current_locx_xact, current_locy_xact;
local current_frame, current_viewframe;
local binsert;

local nilfunc = function () end
local emptylist = {};

-- default on-map icon size in pixels at the IconSize option's neutral value (1.0)
local TWM_ICON_BASE_SIZE = 14;

function TWM_GetIconSize(lm)
    return TWM_ICON_BASE_SIZE * (TWMOption.Frames[lm].IconSize or 1);
end

function TWMPoints_RegisterSet(set)
    sets[set.name] = set;
end

function TWMPoints_RegisterFrame(a)
    frames[a] = 0;
end

function TWMPoints_ForceUpdate(frame)
    if( not frame) then
        for h,v in pairs(frames) do
            TWMPoints_OnMapChange(_G[h]);
        end
    else
        TWMPoints_OnMapChange(frame);
    end
end

function TWMPoints_OnMapChange(frame)
    local lm = frame:GetName();

    -- clear all points
    local h = 1;
    while h > 0 do
        local point = _G[lm.."Point"..h];
        if(point) then
            point:Clear();
            h = h + 1;
        else
            h = 0;
        end
    end

    local pd_resetlist = _G[frame.TWM_PD_ResetList];
    if(pd_resetlist) then pd_resetlist(); end

    -- store all points for this map
    frame.points = {};
    current_frame = frame;
    for h,v in pairs(sets) do
        if(v.getpoints) then
            v.getpoints(h, TWMOption.Frames[lm].Map);
        end
    end

    -- handle mobile points here to.
    -- Keep in mind, mobile points shouldn't be updated here specifically,
    -- but it gets the job done.
    frame.mobilepoints = {};
    frame.nextmobilepoint = 1;
    if(frame.mobilepointframes == nil) then frame.mobilepointframes = {} end
    for h,v in pairs(sets) do
        if(v.getmobilepoints) then
            v.getmobilepoints(h);
        end
    end

    -- Hide mobile points left over on a different map (e.g. a raid member
    -- who isn't on the map currently being shown) -- comparing against the
    -- map actually being displayed, not the point's own last-known map.
    for id,mp in pairs(frame.mobilepoints) do
        if(mp.locmap ~= TWMOption.Frames[lm].Map) then
            mp:Hide();
        end
    end

    -- force update
    frame.yap_lastx = nil;
    TWMPoints_OnMove(frame, unpack(TWMOption.Frames[lm].Location));
end

function TWMPoints_OnMove(frame, x, y, forceupdate)
    local lm = frame:GetName();

    if(frames[lm] == 0) then
        frames[lm] = 1;
        return TWMPoints_OnMapChange(frame);
    end

    -- if we have run at this x, y coord recently, don't do it again --
    -- unless forceupdate is set (e.g. a window resize: the map center (x,y)
    -- doesn't change, but the viewport's own pixel size did, which changes
    -- which points actually fall inside it -- see TWMPoints_Update's own
    -- viewport-bounds culling).
    if(not forceupdate and frame.yap_lastx == x and frame.yap_lasty == y) then
        -- no change
        return;
    end

    -- update normal points and unit points
    TWMPoints_Update(frame, x, y);
--    TWMPoints_UpdateP(frame);

    -- hide/update mobile points as needed
    for id,mp in pairs(frame.mobilepoints) do
        if(mp:IsShown()) then
            mp:Update(frame);
        end
    end

    frame.yap_lasty = y;
    frame.yap_lastx = x;
end

function TWMPoints_OnUpdate(frame, ela) 
    local lm = frame:GetName();

    for h,v in pairs(sets) do
        if(v.OnUpdate) then
            v.OnUpdate(h, frame, ela);
        end
    end
end

function TWMPoints_Update(frame, x, y)
    local lm = frame:GetName();
    local flr,cei=math.floor,math.ceil;
    local z = frame:GetZoom();
    local hpoint = 1;
    local legend = {};
    
    if(x == nil) then
        x = TWMOption.Frames[lm].Location[1];
        y = TWMOption.Frames[lm].Location[2];
    end
    current_locx_xact = x;
    current_locy_xact = y;

    current_frame = frame;
    current_viewframe = _G[lm.."ViewFrame"];

    -- ensure that we have loaded the points already
    if(frame.points == nil) then
        return TWMPoints_OnMapChange(frame);
    end

    -- clear all points
    for h, point in ipairs(frame.pointframes) do
        if(point and point:IsShown()) then
            point:Clear();
        end
    end

    -- init vispoints
    frame.vispoints = {};
    for h,v in pairs(sets) do
        frame.vispoints[h] = {};
    end

    -- fill vispoints
    for xv = flr(x),cei(x+current_viewframe:GetWidth()/z),1 do
        if(frame.points[xv] ~= nil) then 
            for yv = flr(y),cei(y+current_viewframe:GetHeight()/z),1 do
                if(frame.points[xv][yv] ~= nil) then
                    for k,vv in pairs(frame.points[xv][yv]) do
                        if(vv.x > x and vv.y > y and
                                vv.x < x+current_viewframe:GetWidth()/z and 
                                vv.y < y+current_viewframe:GetHeight()/z) then
                            binsert(frame.vispoints[vv.setname], vv);
                        end
                    end
                end
            end
        end
    end

    local env = {
        current_lm = lm,
        current_frame = current_frame,
        zoom = z,
        iconsize = TWM_GetIconSize(lm)
    };

    -- draw visible points
    frame._common_pd = {};
    local id = 1;
    for hset,set in pairs(frame.vispoints) do
        local showornotfunc = sets[hset].showme;
        local pointfunc = sets[hset].setuppoint;
        local legendfunc = sets[hset].setuplegend;

        for hval,val in pairs(set) do
            local point = TWMPoints_GetPoint(frame, hpoint);
            local showmemaybe = 
                (not showornotfunc and not TWMOption.Frames[lm].PointCfg[val.setsubname]) or
                (showornotfunc and showornotfunc(val, lm) );
            

            if(point and showmemaybe) then

                if(not val.options.commonpd) then
                    val.id = id;
                    id = id + 1;
                end

                point:Clear();
                point:Show();

                -- this gets changed around a lot
                env.iconsize = TWM_GetIconSize(lm);

                -- point's own hit-test area must track the icon size too --
                -- it's created at a fixed 16x16 (see TWMPoints_GetPoint) and
                -- each set's setuppoint only resizes the child Icon texture,
                -- so a bigger-than-default icon size left the mouseover/
                -- tooltip area stuck at the icon's original top-left corner.
                point:SetWidth(env.iconsize);
                point:SetHeight(env.iconsize);

                -- call functions
                point.dat = val;
                if(pointfunc) then
                    pointfunc(point, env, val);
                end
            elseif(point) then
                hpoint = hpoint-1;
            end

            hpoint = hpoint + 1;
        end
    end

    -- Optional hook (FlightPaths.lua) -- not every build/config has it, so
    -- only call if it's actually loaded.
    if(TWM_FlightPaths_OnPointsUpdate) then
        TWM_FlightPaths_OnPointsUpdate(frame, x, y);
    end
end

-- Exposes TWMPoints_Update's last-known (frame, viewport-topleft-x,
-- viewport-topleft-y) so FlightPaths.lua can redraw just the flight-path
-- lines (e.g. on hover start/stop) without forcing a full point recompute.
function TWMPoints_GetCurrentView()
    return current_frame, current_locx_xact, current_locy_xact;
end

function TWMPoints_GetPoint(frame, id)
    -- does point exist??
    if(frame.pointframes[id]) then
        return frame.pointframes[id];
    end

    if(id > 4096) then
        -- this is too big by far
        return;
    end

    -- create
    local viewframe = _G[frame:GetName().."ViewFrame"];
    local f = CreateFrame("Button");

    f:SetHeight(16);
    f:SetWidth(16);
    f:SetParent(viewframe);
    f:EnableMouse(true);
    TWMP_EnableDragThrough(f, viewframe);

    f.Icon = f:CreateTexture(nil, "OVERLAY");
    f.Icon:SetPoint("TOPLEFT", f);

    f.Foreground = f:CreateFontString(nil, "ARTWORK");
    f.Foreground:SetFontObject(GameFontHighlight);
    f.Foreground:SetTextColor(0, 0, 0);
    f.Foreground:SetShadowOffset(-1, 0);
    f.Foreground:SetPoint("TOPLEFT", f);

    f:SetFrameLevel(f:GetFrameLevel() + 4);
    f.Clear = TWMP_Clear;
    f.SetOffset = TWMP_SetOffset;

    f:SetScript("OnEnter", TWMP_OnEnter);

    frame.pointframes[id] = f;
    return f;
end

function TWMPoints_AllocMobilePoint(frame, id)
    -- does point exist??
    if(frame.mobilepointframes[id]) then
        return frame.mobilepointframes[id];
    end

    if(id > 1024) then
        -- this is too big by far
        return;
    end

    -- create
    local viewframe = _G[frame:GetName().."ViewFrame"];
    local f = CreateFrame("Button");

    f:SetHeight(16);
    f:SetWidth(16);
    f:SetParent(viewframe);
    f:EnableMouse(true);
    TWMP_EnableDragThrough(f, viewframe);

    f.Icon = f:CreateTexture(nil, "OVERLAY");
    f.Icon:SetPoint("TOPLEFT", f);

    f.Foreground = f:CreateFontString(nil, "ARTWORK");
    f.Foreground:SetFontObject(GameFontHighlight);
    f.Foreground:SetTextColor(0, 0, 0);
    f.Foreground:SetShadowOffset(-1, 0);
    f.Foreground:SetPoint("TOPLEFT", f);

    f:SetFrameLevel(f:GetFrameLevel() + 4);
    f.Clear = TWMP_Clear;
    f.SetOffset = TWMP_SetOffset;
    f.Update = TWMMP_Update;

    f:SetScript("OnEnter", TWMP_OnEnter);

    frame.mobilepointframes[id] = f;
    return f;
end

function TWMPoints_UpdateTooltip(frame, tooltip, point, op) 
    local dat = point.dat;
    local lm = frame:GetName();

    if(not tooltip.points) then
        tooltip.points = {};
    end

    if(op == "add") then
        if(point.intooltip == nil) then
            tinsert(tooltip.points, point);

            point.intooltip = 1;
        end
    elseif(op == "remove") then
        for h,v in ipairs(tooltip.points) do
            if(v == point) then
                tremove(tooltip.points, h);
                break;
            end
        end

        point.intooltip = nil;
    else
        -- ???
    end

    local env = {
        current_lm = lm,
        current_frame = frame,
        zoom = frame:GetZoom(),
 	iconsize = 14,
        islegend = true,
    };

    if(tooltip.points[1]) then
        local vf = _G[lm.."ViewFrame"];
        tooltip:Clear();
        for h,point in ipairs(tooltip.points) do
            local legendfunc = sets[point.dat.setname].setuplegend;
            if(legendfunc) then
                local legend = tooltip:GetNext();
                legendfunc(legend, env, point.dat);
            end
            -- tooltip:AddDataPoint(point.dat.name);
        end
        tooltip:Show();
    else
        tooltip:Hide();
    end
end

function TWMPoints_showmeornot(frame, val)
    local showornotfunc = sets[val.setname].showme;

    if(type(frame) ~= "string") then
        frame = frame:GetName();
    end

    return
        (not showornotfunc and not TWMOption.Frames[frame].PointCfg[val.setsubname]) or
         (showornotfunc and showornotfunc(val, frame) );
end

---
--- point OO implementation
---

-- Point icons are mouse-enabled Buttons (needed for TWMP_OnEnter's hover
-- tooltip) sitting on top of the ViewFrame at a higher frame level -- so a
-- drag that starts with the cursor over an icon never reaches the
-- ViewFrame's own OnDragStart (TWMFrameViewTemplate in Templates.xml),
-- meaning the map silently failed to pan whenever a click-drag happened to
-- start on a marker.
--
-- Deliberately does NOT use RegisterForDrag/OnDragStart/OnDragStop on the
-- icon itself: point icons are pooled and get recycled (TWMP_Clear, which
-- calls :Hide()) for a different point mid-pan as the view moves -- and WoW
-- silently cancels an in-progress drag gesture the moment the frame that
-- started it gets hidden. That produced exactly the observed bug: one
-- pixel of movement (the first OnUpdate tick), then nothing for the rest of
-- the hold, because the icon got recycled out from under the still-held
-- gesture. Starting on plain OnMouseDown instead, with the stop condition
-- polled from the ViewFrame's own OnUpdate (see TWMFrameViewFrame_OnDrag)
-- rather than an OnDragStop tied to this specific icon, makes the drag's
-- lifetime independent of whether this icon frame still exists.
function TWMP_EnableDragThrough(point, viewframe)
    point:SetScript("OnMouseDown", function(self, button)
        if(button == "LeftButton" or button == "RightButton") then
            viewframe.dragme = true;
            twm_lastdragx = nil;
            twm_lastdragy = nil;
        end
    end);
end

function TWMP_Clear(point)
    point:Hide();
    point:ClearAllPoints();
    point:SetPoint("TOPLEFT", point:GetParent());
    point.Icon:SetTexture(nil);
    point.Icon:SetTexCoord(0, 1, 0, 1);
    point.Foreground:SetText("");
end

function TWMP_SetOffset(point, x, y) 
    local z = current_frame:GetZoom();
    local lm = current_frame:GetName();
    local iconsz = TWM_GetIconSize(lm);

    point:ClearAllPoints();
    point:SetPoint("TOPLEFT", current_viewframe, "TOPLEFT", 
           -(current_locx_xact - x)*z - iconsz/2,
           (current_locy_xact - y)*z + iconsz/2);
end

function TWMP_OnEnter(self)
    local vf = self:GetParent(); 
    local f = vf:GetParent();
    local tp = _G[f.hoverTooltip];
    
    vf.inpoint = true;
    if(tp and tp.knownshownlines == nil) then
        tp.knownshownlines = 0;
    end
    
end


function TWMFrameViewFrame_UpdatePointTooltip(self) 
    local f = self:GetParent();
    local tp = _G[f.hoverTooltip];

    for h,v in pairs(f.pointframes) do
        if(v.intooltip and not MouseIsOver(v)) then
            TWMPoints_UpdateTooltip(f, tp, v, "remove");
            tp.knownshownlines = tp.knownshownlines - 1;

            -- Hovering off a flight master's icon stops the hover-preview
            -- flight-path lines (see FlightPaths.lua) it was showing.
            if(v.dat and v.dat.setname == "flightmasters" and TWM_HoveredTaxiNodeID == v.dat.userdat[1]) then
                TWM_HoveredTaxiNodeID = nil;
                if(TWM_FlightPaths_Refresh) then TWM_FlightPaths_Refresh(); end
            end
        elseif(not v.intooltip and MouseIsOver(v)) then
            TWMPoints_UpdateTooltip(f, tp, v, "add");
            tp.knownshownlines = tp.knownshownlines + 1;

            -- Hovering a flight master's icon starts the hover-preview
            -- flight-path lines to its known neighbors (see FlightPaths.lua;
            -- no-op when "Toggle Flight Paths" already shows everything).
            if(v.dat and v.dat.setname == "flightmasters") then
                TWM_HoveredTaxiNodeID = v.dat.userdat[1];
                if(TWM_FlightPaths_Refresh) then TWM_FlightPaths_Refresh(); end
            end
        end
    end

    for h,v in pairs(f.mobilepointframes) do
        if(v.intooltip and not MouseIsOver(v)) then
            TWMPoints_UpdateTooltip(f, tp, v, "remove");
            tp.knownshownlines = tp.knownshownlines - 1;
        elseif(not v.intooltip and MouseIsOver(v) and v:IsShown()) then
            TWMPoints_UpdateTooltip(f, tp, v, "add");
            tp.knownshownlines = tp.knownshownlines + 1;
        end
    end

    if(tp.knownshownlines == 0) then
        self.inpoint = nil;
    else
        -- Follow the cursor like a standard tooltip, instead of the fixed
        -- bottom-right anchor set up in TerrainWorldMap.xml.
        local scale = UIParent:GetEffectiveScale();
        local cx, cy = GetCursorPosition();
        tp:ClearAllPoints();
        tp:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", cx/scale + 16, cy/scale - 16);
    end
end

---
---
---

function TWMPoints_AddPoint(frame, setname, name, x, y, options, userdat)
    local tab = {
        setname = setname,
        name = name,
        x = x, y = y,
        options = options,
        userdat = userdat
    };

    if(tab.options == nil) then
        tab.options = emptylist;
    end

    if(options and options.setsubname) then
        tab.setsubname = options.setsubname;
    else
        tab.setsubname = tab.setname;
    end

    if(type(frame) ~= "table") then
        frame = current_frame;
    end

    local fx = math.floor(x);
    local fy = math.floor(y);

    if(frame.points[fx] == nil) then frame.points[fx] = {}; end
    if(frame.points[fx][fy] == nil) then frame.points[fx][fy] = {}; end

    tinsert(frame.points[fx][fy], tab);
end

function TWMPoints_AddMobilePoint(frame, setname, name, opt, userdat) 
    local tab = {
        setname = setname,
        name = name,
        options = opt,
        userdat = userdat
    };

    if(tab.options == nil) then
        tab.options = emptylist;
    end

    if(options and options.setsubname) then
        tab.setsubname = options.setsubname;
    else
        tab.setsubname = tab.setname;
    end

    if(type(frame) ~= "table") then
        frame = current_frame;
    end

    point = TWMPoints_AllocMobilePoint(frame, frame.nextmobilepoint);
    point.dat = tab; 
    frame.nextmobilepoint = frame.nextmobilepoint + 1;

    frame.mobilepoints[setname..":"..name] = point;
    return #frame.mobilepoints;
end

function TWMPoints_Mobile_SetLocation(setname, name, map, x, y) 
    for framename,v in pairs(frames) do
        local frame = _G[framename];
        if(frame:IsVisible()) then
            local d = frame.mobilepoints[setname..":"..name];
            d.locx = x;
            d.locy = y;
            d.locmap = map;
            d:Update(frame);
        end
    end
end

function TWMPoints_SetupMobilePoint(setname, name, itahm, prop, ...)
    local whut;
    
    for framename,v in pairs(frames) do
        local frame = _G[framename];
        whut = frame.mobilepoints[setname..":"..name][itahm];
        whut[prop](whut, ...);
    end
end

function TWMPoints_SetupMobilePointF(frame, setname, name, itahm, prop, ...)
    local whut;

    if(type(frame) ~= "table") then
        frame = current_frame;
    end

    whut = frame.mobilepoints[setname..":"..name][itahm];
    whut[prop](whut, ...);
end

function TWMPoints_HideMobile(setname, name) 
    for framename,v in pairs(frames) do
        local frame = _G[framename];
        if(frame:IsVisible()) then
            local d = frame.mobilepoints[setname..":"..name];
            d.locmap = nil;
            d:Update(frame);
        end
    end
end

function TWMMP_Update(point, frame)
    local zoom = frame:GetZoom();
    local vf = _G[frame:GetName().."ViewFrame"]
    local map = frame:GetMap();
    local minx, miny = frame:GetLocation();
    local maxx, maxy = minx + vf:GetWidth()/zoom, miny + vf:GetHeight()/zoom;

    if(map == point.locmap and
            point.locx > minx and point.locx < maxx and
            point.locy > miny and point.locy < maxy) then
        local iconsz = TWM_GetIconSize(frame:GetName());
        point.Icon:SetWidth(iconsz);
        point.Icon:SetHeight(iconsz);
        -- point's own hit-test area must track the icon size too -- see the
        -- same fix/comment in TWMPoints_Update for the fixed-point case.
        point:SetWidth(iconsz);
        point:SetHeight(iconsz);
        point:SetOffset(point.locx, point.locy);
        point:Show();
    else
        point:Hide();
    end
end


---
--- TWMFOO: pulldown to control what points are shown.  name has some 
---       historical significance
---

function TWMFOO_Init(self, frame)
    if(not frame) then
        frame = self;
    end

    UIDropDownMenu_Initialize(frame, TWMFOODropDown_Initialize, "MENU");
    UIDropDownMenu_SetButtonWidth(frame,50);
    UIDropDownMenu_SetWidth(frame,50);
end

function TWMFOODropDown_Initialize()
    local func;

    if(current_frame == nil) then
        return;
    end

    local lm = current_frame:GetName();

    if(UIDROPDOWNMENU_MENU_LEVEL == 1) then
        local info = {};
        info.text = TWM_POINTS_SHOWPOINTS_TITLE;
        info.notClickable = 1;
        info.isTitle = 1;
        info.notCheckable = 1;
        UIDropDownMenu_AddButton(info);
    end

    if(TWMOption.Frames and TWMOption.Frames[lm]) then
        for h,v in pairs(sets) do
            func = v.configmenu;
            if(func) then
                func(h, lm);
            end
        end
    end
end

function TWMFOO_OnClick(self)
    current_frame = self;
    while(current_frame and not current_frame.SetLocation) do
        current_frame = current_frame:GetParent()
    end

    ToggleDropDownMenu(1, nil, _G[self:GetName().."DropDown"], self:GetName(), 0, 0);
end

function TWMFOODropDown_do_toggle_normal(self)
    -- PointCfg[name] means "hidden"; the checkbox means "shown", so invert.
    TWMOption.Frames[current_frame:GetName()].PointCfg[self.value] = not UIDropDownMenuButton_GetChecked(self)
    TWMPoints_ForceUpdate(current_frame)
end

---
--- misc
---

-- based on code by ???
binsert = function( t, val)
    local iStart, iEnd, iMid, iState =  1, #t, 1, 0

    -- Get Insertposition
    while iStart <= iEnd do
            
            -- calculate middle
            iMid = math.floor( ( iStart + iEnd )/2 )

            -- compare
            if val.name <= t[iMid].name then
                    iEnd = iMid - 1
                    iState = 0
            else
                    iStart = iMid + 1
                    iState = 1
            end
    end

    table.insert( t, ( iMid+iState ), val )
end
