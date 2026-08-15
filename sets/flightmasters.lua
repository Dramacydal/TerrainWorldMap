
local set = {name="flightmasters"};

-- Flight master markers, generated (see scripts/gen_poi_flightmasters.js)
-- into Data_<Flavor>/mapdata_poi_flightmasters.lua. Entries are
-- {TaxiNodeID, "Alliance"|"Horde"|"Neutral", Name, x, y}. Enemy-faction
-- markers are skipped entirely here (not just hidden) unless "Show enemy
-- faction Flight masters" is on, same neutral-is-always-shown rule as the
-- real in-game flight map.
function set.getpoints(name, map)
    if(type(Twm_flightmasters[map]) ~= "table") then return; end

    for h,v in ipairs(Twm_flightmasters[map]) do
        local nodeID, faction = v[1], v[2];
        if(TWM_IsFlightmasterVisible(faction)) then
            local x,y = TWM_Big2Mini_Coord(v[4], v[5]);
            TWMPoints_AddPoint(nil, "flightmasters", v[3], x, y, nil, {nodeID, faction});
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
