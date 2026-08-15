-- Builds runtime lookup tables from the generated, deliberately-raw
-- Twm_flightmasters / Twm_taxipaths (Data_<Flavor>/mapdata_poi_flightmasters.lua)
-- once, at load time -- see scripts/gen_poi_flightmasters.js's header for why
-- dedup/continent-matching happens here instead of at generation time.
--
-- Twm_TaxiNodeInfo[nodeID]      = {faction, name, x, y, continent}
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

local function TWM_BuildTaxiRouteTables()
    wipe(Twm_TaxiNodeInfo);
    for continent, list in pairs(Twm_flightmasters) do
        for _, v in ipairs(list) do
            Twm_TaxiNodeInfo[v[1]] = { faction = v[2], name = v[3], x = v[4], y = v[5], continent = continent };
        end
    end

    wipe(Twm_TaxiNeighbors);
    wipe(Twm_TaxiRoutesByContinent);
    local seenRoutePairs = {};

    for _, p in ipairs(Twm_taxipaths) do
        local fromID, toID = p[2], p[3];
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
