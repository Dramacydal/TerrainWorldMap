
-- Leatrix Maps integration: a click on one of its dungeon/raid icons on the
-- World Map opens that instance in the TWM window. Its icons carry no map ID
-- (only a localized name and a position on the zone map), so each is matched
-- to our entrance markers (Twm_instances): by name first, by position only when
-- no name matches; if that leaves several instances (e.g. Blackrock Mountain),
-- a list is shown.

-- Icons whose name does not match any of ours in any locale, which Leatrix Maps
-- has to fix: its name (lowercase, as Leatrix gives it) -> our Map ID. The
-- Forever one has no translation of "The Ruins of Lordaeron" at all (English in
-- every locale), ours has no "The". Remove an entry when Leatrix Maps is fixed.
local TWM_LEATRIX_NAME_FIXES = {
    ["the ruins of lordaeron"] = 2999,
};

-- Template of Leatrix Maps' icons.
local TWM_LEATRIX_PIN_TEMPLATE = "LeaMapsGlobalPinTemplate";
-- Position match: entrances within this part of the zone's larger side.
local TWM_LEATRIX_MATCH_RADIUS = 0.1;
-- Index of the description matcher in TWM_LeatrixCandidates.
local TWM_LEATRIX_DESCRIPTION_TIER = 3;
-- Range of the single nearest entrance, when none is within the radius above.
local TWM_LEATRIX_FAR_RADIUS = 0.2;

-- The icon's name without color codes, the " (min-max)" level suffix and other
-- parenthesized notes ("(Main Gate)"), lowercase. Its level color arrives as
-- "|cffffff 0" (a space for a leading zero), hence hex digits or spaces.
local function TWM_LeatrixPlainName(name)
    name = name:gsub("|c[%x%s][%x%s][%x%s][%x%s][%x%s][%x%s][%x%s][%x%s]", ""):gsub("|r", "");
    name = name:gsub("%s*%b()", "");
    return name:lower();
end

