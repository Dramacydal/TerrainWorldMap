
local set = {name="graveyards"};

function set.getpoints(name, map)
    -- Graveyard (spirit healer) locations, generated from Wowhead's own
    -- "Spirit Healer" NPC page (see scripts/gen_poi_graveyards.js).
    if(type(Twm_poi_graveyards[map]) == "table") then
        for h,v in ipairs(Twm_poi_graveyards[map]) do
            local x,y = TWM_Big2Mini_Coord(v[1],v[2]);

            TWMPoints_AddPoint(nil, "graveyards", TWM_POINTS_GRAVEYARDS, x, y, nil, nil);
        end
    end
end

function set.setuppoint(point, env, dat)
    local text, bg = point.Foreground, point.Icon;
    local iconsize = env.iconsize;

    point:Show();
    point:SetOffset(dat.x, dat.y);
    text:SetText("");

    bg:Show();
    bg:SetHeight(iconsize);
    bg:SetWidth(iconsize);
    bg:SetTexture("Interface\\AddOns\\TerrainWorldMap\\images\\Icons\\Icon-Graveyard");
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
        info.text = TWM_POINTS_GRAVEYARDS;
        info.func = YFOODropDown_do_toggle_normal;
        info.checked = TWMOption.Frames[lm].PointCfg and not TWMOption.Frames[lm].PointCfg[name];
        info.value = name;
        info.keepShownOnClick = 1;
        UIDropDownMenu_AddButton(info);
    end
end

TWMPoints_RegisterSet(set);
