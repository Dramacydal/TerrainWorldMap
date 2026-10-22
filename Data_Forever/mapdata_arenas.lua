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
}

