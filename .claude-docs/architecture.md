---
tags: [memory/repo, architecture]
---

# Architecture

## Two halves: offline generation (`scripts/`) vs runtime addon

`scripts/*.js`/`.ps1` never ship to players — the WoW addon loader ignores
non-`.lua`/`.xml` files, and they aren't listed in any `.toc`. They're a
separate, standalone Node.js/PowerShell pipeline you run by hand (or in CI)
to regenerate the `Data_<Flavor>/mapdata_*.lua` files, which are the actual
runtime data the addon loads. See `scripts/README.md` for the full pipeline
(fetch client data → zone boxes → tile validity → POI areas → graveyards →
dungeon/raid entrances).

## Coordinate systems

- **World coordinates**: raw game engine X/Y, what DB2 tables like
  `AreaTrigger.Pos_0/Pos_1` store directly.
- **"Big" coordinates**: this addon's own system, `Big-X = world-Y`,
  `Big-Y = world-X`, no offset/scale (see `gen_mapareas.js`'s header
  comment). All `Data_<Flavor>/mapdata_*.lua` data is in Big coordinates.
- **"Mini" coordinates**: the on-screen minimap-style rendering coordinate
  used by `TWM_Big2Mini_Coord`/`TWM_Mini2Big_Coord` (`TerrainWorldMap.lua`).
  Every `set.getpoints` converts Big → Mini right before calling
  `TWMPoints_AddPoint`.
- **Zone-relative percentages** (0-100): used by external sources this addon
  borrows from (Wowhead's `g_mapperData`) — converted to Big via
  `bigX = x1 - (x/100)*(x1-x2)`, `bigY = y1 - (y/100)*(y1-y2)` against a
  zone's own `Twm_mapareas` box `{x1, x2, y1, y2}` = `{maxX, minX, maxY, minY}`.

## The point-set system (`Points.lua` + `sets/*.lua`)

Every category of map marker (landmarks/sub-areas, graveyards, capitals,
dungeons/raids, live players) is a **"set"**: a small Lua table registered
via `TWMPoints_RegisterSet(set)`, loaded via `sets/index.xml`. A set
implements some subset of:

- `set.getpoints(name, map)` — called once per map change; reads a
  `Twm_*` global table for the current `map` (continent name) and calls
  `TWMPoints_AddPoint(frame, setname, name, x, y, options, userdat)` for each
  marker. `userdat` is a free-form table for anything the set's own
  `setuppoint` needs (e.g. `sets/dungeons.lua` stashes `{type}` there to pick
  `Icon-Dungeon` vs `Icon-Raid`).
- `set.setuppoint(point, env, dat)` — called whenever a point becomes visible
  in the current viewport; sets the icon texture/size/color. Icons should
  always call `SetVertexColor` explicitly even with no real tint (see
  gotchas.md) — the underlying frame is pooled/reused across different
  point types.
- `set.setuplegend(point, env, dat)` — same as `setuppoint` but also shows
  the text label, for the "Show Points" legend/tooltip.
- `set.configmenu(name, lm)` — adds this set's on/off checkbox to the
  in-frame dropdown menu (`TWMFOO` button, bottom-right of the map view).
  Every set that defines this gets the toggle "for free" — no need to touch
  `Points.lua` itself.
- `set.getmobilepoints(name)` / `set.OnUpdate` — only `sets/players.lua`
  uses these, for live-tracked units (player/party/raid) instead of static
  map data.

Visibility of a static point is controlled by `TWMOption.Frames[lm].PointCfg[setname]`
(`true` = hidden, absence = shown — i.e. **shown by default**). The in-frame
dropdown and the `Settings.lua` "Browser" tab checkboxes both just flip this
same table entry and call `TWMPoints_ForceUpdate(TWMFrame)`.

**Adding a new marker category**: copy `sets/capitals.lua` or
`sets/dungeons.lua` as a template, register it in `sets/index.xml`, add a
`TWM_POINTS_<NAME>`/`TWM_OPTIONS_SHOW_<NAME>` locale string per
`Locale/TerrainWorldMap-*.lua`, and (if it should also live in
`Settings.lua`'s Browser tab, not just the in-frame dropdown) add a
`CreateCheckbox` block there bound to `PointCfg["<name>"]`.

## Live name resolution — don't bake locale into generated data

`Data_<Flavor>/mapdata_poi_areas.lua`/`mapdata_poi_instances.lua` are
generated once (usually from an `enUS` DB2/Wowhead export) and store a name
string as a **fallback only**. At render time:

- `sets/landmarks.lua`/`sets/capitals.lua` resolve the real label via
  `Twm_areadb[areaID]` (`mapdata_zones.lua`'s `C_Map.GetAreaInfo`-backed
  cache table) — falls back to the baked name if the AreaID doesn't resolve
  on this build.
- `sets/dungeons.lua` resolves via `GetRealZoneText(mapID)` — confirmed this
  global accepts the same `Map.ID` used as `target_map` in
  `gen_poi_instances.js` (e.g. `GetRealZoneText(530) == "Outland"`, `530` =
  `Map.ID` for `Expansion01`).

This means Landmarks/Capitals/Dungeons all display in whatever locale the
*player's own client* is running, regardless of what locale the data was
generated in. Graveyards have no per-point name at all (just the generic
localized `TWM_POINTS_GRAVEYARDS` string), so there's nothing to resolve.

## The custom tooltip (`TWMTooltip`)

Not the Blizzard `GameTooltip` — a fully custom frame
(`TWMTooltipTemplate`, `TerrainWorldMap.lua`) with its own pooled "line"
button rows. It follows the cursor (`Points.lua`'s
`TWMFrameViewFrame_UpdatePointTooltip`, repositioned every tick while any
point is hovered) instead of a fixed XML anchor. Its row buttons must never
call `EnableMouse(true)` (see gotchas.md) — they have no interaction of
their own and doing so silently swallows clicks meant for whatever is under
the tooltip (e.g. a map-drag).
