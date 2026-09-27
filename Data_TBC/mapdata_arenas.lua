-- GENERATED FILE -- do not hand-edit, regenerate with scripts/gen_arenas.js
-- and replace this file wholesale. See scripts/README.md for details.
--
-- Arena zone boxes, kept deliberately separate from Twm_ContinentMapID/
-- TWM_MAPS and Twm_BattlegroundMapID/TWM_BATTLEGROUNDS (see this script's
-- header) -- own "Arenas" dropdown category. No Twm_ArenaMapID table:
-- arenas have no UiMapID at all (unlike battlegrounds), so there's no
-- position tracking or continent-hint lookup to back with one.
-- Twm_mapareas is the same generic per-map-name box registry every other
-- top-level map category already populates, just derived from valid-tile
-- extent (Big coordinates, via TWM_Mini2Big_Coord's own formula) instead
-- of a UiMapAssignment Region box, which doesn't exist for these.
-- Twm_ArenaNames is resolved into the actual TWM_ARENAS dropdown table at
-- load time (TerrainWorldMap.lua), same as Twm_flightmasters' name
-- tables (TaxiRoutes.lua) -- see this file's own header comment.

Twm_ArenaNames = {
    {
        key = "bladesedgearena",
        name = {
            enUS = "Blade's Edge Arena",
            deDE = "Arena des Schergrats",
            esES = "Arena Filospada",
            esMX = "Arena Filospada",
            frFR = "Arène des Tranchantes",
            itIT = "Blade's Edge Arena",
            koKR = "칼날 산맥 투기장",
            ptBR = "Arena da Lâmina Afiada",
            ruRU = "Арена Острогорья",
            zhCN = "刀锋山竞技场",
            zhTW = "劍刃競技場",
        },
    },
    {
        key = "PVPZone05",
        name = {
            enUS = "Nagrand Arena",
            deDE = "Arena von Nagrand",
            esES = "Arena de Nagrand",
            esMX = "Arena de Nagrand",
            frFR = "Arène de Nagrand",
            itIT = "Nagrand Arena",
            koKR = "나그란드 투기장",
            ptBR = "Arena de Nagrand",
            ruRU = "Арена Награнда",
            zhCN = "纳格兰竞技场",
            zhTW = "納葛蘭競技場",
        },
    },
    {
        key = "PVPLordaeron",
        name = {
            enUS = "Ruins of Lordaeron",
            deDE = "Ruinen von Lordaeron",
            esES = "Ruinas de Lordaeron",
            esMX = "Ruinas de Lordaeron",
            frFR = "Ruines de Lordaeron",
            itIT = "Ruins of Lordaeron",
            koKR = "로데론의 폐허",
            ptBR = "Ruínas de Lordaeron",
            ruRU = "Руины Лордерона",
            zhCN = "洛丹伦废墟",
            zhTW = "羅德隆廢墟",
        },
    },
}

Twm_mapareas["PVPZone05"] = {
    [0] = {3733.3333333333335, 2133.3333333333335, 4800, 3200},    --NagrandArena
}
Twm_mapareas["bladesedgearena"] = {
    [0] = {1066.6666666666667, -533.3333333333334, 6933.333333333334, 5333.333333333334},    --Blade'sEdgeArena
}
Twm_mapareas["PVPLordaeron"] = {
    [0] = {3200, 533.3333333333334, 2666.666666666667, 0},    --RuinsofLordaeron
}
