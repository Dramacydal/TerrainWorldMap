
local set = {name="players", internal = {}};
local eventframe;
local unitlocations = {};

local addpoint = function(name, unit)
    TWMPoints_AddMobilePoint(nil, name, unit, nil, nil);

    TWMPoints_SetupMobilePointF(nil, name, unit, "Icon","SetTexture",
            "Interface\\AddOns\\TerrainWorldMap\\images\\Icons\\Icon-PartyUnit", nil, nil, "NEAREST");
    if(string.find(unit,"party")) then
        TWMPoints_SetupMobilePointF(nil, name, unit, "Icon","SetVertexColor",1,0.4,0.4,1);
    elseif(string.find(unit,"raid")) then
        TWMPoints_SetupMobilePointF(nil, name, unit, "Icon","SetVertexColor",1,1,0.3,1);
    else
        TWMPoints_SetupMobilePointF(nil, name, unit, "Icon","SetVertexColor",0.4,0.6,1,1);
    end
    TWMPoints_SetupMobilePointF(nil, name, unit, "Icon","SetTexCoord",0,1,0,1);
    TWMPoints_SetupMobilePointF(nil, name, unit, "Icon","Show");
end

function set.getmobilepoints(name)
    if(eventframe == nil) then
        set.internal.CreateEventFrame();
    end

    addpoint(name, "player");
    for h = 1,40 do
        addpoint(name, "raid"..h);
    end
    for h = 1,5 do
        addpoint(name, "party"..h);
    end
end

function set.OnUpdate(name, frame, elapsed)
    set.internal.OnWorldMapUpdate()
end

function set.internal.OnWorldMapUpdate()
    set.internal.OnWorldMapUpdateUnit("player");
    if(IsInRaid()) then
        for h = 1,GetNumGroupMembers() do
            set.internal.OnWorldMapUpdateUnit("raid"..h);
        end
    else
        for h = 1,GetNumGroupMembers() do
            set.internal.OnWorldMapUpdateUnit("party"..h);
        end
    end
end

function set.internal.OnWorldMapUpdateUnit(u)
    local map, x, y = TWM_GetUnitContinentPosition(u);
    local ux, uy;

    if(map == nil) then
        if(unitlocations[u]) then
            unitlocations[u] = nil;
            TWMPoints_HideMobile("players", u);
        end
        return;
    end

    if(UnitIsUnit(u, "player") and u ~= "player") or
            (UnitInParty(u) and string.sub(u, 1, 4) == "raid") then
        -- hide other representations of units
        if(unitlocations[u]) then
            unitlocations[u] = nil;
            TWMPoints_HideMobile("players", u);
        end
        return;
    end

    if(Twm_mapareas[map] == nil) then
        return;
    end

    -- Map identified but no live position on it (e.g. Alterac Valley) --
    -- nothing to plot; treat like unit not found so a stale pin gets
    -- cleared instead of erroring on the arithmetic below.
    if(x == nil) then
        if(unitlocations[u]) then
            unitlocations[u] = nil;
            TWMPoints_HideMobile("players", u);
        end
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
    
    ux, uy = TWM_Big2Mini_Coord((-x*(x1-x2) + x1), (-y*(y1-y2) + y1))
    unitlocations[u] = { map, ux, uy};
    TWMPoints_Mobile_SetLocation("players", u, map, ux, uy);
end

function set.internal.CreateEventFrame()
    if(eventframe ~= nil) then
        return;
    end

    eventframe = CreateFrame("frame");

    eventframe:SetScript("OnEvent", function(self, event, ...)
        if(event == "GROUP_ROSTER_UPDATE") then
            local q = {};
            for h,v in pairs(unitlocations) do
                if(not UnitExists(h)) then
                    tinsert(q,h);
                end
            end

            for h,v in ipairs(q) do
                unitlocations[v] = nil;
                TWMPoints_HideMobile("players", v);
            end
        end
    end)

    eventframe:RegisterEvent("GROUP_ROSTER_UPDATE");
end

-- Class icon from the client's class-icon atlas, else the class icon sheet.
local function SetClassIcon(icon, class)
    local atlas = "classicon-" .. class:lower();
    if(C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(atlas)) then
        icon:SetAtlas(atlas);
        return true;
    end

    local coords = CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[class];
    if(coords) then
        icon:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES");
        icon:SetTexCoord(unpack(coords));
        return true;
    end
    return false;
end

-- The unit's name in its class color plus its class icon; plain name and no
-- icon when the class is unknown.
function set.setuplegend(point, env, dat)
    local name = UnitName(dat.name);
    local class = select(2, UnitClass(dat.name));
    local color = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class];

    point:Show();
    if(color and name) then
        name = string.format("|cff%02x%02x%02x%s|r",
            math.floor(color.r * 255 + 0.5), math.floor(color.g * 255 + 0.5), math.floor(color.b * 255 + 0.5), name);
    end
    point.Text:SetText(name);
    point.Icon:SetTexture(nil);
    if(class) then
        SetClassIcon(point.Icon, class);
    end
    point.Text:Show();
    point.Icon:SetHeight(env.iconsize);
    point.Icon:SetWidth(env.iconsize);
end

TWMPoints_RegisterSet(set);
