-- GENERATED FILE -- do not hand-edit, regenerate with scripts/gen_instance_maps.js
-- and replace this file wholesale. See scripts/README.md for details.
--
-- Raid zone boxes, kept deliberately separate from
-- Twm_ContinentMapID/TWM_MAPS and Twm_BattlegroundMapID/TWM_BATTLEGROUNDS
-- (own dropdown category, see this script's header). No MapID table:
-- same as arenas, these have no reliable UiMapID to back position
-- tracking or a continent-hint lookup with.
-- Twm_mapareas is the same generic per-map-name box registry every other
-- top-level map category already populates, derived from valid-tile
-- extent (Big coordinates, via TWM_Mini2Big_Coord's own formula) when a
-- real ADT tile grid exists, or (most dungeons/raids: a single global
-- WMO, no ADT grid at all) from that WMO's own MOHD bounding box placed
-- by the WDT-level MODF instead -- see pureWmoBoxFor's header. Does NOT
-- depend on baked minimap art existing at all (absent on Vanilla).
-- Twm_RaidNames is resolved into the actual TWM_RAIDS dropdown
-- table at load time (TerrainWorldMap.lua), same as Twm_ArenaNames/
-- Twm_flightmasters' name tables -- see this file's own header comment.
-- `expansion` is Map.csv's own ExpansionID (a string, like every other ID
-- in this codebase) -- drives the expansion-selection dropdown level
-- TerrainWorldMap.lua inserts between this category and the actual list.

Twm_RaidNames = {
    {
        key = "OnyxiaLairInstance",
        expansion = "0",
        name = {
            enUS = "Onyxia's Lair",
            deDE = "Onyxias Hort",
            esES = "Guarida de Onyxia",
            esMX = "Guarida de Onyxia",
            frFR = "Repaire d’Onyxia",
            itIT = "Onyxia's Lair",
            koKR = "오닉시아의 둥지",
            ptBR = "Covil de Onyxia",
            ruRU = "Логово Ониксии",
            zhCN = "奥妮克希亚的巢穴",
            zhTW = "奧妮克希亞的巢穴",
        },
    },
}

Twm_mapareas["OnyxiaLairInstance"] = {
    [0] = {17129.912611643475, 16847.833719889324, 17092.778622309368, 16780.20228068034},    --Onyxia'sLair
}
