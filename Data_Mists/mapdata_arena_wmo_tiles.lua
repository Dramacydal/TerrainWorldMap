-- GENERATED FILE -- do not hand-edit, regenerate with scripts/gen_arena_wmo_tiles.js
-- and replace this file wholesale. See scripts/README.md for details.
--
-- Minimap tiles for the WMO structure actually placed on an arena whose
-- own outdoor terrain has no baked minimap art (see this script's own
-- header for the full explanation and the coordinate derivation).
-- {fileID, x1, x2, y1, y2, height} per tile, x1/y1 = max, x2/y2 = min
-- (same box convention as Twm_mapareas). height is MODF.position[1]
-- (the placement's own world height) PLUS that specific tile's own
-- WMO GROUP's height-axis center -- a single WMO placement can have
-- groups at meaningfully different real heights (e.g. a raised
-- walkway/balcony vs. the main floor below it), so height is tracked
-- per group, not just per placement. x1/x2/y1/y2 already include a
-- fixed 90-degree clockwise rotation (applied to LOCAL coordinates,
-- before they ever become a world/Big position -- see the per-tile
-- loop below) that corrects for a real property of Blizzard's own
-- WMO-minimap-tile baking convention (see gotchas.md) -- the
-- rendering side (TerrainWorldMap.lua) does NOT need to apply any
-- extra rotation of its own, only the matching texture-content
-- rotation (TWM_ArenaWMO_EnsureTextures' SetTexCoord). Entries are
-- emitted in ascending height order (lowest first) so the addon's
-- own draw order stacks higher tiles visually on top, and so the
-- height-cutoff slider (TerrainWorldMap.lua) has a stable order to
-- hide from the top down.

Twm_ArenaWMOTiles = {
    ["DalaranArena"] = {
        {248002, 1066.2340265909843, 938.2340265909843, 1384.572687784832, 1256.572687784832, 20.614027976989746},
        {312454, 938.2340265909843, 810.2340265909843, 1384.572687784832, 1256.572687784832, 20.614027976989746},
        {312455, 1066.2340265909843, 938.2340265909843, 1256.572687784832, 1128.572687784832, 20.614027976989746},
        {312456, 938.2340265909843, 810.2340265909843, 1256.572687784832, 1128.572687784832, 20.614027976989746},
        {248003, 1044.6588541666679, 916.6588541666679, 1332.5137106577567, 1204.5137106577567, 78.43648624420166},
        {312457, 916.6588541666679, 788.6588541666679, 1332.5137106577567, 1204.5137106577567, 78.43648624420166},
    },
    ["OrgrimmarArena"] = {
        {4912599, -26.82161458333212, -154.82161458333212, 944.3598276774101, 816.3598276774101, 59.68450355529785},
        {4912601, -26.82161458333212, -154.82161458333212, 816.3598276774101, 688.3598276774101, 59.68450355529785},
        {4912603, -26.82161458333212, -154.82161458333212, 688.3598276774101, 560.3598276774101, 59.68450355529785},
        {4912605, -154.82161458333212, -282.8216145833321, 944.3598276774101, 816.3598276774101, 59.68450355529785},
        {4912607, -154.82161458333212, -282.8216145833321, 816.3598276774101, 688.3598276774101, 59.68450355529785},
        {4912609, -154.82161458333212, -282.8216145833321, 688.3598276774101, 560.3598276774101, 59.68450355529785},
    },
}