-- The ":"-separated parts of `name` ("Auchindoun: Mana-Tombs"), trimmed.
local function TWM_LeatrixParts(name)
    local parts = {};
    for part in name:gmatch("[^:]+") do parts[#parts + 1] = part:match("^%s*(.-)%s*$"); end
    return parts;
end

-- True when a part of `name` is a part of `plain` (the icon's name): "Stratholme:
-- Knights' Square" (icon) / "Stratholme", "Auchindoun: Mana-Tombs" / "Mana-Tombs".
local function TWM_LeatrixHasPart(name, plainParts)
    for _, part in ipairs(TWM_LeatrixParts(name)) do
        for _, plainPart in ipairs(plainParts) do
            if(part == plainPart) then return true; end
        end
    end
    return false;
end

-- The words of `text` as a set, with the punctuation that separates them
-- ("Auchindoun: Mana-Tombs") taken out.
local function TWM_LeatrixWords(text)
    local words, count = {}, 0;
    for word in text:gsub("[:;,()]", " "):gmatch("%S+") do
        words[word] = true;
        count = count + 1;
    end
    return words, count;
end

-- True when every word of `a` is among the words of `b`.
local function TWM_LeatrixWordsWithin(a, b)
    local wordsA, countA = TWM_LeatrixWords(a);
    if(countA == 0) then return false; end
    local wordsB = TWM_LeatrixWords(b);
    for word in pairs(wordsA) do
        if(not wordsB[word]) then return false; end
    end
    return true;
end

-- Continent key, Big coordinates and the larger side of the zone for a point
-- (normalized x, y) on the map `uiMapID`; the same conversion as
-- TWM_GetUnitContinentPosition.
local function TWM_LeatrixBigPosition(uiMapID, position)
    local continent, box;
    local known = Twm_UiMapID2Zone[uiMapID];
    if(known) then
        continent = known[1];
        box = Twm_mapareas[continent] and Twm_mapareas[continent][known[2]];
    else
        continent = TWM_GetContinentForMapID(uiMapID);
        box = continent and Twm_mapareas[continent][0];
    end
    if(not box) then return nil; end
    return continent,
        -position.x * (box[1] - box[2]) + box[1],
        -position.y * (box[3] - box[4]) + box[3],
        math.max(math.abs(box[1] - box[2]), math.abs(box[3] - box[4]));
end

-- Our map selector's entry for an instance by Map ID: its display name (e.g.
-- "Auchindoun: Mana-Tombs") and the aliases (other names it is known by, e.g.
-- "The Black Morass" for "Opening of the Dark Portal"; see gen_instance_maps.js).
-- GetRealZoneText gives the same plain name for instances of one complex.
local selectorEntries;
local function TWM_LeatrixSelectorEntry(mapID)
    if(not selectorEntries) then
        selectorEntries = {};
        for _, list in ipairs({TWM_DUNGEONS or {}, TWM_RAIDS or {}}) do
            for displayName, e in pairs(list) do
                if(e.mapID) then selectorEntries[e.mapID] = {name = displayName, alias = e.alias}; end
            end
        end
    end
    return selectorEntries[tostring(mapID)];
end

-- True when the map `mapID` is somewhere below `ancestorMapID` in the game's
-- map hierarchy (the Isle of Thunder is below Pandaria).
local function TWM_LeatrixIsBelow(mapID, ancestorMapID)
    local guard = 0;
    local info = C_Map.GetMapInfo(mapID);
    while(info and info.parentMapID and info.parentMapID > 0 and guard < 10) do
        if(info.parentMapID == ancestorMapID) then return true; end
        info = C_Map.GetMapInfo(info.parentMapID);
        guard = guard + 1;
    end
    return false;
end

-- The entrance lists an icon on `continent` can lead to: that continent's own,
-- those of the continents below it (the Isle of Thunder, where the Throne of
-- Thunder is, for an icon in Pandaria) and, from there, those of the instances
-- they enter (Blackwing Lair is entered from Blackrock Spire). Instances of
-- other continents (Coilfang, on Outland, for an icon in the Eastern Kingdoms)
-- are not among them. Every list when the continent is unknown. The
-- continent's own list is the first.
local function TWM_LeatrixReachableGroups(continent)
    local groups = {};
    if(not continent) then
        for _, group in pairs(Twm_instances) do groups[#groups + 1] = group; end
        return groups;
    end

    -- the queue is taken from its end: the continent itself goes last
    local seen, queue = {}, {};
    local continentMapID = Twm_ContinentMapID[continent];
    if(continentMapID) then
        for key in pairs(Twm_instances) do
            local mapID = Twm_ContinentMapID[key];
            if(key ~= continent and mapID and TWM_LeatrixIsBelow(mapID, continentMapID)) then
                queue[#queue + 1] = key;
            end
        end
    end
    queue[#queue + 1] = continent;
    while(#queue > 0) do
        local key = table.remove(queue);
        local group = Twm_instances[key];
        if(type(group) == "table" and not seen[key]) then
            seen[key] = true;
            groups[#groups + 1] = group;
            for _, v in ipairs(group) do
                -- an exit leads back outdoors, possibly to another continent
                if(v[1] ~= "Exit" and v[6]) then queue[#queue + 1] = v[6]; end
            end
        end
    end
    return groups;
end

-- The maps of our selector that no entrance marker leads to (new maps whose
-- entrances are not in the data yet), as entries like the entrance markers' but
-- without a position: {"Dungeon"|"Raid", Map ID, name}. They can only be found by
-- name (and are opened like any other, without an arrival point).
local markerless;
local function TWM_LeatrixMarkerlessGroup()
    if(not markerless) then
        local hasMarker = {};
        for _, group in pairs(Twm_instances) do
            for _, v in ipairs(group) do
                if(v[1] ~= "Exit") then hasMarker[v[2]] = true; end
            end
        end

        markerless = {};
        for kind, list in pairs({Dungeon = TWM_DUNGEONS or {}, Raid = TWM_RAIDS or {}}) do
            for displayName, e in pairs(list) do
                local mapID = tonumber(e.mapID);
                if(mapID and not hasMarker[mapID]) then markerless[#markerless + 1] = {kind, mapID, displayName}; end
            end
        end
    end
    return markerless;
end

-- Instances the icon can stand for, nearest first: {entry, name, d}, one per
-- target map. Looked up by name among the instances reachable from the icon's
-- continent (also inside another
-- instance, like Blackwing Lair): the icon's name is the instance's name (the
-- one the game gives, our map selector's or one of its aliases); else
-- one of the parts of the instance's name ("Auchindoun: Mana-Tombs"); else the
-- instance's name is listed in the icon's description (an icon for a whole
-- complex such as Blackrock Mountain; its words may be in another order), plus
-- the entrances next to the icon. Only when no name matches, by position.
-- `namesOnly` stops after the names (what the icon matches by name, tier,
-- plain name); `skip(v)` excludes entrances from the position stage (those
-- another icon of the map matched by name, see TWM_LeatrixAssign).
local function TWM_LeatrixCandidates(uiMapID, info, namesOnly, skip)
    local continent, bx, by, size = TWM_LeatrixBigPosition(uiMapID, info.position);
    local entries = continent and Twm_instances[continent];
    local plain = info.name and TWM_LeatrixPlainName(info.name) or "";
    local plainParts = TWM_LeatrixParts(plain);
    local fixedMapID = TWM_LEATRIX_NAME_FIXES[plain];
    local description = info.description and info.description:lower();
    -- the names an icon for a complex lists ("Ruins of Ahn'Qiraj, Temple of Ahn'Qiraj")
    local items = {};
    if(description) then
        -- ("Black Morass (req: 65)": the notes in parentheses are not part of a name)
        for item in description:gsub("|n", ","):gsub("%b()", ""):gmatch("[^,]+") do items[#items + 1] = item; end
    end

    local found = {};
    local function consider(v, d)
        if(v[1] == "Exit" or not TWM_GetPortalTargetMap(v[2], v[6])) then return; end
        if(not found[v[2]] or d < found[v[2]].d) then
            found[v[2]] = {entry = v, d = d, name = (TWM_LeatrixSelectorEntry(v[2]) or {}).name or GetRealZoneText(v[2]) or v[3]};
        end
    end

    local function distance(v, group)
        return (group == entries and bx) and (v[4] - bx)^2 + (v[5] - by)^2 or math.huge;
    end

    local matchers = {
        function(name) return plain ~= "" and name == plain; end,
        function(name) return plain ~= "" and TWM_LeatrixHasPart(name, plainParts); end,
        function(name)
            -- A description with one name is just the icon's type ("Dungeon",
            -- which a name like "Steamvault: Паровое подземелье" can contain).
            if(not description or #items < 2) then return false; end
            if(description:find(name, 1, true)) then return true; end
            -- the same words in another order or with others between ("Ahn'Qiraj
            -- Temple" / "Temple of Ahn'Qiraj")
            for _, item in ipairs(items) do
                if(TWM_LeatrixWordsWithin(name, item) or TWM_LeatrixWordsWithin(item, name)) then return true; end
            end
            return false;
        end,
    };
    local tier = "position";
    local groups = TWM_LeatrixReachableGroups(continent);
    groups[#groups + 1] = TWM_LeatrixMarkerlessGroup();
    for tierIndex, matches in ipairs(matchers) do
        for _, group in ipairs(groups) do
            for _, v in ipairs(group) do
                local entry = TWM_LeatrixSelectorEntry(v[2]);
                local names = {GetRealZoneText(v[2]) or v[3]};
                if(entry) then
                    names[#names + 1] = entry.name;
                    for _, alias in ipairs(entry.alias or {}) do names[#names + 1] = alias; end
                end
                if(tierIndex == 1 and v[2] == fixedMapID) then
                    consider(v, distance(v, group));
                else
                    for _, name in ipairs(names) do
                        if(matches(name:lower())) then
                            consider(v, distance(v, group));
                            break;
                        end
                    end
                end
            end
        end
        if(next(found)) then
            tier = tierIndex;
            break;
        end
    end

    local function sorted()
        local list = {};
        for _, c in pairs(found) do list[#list + 1] = c; end
        table.sort(list, function(a, b) return a.d < b.d; end);
        return list;
    end
    if(namesOnly) then return sorted(), tier, plain; end

    -- By position when no name matched; also for an icon of a complex (several
    -- names in its description), whose other entrances next to it are part of
    -- it. Leatrix's names for those differ from ours (Caverns of Time: "Black
    -- Morass" / our "Opening of the Dark Portal"), so the entrances are taken
    -- around the nearest one.
    local composite = #items >= 2;

    -- Not among those by position: the ones taken by other icons (`skip`) and,
    -- unless the icon is a complex's (which has both), the entrances of the
    -- other kind -- a raid icon (its `atlasName`) stands for a raid, not for
    -- a dungeon next to it.
    local function excluded(v)
        if(skip and skip(v)) then return true; end
        return not composite and info.atlasName ~= nil and v[1] ~= info.atlasName;
    end

    if((next(found) == nil or tier == TWM_LEATRIX_DESCRIPTION_TIER or composite) and type(entries) == "table") then
        local radius2 = (size * TWM_LEATRIX_MATCH_RADIUS)^2;
        for _, v in ipairs(entries) do
            local d = distance(v, entries);
            if(d <= radius2 and not excluded(v)) then consider(v, d); end
        end

        local nearest, nearestD;
        for _, v in ipairs(entries) do
            local d = distance(v, entries);
            if(v[1] ~= "Exit" and TWM_GetPortalTargetMap(v[2], v[6]) and not excluded(v)
                    and (not nearestD or d < nearestD)) then
                nearest, nearestD = v, d;
            end
        end

        -- The icon may be placed a bit off (Sunken Temple, whose name differs
        -- too): within a wider range the nearest entrance is taken.
        if(nearest and nearestD <= (size * TWM_LEATRIX_FAR_RADIUS)^2) then
            if(composite) then
                for _, v in ipairs(entries) do
                    if((v[4] - nearest[4])^2 + (v[5] - nearest[5])^2 <= radius2 and not excluded(v)) then
                        consider(v, distance(v, entries));
                    end
                end
            elseif(next(found) == nil) then
                consider(nearest, nearestD);
            end
        end
    end

    return sorted(), tier, plain;
end

-- Which instances each dungeon/raid icon of a map stands for, worked out once
-- per map (when the first of its icons is clicked) for all of its icons
-- together: an instance an icon matched by name (the icon's name equals the
-- instance's name or one of its parts) is that icon's, so another icon next to
-- it does not take it by position (the Frozen Halls icon, standing next to
-- Icecrown Citadel's). Cached by map and icon position.
local TWM_LEATRIX_NAME_TIERS = 2;
local assignments = {};

local function TWM_LeatrixIconKey(info)
    return format("%.4f:%.4f:%s", info.position.x, info.position.y, tostring(info.name));
end

local function TWM_LeatrixIsInstanceIcon(info)
    return info and info.position and not info.ZoneCrossing and (info.atlasName == "Dungeon" or info.atlasName == "Raid");
end

-- Older Leatrix Maps (the one for Forever) draws its icons itself: plain frames
-- on the map's canvas (`isLeaMapsPin`), without mouse input, its data in
-- `pin.data` = {kind, x%, y%, name, description, atlas, minLevel, maxLevel}.
-- Its data as the same table the other kind of icon has (`info`), one per data.
local infoByData = setmetatable({}, {__mode = "k"});
local function TWM_LeatrixInfoFromData(data)
    local info = infoByData[data];
    if(not info) then
        info = {name = data[4], description = data[5], atlasName = data[6], position = {x = data[2] / 100, y = data[3] / 100}};
        infoByData[data] = info;
    end
    return info;
end

-- The icons of the map `uiMapID` that are on the map now (all of them are
-- created together when the map is shown); `info` is always among them.
local function TWM_LeatrixMapIcons(info)
    local infos, seen = {info}, {[info] = true};
    local function add(other)
        if(TWM_LeatrixIsInstanceIcon(other) and not seen[other]) then
            seen[other] = true;
            infos[#infos + 1] = other;
        end
    end

    local pool = WorldMapFrame.pinPools and WorldMapFrame.pinPools[TWM_LEATRIX_PIN_TEMPLATE];
    if(pool) then
        for pin in pool:EnumerateActive() do add(pin.twmInfo or pin.poiInfo); end
    end
    for _, child in ipairs({WorldMapFrame:GetCanvas():GetChildren()}) do
        if(child.isLeaMapsPin and child.data and child:IsShown()) then add(TWM_LeatrixInfoFromData(child.data)); end
    end
    return infos;
end

local function TWM_LeatrixAssign(uiMapID, info)
    local cache = assignments[uiMapID];
    local key = TWM_LeatrixIconKey(info);
    if(cache and cache[key]) then return cache[key]; end

    local infos = TWM_LeatrixMapIcons(info);
    local byName, claimed = {}, {};
    for _, icon in ipairs(infos) do
        local list, tier, plain = TWM_LeatrixCandidates(uiMapID, icon, true);
        byName[icon] = {tier = tier, plain = plain};
        if(type(tier) == "number" and tier <= TWM_LEATRIX_NAME_TIERS) then
            for _, c in ipairs(list) do
                claimed[c.entry[2]] = claimed[c.entry[2]] or {};
                claimed[c.entry[2]][icon] = true;
            end
        end
    end

    cache = {};
    assignments[uiMapID] = cache;
    for _, icon in ipairs(infos) do
        local function claimedByOther(v)
            local owners = claimed[v[2]];
            return owners ~= nil and not owners[icon] and next(owners) ~= nil;
        end
        local list, tier, plain = TWM_LeatrixCandidates(uiMapID, icon, false, claimedByOther);
        cache[TWM_LeatrixIconKey(icon)] = {list = list, tier = tier, plain = plain};
    end
    return cache[key];
end

local function TWM_LeatrixOpenInstance(entry)
    local function open()
        -- no arrival point: the map is fitted to the window like a pick from the list
        TWM_OpenPortalTarget(TWMFrame, entry[2], entry[6]);
    end
    if(TWMFrame:IsShown()) then
        open();
    else
        TWMFrame:Show();
        -- a window just shown has no resolved layout yet
        C_Timer.After(0, open);
    end
end

local TWM_LEATRIX_ICON_SIZE = 16;

-- The "Open dungeon and raid icons in the TerrainWorldMap window" option
-- (Integrations tab of the settings, on unless switched off).
local function TWM_LeatrixClickEnabled()
    return not (TWMOption and TWMOption.LeatrixMapsClick == false);
end

-- A click on the icon `info` (drawn by `pin`); true when it was taken (an
-- instance was opened or a list shown), false when the icon is not one of ours
-- to handle or the option is off.
local function TWM_LeatrixIconClick(pin, info)
    if(not TWM_LeatrixClickEnabled() or not TWM_LeatrixIsInstanceIcon(info)) then return false; end

    local assigned = TWM_LeatrixAssign(WorldMapFrame:GetMapID(), info);
    local list, tier, plain = assigned.list, assigned.tier, assigned.plain;
    if(TWM_DebugTiles) then
        local names = {};
        for _, c in ipairs(list) do names[#names + 1] = c.name; end
        print("TWM Leatrix: name=" .. tostring(info.name):gsub("|", "||") .. " plain=" .. tostring(plain)
            .. " description=" .. tostring(info.description) .. " tier=" .. tostring(tier)
            .. " found=" .. table.concat(names, "; "));
        for _, c in ipairs(list) do
            local real = GetRealZoneText(c.entry[2]);
            local lowered = (real or c.entry[3]):lower();
            print(format("TWM Leatrix:   %s real=[%s] lowered=[%s](%d) plain=[%s](%d) part=%s exact=%s", c.name, tostring(real),
                lowered, #lowered, plain, #plain, tostring(TWM_LeatrixHasPart(lowered, TWM_LeatrixParts(plain))), tostring(lowered == plain)));
        end
    end
    if(#list == 0) then return false; end
    if(#list == 1) then
        TWM_LeatrixOpenInstance(list[1].entry);
        return true;
    end

    -- by name (the cached list stays in the order of distance)
    local byName = {};
    for i, c in ipairs(list) do byName[i] = c; end
    table.sort(byName, function(a, b) return a.name:lower() < b.name:lower(); end);

    MenuUtil.CreateContextMenu(pin, function(owner, root)
        for _, c in ipairs(byName) do
            local item = root:CreateButton(c.name, TWM_LeatrixOpenInstance, c.entry);
            -- our entrance icon (as on the map) to the left of the text
            item:AddInitializer(function(button)
                local icon = button:AttachTexture();
                icon:SetPoint("LEFT");
                icon:SetSize(TWM_LEATRIX_ICON_SIZE, TWM_LEATRIX_ICON_SIZE);
                icon:SetTexture("Interface\\AddOns\\TerrainWorldMap\\images\\Icons\\Icon-" .. c.entry[1], nil, nil, "NEAREST");
                button.fontString:ClearAllPoints();
                button.fontString:SetPoint("LEFT", icon, "RIGHT", 4, 0);
            end);
        end
    end);
    return true;
end

-- The icons of Leatrix Maps' own pin mixin (a map pin): its mouse-up.
local function TWM_LeatrixPinClick(pin, button)
    if(button == "LeftButton") then TWM_LeatrixIconClick(pin, pin.twmInfo or pin.poiInfo); end
end

local function TWM_LeatrixHookPin(pin)
    hooksecurefunc(pin, "OnAcquired", function(self, info) self.twmInfo = info; end);
    hooksecurefunc(pin, "OnMouseUp", TWM_LeatrixPinClick);
end

-- The icons Leatrix Maps draws itself take no mouse input, it finds the one
-- under the cursor by their on-map footprint (its `hitScale`, 0.8, of the icon).
local TWM_LEATRIX_HIT_SCALE = 0.8;

local function TWM_LeatrixPinAtCursor()
    local canvas = WorldMapFrame:GetCanvas();
    local nx, ny = WorldMapFrame:GetNormalizedCursorPosition();
    if(not (nx and ny)) then return nil; end

    local width, height = canvas:GetWidth(), canvas:GetHeight();
    local best, bestD;
    for _, child in ipairs({canvas:GetChildren()}) do
        if(child.isLeaMapsPin and child.data and child:IsShown()) then
            local dx = (nx - child.data[2] / 100) * width;
            local dy = (ny - child.data[3] / 100) * height;
            local half = child:GetScale() * TWM_LEATRIX_HIT_SCALE * 0.5;
            if(math.abs(dx) <= child:GetWidth() * half and math.abs(dy) <= child:GetHeight() * half) then
                local d = dx * dx + dy * dy;
                if(not bestD or d < bestD) then best, bestD = child, d; end
            end
        end
    end
    return best;
end

-- Their click: a click on the map's canvas (a drag is not one). A canvas click
-- handler that returns true stops the map's own handling, which would
-- otherwise go to the zone under the cursor (an icon near the edge of the map,
-- like Uldaman's, is over the neighbouring zone too).
local TWM_LEATRIX_CLICK_PRIORITY = 100;

local function TWM_LeatrixInstallCanvasClicks()
    if(not WorldMapFrame.AddCanvasClickHandler) then return; end

    WorldMapFrame:AddCanvasClickHandler(function(_, button)
        if(button ~= "LeftButton") then return false; end
        local pin = TWM_LeatrixPinAtCursor();
        return pin ~= nil and TWM_LeatrixIconClick(pin, TWM_LeatrixInfoFromData(pin.data));
    end, TWM_LEATRIX_CLICK_PRIORITY);
end

local installed;

-- Leatrix Maps creates its pin mixin on PLAYER_ENTERING_WORLD. Pins get their
-- methods from the mixin when they are created, so pins that already exist
-- (the mixin hooks only reach later ones) are hooked one by one.
local function TWM_LeatrixInstall()
    if(installed or not LeaMapsGlobalPinMixin) then return; end
    installed = true;

    local pool = WorldMapFrame.pinPools and WorldMapFrame.pinPools[TWM_LEATRIX_PIN_TEMPLATE];
    if(pool) then
        for pin in pool:EnumerateActive() do TWM_LeatrixHookPin(pin); end
        for _, pin in ipairs(pool.inactiveObjects or {}) do TWM_LeatrixHookPin(pin); end
    end

    hooksecurefunc(LeaMapsGlobalPinMixin, "OnAcquired", function(pin, info) pin.twmInfo = info; end);
    hooksecurefunc(LeaMapsGlobalPinMixin, "OnMouseUp", TWM_LeatrixPinClick);
end

local leatrixFrame = CreateFrame("Frame");
leatrixFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
leatrixFrame:SetScript("OnEvent", function(self)
    self:UnregisterAllEvents();
    TWM_LeatrixInstall();
    if(installed or not WorldMapFrame) then return; end

    -- No pin mixin (yet): the version that draws its icons itself (clicks found
    -- on the map's canvas; with the mixin version there is nothing to find
    -- there), and the mixin, should it appear after all, when the map is shown.
    if((C_AddOns and C_AddOns.IsAddOnLoaded or IsAddOnLoaded)("Leatrix_Maps")) then
        TWM_LeatrixInstallCanvasClicks();
    end
    WorldMapFrame:HookScript("OnShow", TWM_LeatrixInstall);
end);
