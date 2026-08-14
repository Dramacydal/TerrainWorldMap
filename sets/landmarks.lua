
local landmarkalthamlet = {nil,nil,nil,nil,-4};

local set = {name="landmarks"};

function set.getpoints(name, map)
    -- Sub-area/POI labels, generated from AreaTable's own zone hierarchy
    -- (see scripts/gen_poi_areas.js). Entries are {AreaID, Name, x, y} --
    -- Name is only a fallback for a build where the AreaID no longer
    -- resolves; Twm_areadb (mapdata_zones.lua) resolves it live via
    -- C_Map.GetAreaInfo so the label always matches the client's own
    -- current locale instead of whatever locale this data was generated in.
    if(type(Twm_poi_areas[map]) == "table") then
        for h,v in ipairs(Twm_poi_areas[map]) do
            local x,y = TWM_Big2Mini_Coord(v[3],v[4]);

            TWMPoints_AddPoint(nil, "landmarks", Twm_areadb[v[1]] or v[2], x, y, nil, landmarkalthamlet);
        end
    end
end

function set.setuppoint(point, env, dat)
    local text, bg = point.Foreground, point.Icon;
    local iconsize = env.iconsize;
    local kind = dat.userdat[5];

    local r, g, b = 0.2, 0.6, 1;
    local bgtextname = "Interface\\AddOns\\TerrainWorldMap\\images\\Icons\\Icon-Circle";

    if(kind == -4) then
        r, g, b = 0.3, 0.8, 1;
        bgtextname = "Interface\\AddOns\\TerrainWorldMap\\images\\Icons\\Icon-Exclaim";
    end

    point:Show();
    point:SetOffset(dat.x, dat.y);
    text:SetText("");

    bg:Show();
    bg:SetHeight(iconsize);
    bg:SetWidth(iconsize);
    bg:SetTexture(bgtextname, nil, nil, "NEAREST");
    bg:SetTexCoord(0, 1, 0, 1);
    bg:SetVertexColor(r, g, b, 1);
end

function set.setuplegend(point, env, dat)
    env.iconsize = 16;
    set.setuppoint(point, env, dat);

    point.Text:SetText(dat.name);
end

function set.configmenu(name, lm)
    if(UIDROPDOWNMENU_MENU_LEVEL == 1) then
        local info = {};
        info.text = TWM_POINTS_LANDMARKS;
        info.func = YFOODropDown_do_toggle_normal;
        info.checked = TWMOption.Frames[lm].PointCfg and not TWMOption.Frames[lm].PointCfg[name];
        info.value = name;
        info.keepShownOnClick = 1;
        UIDropDownMenu_AddButton(info);
    end
end

TWMPoints_RegisterSet(set);
