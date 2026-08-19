-- Builds runtime lookup tables from the generated, deliberately-raw
-- Twm_flightmasters / Twm_taxipaths (Data_<Flavor>/mapdata_poi_flightmasters.lua)
-- once, at load time -- see scripts/gen_poi_flightmasters.js's header for why
-- dedup/continent-matching happens here instead of at generation time.
--
-- Twm_TaxiNodeInfo[nodeID]      = {faction, name, x, y, continent} -- name
--                                 is already resolved to the client's own
--                                 locale here (see TWM_ResolveFlightMasterName
--                                 below), not the raw per-locale name table.
-- Twm_TaxiNeighbors[nodeID]     = { otherNodeID, ... } -- for the hover-preview
--                                 line display (sets/flightmasters.lua),
--                                 deduped so an A->B and B->A row pair
--                                 don't produce two identical entries.
-- Twm_TaxiRoutesByContinent[c]  = { {x1,y1,x2,y2,fromID,toID}, ... } -- deduped
--                                 straight line segments for the "always
--                                 show" toggle (FlightPaths.lua), same-
--                                 continent pairs only. fromID/toID are kept
--                                 so FlightPaths.lua can re-check each
--                                 endpoint's faction visibility at draw time
--                                 (TWMOption.ShowEnemyFlightmasters can
--                                 change at runtime, unlike this table).

Twm_TaxiNodeInfo = {};
Twm_TaxiNeighbors = {};
Twm_TaxiRoutesByContinent = {};

-- pathID for an exact directed (fromID, toID) pair -- lets FlightPaths.lua
-- draw a route as its real TaxiPathNode polyline
-- (Twm_taxipathnodes[pathID]) while Shift is held, instead of the default
-- straight line.
Twm_TaxiPathIDByPair = {};

-- Flight masters have no AreaID/MapID of their own to resolve a live name
-- from (unlike Landmarks/Capitals/Dungeons -- see architecture.md's live-
-- name-resolution section), so scripts/gen_poi_flightmasters.js bakes in
-- every locale's name instead (Twm_flightmasters[continent][n].name, keyed
-- by client locale). This just picks the current client's own locale out of
-- that table once, at load time. enGB/ptPT clients aren't fetched as their
-- own locale (wago.tools doesn't export them separately from enUS/ptBR),
-- hence the aliasing.
local LOCALE_ALIASES = { enGB = "enUS", ptPT = "ptBR" };

function TWM_ResolveFlightMasterName(nameTable)
    local loc = GetLocale();
    loc = LOCALE_ALIASES[loc] or loc;
    return nameTable[loc] or nameTable.enUS;
end

local function TWM_BuildTaxiRouteTables()
    wipe(Twm_TaxiNodeInfo);
    for continent, list in pairs(Twm_flightmasters) do
        for _, v in ipairs(list) do
            Twm_TaxiNodeInfo[v.id] = { faction = v.faction, name = TWM_ResolveFlightMasterName(v.name), x = v.x, y = v.y, continent = continent };
        end
    end

    wipe(Twm_TaxiNeighbors);
    wipe(Twm_TaxiRoutesByContinent);
    wipe(Twm_TaxiPathIDByPair);
    local seenRoutePairs = {};

    for _, p in ipairs(Twm_taxipaths) do
        local fromID, toID = p[2], p[3];
        Twm_TaxiPathIDByPair[fromID .. "->" .. toID] = p[1];
        local fromInfo, toInfo = Twm_TaxiNodeInfo[fromID], Twm_TaxiNodeInfo[toID];
        if(fromInfo and toInfo) then
            Twm_TaxiNeighbors[fromID] = Twm_TaxiNeighbors[fromID] or {};
            Twm_TaxiNeighbors[toID] = Twm_TaxiNeighbors[toID] or {};

            local alreadyNeighbor = false;
            for _, n in ipairs(Twm_TaxiNeighbors[fromID]) do
                if(n == toID) then alreadyNeighbor = true; break; end
            end
            if(not alreadyNeighbor) then
                tinsert(Twm_TaxiNeighbors[fromID], toID);
                tinsert(Twm_TaxiNeighbors[toID], fromID);
            end

            if(fromInfo.continent == toInfo.continent) then
                local a, b = fromID, toID;
                if(b < a) then a, b = b, a; end
                local pairKey = a .. "-" .. b;
                if(not seenRoutePairs[pairKey]) then
                    seenRoutePairs[pairKey] = true;
                    local list = Twm_TaxiRoutesByContinent[fromInfo.continent];
                    if(not list) then
                        list = {};
                        Twm_TaxiRoutesByContinent[fromInfo.continent] = list;
                    end
                    tinsert(list, { fromInfo.x, fromInfo.y, toInfo.x, toInfo.y, fromID, toID });
                end
            end
        end
    end
end

TWM_BuildTaxiRouteTables();
