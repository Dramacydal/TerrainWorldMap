
local set = {name="dungeons"};

function set.getpoints(name, map)
    -- Dungeon/raid entrance and portal markers, generated (see
    -- scripts/gen_poi_instances.js) into Data_<Flavor>/mapdata_poi_instances.lua.
    -- Keyed by the map the marker stands on (a continent, or a dungeon/raid:
    -- exits and links between instances). Entries are
    -- {"Dungeon"|"Raid"|"Exit", target MapID, Name, x, y [, target Directory,
    -- target x, target y]} -- the kind is the type of the TARGET map and
    -- doubles as the icon name (Icon-Dungeon / Icon-Raid / Icon-Exit, the
    -- last one for a target that is not a dungeon/raid, i.e. an outdoor map).
    -- x/y are on this map, target x/y on the target map
    -- (all Big coordinates). Name is only a fallback -- GetRealZoneText
    -- accepts the same MapID (confirmed: GetRealZoneText(530) == "Outland",
    -- Map.ID 530 = Expansion01) and returns the live, locale-correct name.
    if(type(Twm_instances[map]) == "table") then
        for h,v in ipairs(Twm_instances[map]) do
            local x,y = TWM_Big2Mini_Coord(v[4],v[5]);

            TWMPoints_AddPoint(nil, "dungeons", GetRealZoneText(v[2]) or v[3], x, y, nil, {v[1], v[2], v[6], v[7], v[8]});
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
    bg:SetVertexColor(1, 1, 1, 1);
end

-- A click on the marker opens the target map and centers on the arrival point
-- (see TWMP_EnableDragThrough).
function set.onclick(dat, frame)
    local u = dat.userdat;
    TWM_OpenPortalTarget(frame, u[2], u[3], u[4], u[5]);
end

-- Extra tooltip line (see TWMPoints_UpdateTooltip).
function set.legendhint(dat)
    local u = dat.userdat;
    if(TWM_GetPortalTargetMap(u[2], u[3])) then
        return TWM_TOOLTIP_CLICK_OPEN_MAP;
    end
end

function set.setuplegend(point, env, dat)
    env.iconsize = 16;
    set.setuppoint(point, env, dat);

    point.Text:SetText(dat.name);
end

function set.configmenu(menu, name, lm)
    TWM_AddPointToggle(menu, lm, name, TWM_OPTIONS_SHOW_DUNGEONS);
end

TWMPoints_RegisterSet(set);
