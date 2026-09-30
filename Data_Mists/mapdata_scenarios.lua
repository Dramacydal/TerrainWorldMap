-- GENERATED FILE -- do not hand-edit, regenerate with scripts/gen_instance_maps.js
-- and replace this file wholesale. See scripts/README.md for details.
--
-- Scenario zone boxes, kept deliberately separate from
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
-- Twm_ScenarioNames is resolved into the actual TWM_SCENARIOS dropdown
-- table at load time (TerrainWorldMap.lua), same as Twm_ArenaNames/
-- Twm_flightmasters' name tables -- see this file's own header comment.
-- `expansion` is Map.csv's own ExpansionID (a string, like every other ID
-- in this codebase) -- unused by Scenarios' own dropdown today (Mists is
-- the only flavor with any, always ExpansionID 4), kept for consistency
-- with Dungeons/Raids' shared generator.

Twm_ScenarioNames = {
    {
        key = "PandaFishingVillageScenario",
        expansion = "4",
        name = {
            enUS = "Greenstone Village",
            deDE = "Grünstein",
            esES = "Aldea Verdemar",
            esMX = "Aldea Verdemar",
            frFR = "Pierre-Verte",
            itIT = "Greenstone Village",
            koKR = "녹옥 마을",
            ptBR = "Aldeia Rocha Verde",
            ruRU = "Деревня Зеленой Скалы",
            zhCN = "绿石村",
            zhTW = "綠石村",
        },
    },
}

Twm_mapareas["PandaFishingVillageScenario"] = {
    [0] = {-533.3333333333334, -4266.666666666667, 4266.666666666667, 1066.6666666666667},    --GreenstoneVillage
}
