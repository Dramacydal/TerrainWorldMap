
local set = {name="capitals"};

-- Capital's own Twm_mapareas box center, if it has one (most do -- capitals
-- are usually their own top-level displayed zone).
local function findByBox(map, areaID)
    local box = Twm_mapareas[map] and Twm_mapareas[map][areaID];
    if(box == nil) then
        return nil;
    end

    return (box[1] + box[2]) / 2, (box[3] + box[4]) / 2;
end

-- Fallback: an AreaID with no Twm_mapareas box of its own (e.g. Northrend's
-- Dalaran, which has no dedicated UiMapAssignment zone row in some builds)
-- may still show up in Twm_poi_areas as a top-level ParentAreaID-0 entry
-- (see scripts/gen_poi_areas.js) -- reuse that centroid instead.
local function findByPoiAreas(map, areaID)
    if(type(Twm_poi_areas[map]) ~= "table") then
        return nil;
    end

    for h,v in ipairs(Twm_poi_areas[map]) do
        if(v[1] == areaID) then
            return v[3], v[4];
        end
    end

    return nil;
end

function set.getpoints(name, map)
    -- Hardcoded capital-city AreaIDs (see mapdata_zones.lua's
    -- Twm_CapitalAreaIDs) positioned via their own Twm_mapareas box, or via
    -- Twm_poi_areas as a fallback.
    for areaID, capitalName in pairs(Twm_CapitalAreaIDs) do
        local bigX, bigY = findByBox(map, areaID);
        if(bigX == nil) then
            bigX, bigY = findByPoiAreas(map, areaID);
        end

        if(bigX ~= nil) then
            local x,y = TWM_Big2Mini_Coord(bigX, bigY);

            TWMPoints_AddPoint(nil, "capitals", capitalName, x, y, nil, nil);
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
    bg:SetTexture("Interface\\AddOns\\TerrainWorldMap\\images\\Icons\\Icon-City", nil, nil, "NEAREST");
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
        info.text = TWM_POINTS_CAPITALS;
        info.func = YFOODropDown_do_toggle_normal;
        info.checked = TWMOption.Frames[lm].PointCfg and not TWMOption.Frames[lm].PointCfg[name];
        info.value = name;
        info.keepShownOnClick = 1;
        UIDropDownMenu_AddButton(info);
    end
end

TWMPoints_RegisterSet(set);
