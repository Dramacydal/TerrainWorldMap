
local set = {name="dungeons"};

function set.getpoints(name, map)
    -- Dungeon/raid entrance markers, generated (see scripts/gen_poi_instances.js)
    -- into Data_<Flavor>/mapdata_poi_instances.lua. Entries are
    -- {"Dungeon"|"Raid", MapID, Name, x, y} -- type doubles as the icon name
    -- (Icon-Dungeon / Icon-Raid). Name is only a fallback -- GetRealZoneText
    -- accepts the same MapID (confirmed: GetRealZoneText(530) == "Outland",
    -- Map.ID 530 = Expansion01) and returns the live, locale-correct name.
    if(type(Twm_instances[map]) == "table") then
        for h,v in ipairs(Twm_instances[map]) do
            local x,y = TWM_Big2Mini_Coord(v[4],v[5]);

            TWMPoints_AddPoint(nil, "dungeons", GetRealZoneText(v[2]) or v[3], x, y, nil, {v[1]});
        end
    end
end

function set.setuppoint(point, env, dat)
    local text, bg = point.Foreground, point.Icon;
    local iconsize = env.iconsize;
    local kind = dat.userdat[1];

    point:Show();
    point:SetOffset(dat.x, dat.y);
    text:SetText("");

    bg:Show();
    bg:SetHeight(iconsize);
    bg:SetWidth(iconsize);
    bg:SetTexture("Interface\\AddOns\\TerrainWorldMap\\images\\Icons\\Icon-" .. kind, nil, nil, "NEAREST");
    bg:SetTexCoord(0, 1, 0, 1);
end

function set.setuplegend(point, env, dat)
    env.iconsize = 16;
    set.setuppoint(point, env, dat);

    point.Text:SetText(dat.name);
end

function set.configmenu(name, lm)
    if(UIDROPDOWNMENU_MENU_LEVEL == 1) then
        local info = {};
        info.text = TWM_POINTS_DUNGEONS;
        info.func = YFOODropDown_do_toggle_normal;
        info.checked = TWMOption.Frames[lm].PointCfg and not TWMOption.Frames[lm].PointCfg[name];
        info.value = name;
        info.keepShownOnClick = 1;
        UIDropDownMenu_AddButton(info);
    end
end

TWMPoints_RegisterSet(set);
