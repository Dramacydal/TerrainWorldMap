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
dungeon/raid entrances → flight masters + routes).

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
dungeons/raids, flight masters, live players) is a **"set"**: a small Lua table registered
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

## Flight paths (`FlightPaths.lua`, `TaxiRoutes.lua`) — the one thing that isn't a point icon

Flight master markers themselves are a normal set (`sets/flightmasters.lua`,
icon `Icon-Taxi-<Faction>`), but the routes *between* them are line
segments, not icons — `TWMPoints_AddPoint` only ever places a single
fixed-size icon at one `(x,y)`, so this needed its own small rendering
primitive instead of fitting into the point-set system:

- **`TaxiRoutes.lua`** runs once at load time, joining the generated raw
  `Twm_flightmasters`/`Twm_taxipaths` (see `scripts/README.md`'s step 7 —
  deliberately undeduped/uncategorized at generation time) into three lookup
  tables: `Twm_TaxiNodeInfo[nodeID]` (position/faction/continent),
  `Twm_TaxiNeighbors[nodeID]` (deduped adjacency list, for hover-preview),
  and `Twm_TaxiRoutesByContinent[continent]` (deduped straight-line segments
  for the "always show" mode).
- **`FlightPaths.lua`** draws those segments as rotated, stretched
  `Texture`s (`Texture:SetRotation`) from its own small texture pool —
  same acquire/hide-unused pooling pattern as `WorldMapOverlay.lua`'s tile
  textures, just for lines instead of tiles. `TWM_FlightPaths_OnPointsUpdate`
  is called from the tail end of `Points.lua`'s `TWMPoints_Update` (an
  optional hook, only invoked if this file happens to be loaded), so lines
  redraw on the exact same pan/zoom/force-update cadence as every point icon,
  using the same Big→Mini→pixel-offset math as `TWMP_SetOffset`.
- Two mutually-exclusive display modes, both reading `TWMOption.ShowFlightPaths`:
  **on** draws every same-continent route in `Twm_TaxiRoutesByContinent`
  unconditionally; **off** (default) draws only `Twm_TaxiNeighbors` of
  whichever flight master is currently hovered (`TWM_HoveredTaxiNodeID`).
  That global is set/cleared from `Points.lua`'s
  `TWMFrameViewFrame_UpdatePointTooltip` — the same per-tick `MouseIsOver`
  loop that already drives the custom tooltip — right where it detects a
  `"flightmasters"` point entering/leaving hover, then calls
  `TWM_FlightPaths_Refresh()` (redraws just the lines, using
  `TWMPoints_GetCurrentView()`'s last-known view state, without forcing a
  full point recompute).
- `TWM_IsFlightmasterVisible(faction)` (`FlightPaths.lua`) is the single
  source of truth for "should this faction's flight masters be shown right
  now" (Neutral, or matches the player's own faction, or `TWMOption.ShowEnemyFlightmasters`
  is on) — both `sets/flightmasters.lua` (whether to place the marker at
  all) and `FlightPaths.lua` (whether to draw a route to/from that marker,
  in both display modes) call it. A line was originally only checked
  against `TWMOption.ShowFlightPaths`, not faction visibility, so a hovered
  or "always show" route could point at a marker that wasn't actually drawn
  — fixed by having `Twm_TaxiRoutesByContinent` carry each segment's two
  endpoint node IDs (not just their coordinates) specifically so
  `FlightPaths.lua` can re-check both endpoints' visibility at draw time,
  since `ShowEnemyFlightmasters` can change at runtime after `TaxiRoutes.lua`
  already built that table.

## The custom tooltip (`TWMTooltip`)

Not the Blizzard `GameTooltip` — a fully custom frame
(`TWMTooltipTemplate`, `TerrainWorldMap.lua`) with its own pooled "line"
button rows. It follows the cursor (`Points.lua`'s
`TWMFrameViewFrame_UpdatePointTooltip`, repositioned every tick while any
point is hovered) instead of a fixed XML anchor. Its row buttons must never
call `EnableMouse(true)` (see gotchas.md) — they have no interaction of
their own and doing so silently swallows clicks meant for whatever is under
the tooltip (e.g. a map-drag).
