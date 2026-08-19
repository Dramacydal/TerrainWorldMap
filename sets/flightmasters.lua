
local set = {name="flightmasters"};

-- Flight master markers, generated (see scripts/gen_poi_flightmasters.js)
-- into Data_<Flavor>/mapdata_poi_flightmasters.lua. Entries are
-- {id, faction, name = {enUS = ..., deDE = ..., ...}, x, y} -- name is
-- resolved to the client's own locale via TWM_ResolveFlightMasterName
-- (TaxiRoutes.lua), since a flight master has no AreaID/MapID of its own to
-- resolve a live name from at render time the way Landmarks/Capitals/
-- Dungeons do. Enemy-faction markers are skipped entirely here (not just
-- hidden) unless "Show enemy faction Flight masters" is on, same
-- neutral-is-always-shown rule as the real in-game flight map.
function set.getpoints(name, map)
    if(type(Twm_flightmasters[map]) ~= "table") then return; end

    for h,v in ipairs(Twm_flightmasters[map]) do
        if(TWM_IsFlightmasterVisible(v.faction)) then
            local x,y = TWM_Big2Mini_Coord(v.x, v.y);
            TWMPoints_AddPoint(nil, "flightmasters", TWM_ResolveFlightMasterName(v.name), x, y, nil, {v.id, v.faction});
        end
    end
end

function set.setuppoint(point, env, dat)
    local text, bg = point.Foreground, point.Icon;
    local iconsize = env.iconsize;
    local faction = dat.userdat[2];

    point:Show();
    point:SetOffset(dat.x, dat.y);
    text:SetText("");

    -- Always draw above every other marker type -- pooled icon frames
    -- otherwise all share the same baseline level (TWMPoints_GetPoint/
    -- TWMPoints_AllocMobilePoint), so which type ends up "on top" is
    -- otherwise just whatever order Lua happened to iterate the sets in.
    -- TWMP_Clear (Points.lua) resets this back to that baseline before a
    -- recycled frame is handed to any other set, so this doesn't stick once
    -- the frame stops being a flight master.
    point:SetFrameLevel(point:GetParent():GetFrameLevel() + 8);

    bg:Show();
    bg:SetHeight(iconsize);
    bg:SetWidth(iconsize);
    bg:SetTexture("Interface\\AddOns\\TerrainWorldMap\\images\\Icons\\Icon-Taxi-" .. faction, nil, nil, "NEAREST");
    bg:SetTexCoord(0, 1, 0, 1);
    bg:SetVertexColor(1, 1, 1, 1);
end

function set.setuplegend(point, env, dat)
    env.iconsize = 16;
    set.setuppoint(point, env, dat);

    point.Text:SetText(dat.name);
end

function set.configmenu(name, lm)
    if(UIDROPDOWNMENU_MENU_LEVEL == 1) then
        local info = {};
        info.text = TWM_POINTS_FLIGHTMASTERS;
        info.func = TWMFOODropDown_do_toggle_normal;
        info.checked = TWMOption.Frames[lm].PointCfg and not TWMOption.Frames[lm].PointCfg[name];
        info.value = name;
        info.keepShownOnClick = 1;
        UIDropDownMenu_AddButton(info);
    end
end

TWMPoints_RegisterSet(set);
