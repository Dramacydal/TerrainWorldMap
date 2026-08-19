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

**Flight masters are the one exception** — a flight master has no
AreaID/MapID of its own for anything like `Twm_areadb`/`GetRealZoneText` to
resolve, so `scripts/gen_poi_flightmasters.js` bakes in every supported
client locale's name at generation time instead (`Twm_flightmasters[continent][n].name`,
keyed by locale — fetched once per locale from `TaxiNodes.db2`, see
`scripts/README.md`'s step 7). `TaxiRoutes.lua`'s `TWM_ResolveFlightMasterName`
picks the current client's own locale out of that table once, at load time,
falling back to `enUS` if that locale's data is missing (or for
`enGB`/`ptPT` clients, aliased to `enUS`/`ptBR` since wago.tools doesn't
export those separately).

## Flight paths (`FlightPaths.lua`, `TaxiRoutes.lua`) — the one thing that isn't a point icon

Flight master markers themselves are a normal set (`sets/flightmasters.lua`,
icon `Icon-Taxi-<Faction>`), but the routes *between* them are line
segments, not icons — `TWMPoints_AddPoint` only ever places a single
fixed-size icon at one `(x,y)`, so this needed its own small rendering
primitive instead of fitting into the point-set system.

**Data**: `scripts/gen_poi_flightmasters.js` (step 7 of the generation
pipeline, see `scripts/README.md`) produces three tables per flavor into
`Data_<Flavor>/mapdata_poi_flightmasters.lua` — `Twm_flightmasters[continent]`
(marker position + faction, TaxiNode ID first), `Twm_taxipaths` (raw
`TaxiPath.db2` rows, deliberately undeduped/uncategorized), and
`Twm_taxipathnodes[pathID]` (the real curved route as `TaxiPathNode.db2`'s
spline points, ordered by `NodeIndex`). `TaxiRoutes.lua` runs once at load
time and joins these into the tables everything else actually reads:
`Twm_TaxiNodeInfo[nodeID]` (position/faction/continent),
`Twm_TaxiNeighbors[nodeID]` (deduped adjacency list, for hover-preview),
`Twm_TaxiRoutesByContinent[continent]` (deduped straight-line segments —
each entry keeps both endpoints' node IDs, not just coordinates, for
`TWM_IsFlightmasterVisible` re-checks below), and `Twm_TaxiPathIDByPair`
(exact directed node-pair → `TaxiPath.ID`, used to look up that pair's
`Twm_taxipathnodes` entry).

**Rendering** (`FlightPaths.lua`): each segment is drawn as a pair of
`Frame:CreateLine` `Line` objects (the same native UI object Blizzard's own
talent tree connectors use) — a thicker black outline underneath, a
thinner white line on top, faking an outline `Line` has no built-in border
for. Position is **not** recomputed per-line on every pan/zoom tick like
tiles/point icons are: every line is anchored once, in Big/Mini-derived
local units, to a single shared "world" frame (`GetWorldFrame`) parented to
the ViewFrame; panning/zooming only repositions/rescales that ONE frame
(`SetPoint` + `SetScale`, O(1) regardless of line count) and WoW's anchor
system carries every line along for free. This only works for lines
specifically — there are at most a few hundred of them — unlike the tile
grid or point-icon system, which pool/reuse a small fixed set of
objects specifically to avoid ever having a whole continent's worth of them
alive at once; that pooling approach doesn't fit the "reposition one
parent" trick, since a pooled object's *identity* (which point/tile it
represents) changes every pan.

Two costs that don't come for free with this trick:
- `SetThickness` is also in the world frame's local units, so it'd get
  scaled by the same `SetScale` and render thicker/thinner with zoom —
  countered by re-setting every active line's thickness to `PX / z`, but
  only when `z` actually changed (`lastZoom` check) — a pure pan doesn't
  touch it, only a zoom does. `TWMOption.FlightPathThickness` (Settings.lua
  slider, Browser tab) picks the on-screen `PX`.
- Rebuilding *which* lines exist (as opposed to just repositioning the
  existing ones) is still `O(n)` — gated behind a `lastSignature` string
  (map + display mode + faction-visibility options + hovered node + Shift
  state) so it only runs when something that actually changes the line SET
  changed, not on every pan/zoom tick.

**Display modes**, both reading `TWMOption.ShowFlightPaths`: **on** draws
every same-continent route in `Twm_TaxiRoutesByContinent` unconditionally;
**off** (default) draws only `Twm_TaxiNeighbors` of whichever flight master
is currently hovered (`TWM_HoveredTaxiNodeID`, set/cleared from `Points.lua`'s
`TWMFrameViewFrame_UpdatePointTooltip` — the same per-tick `MouseIsOver` loop
that drives the custom tooltip — right where it detects a `"flightmasters"`
point entering/leaving hover, then calls `TWM_FlightPaths_Refresh()` to
redraw just the lines using `TWMPoints_GetCurrentView()`'s last-known view
state, without forcing a full point recompute).

**Straight vs. curved**: every route draws as a straight line by default;
holding **Shift** switches it to the real curved `Twm_taxipathnodes` spline
instead (`TWMFrameViewTemplate`'s `OnUpdate`, Templates.xml, polls
`IsShiftKeyDown()` every tick via `TWM_FlightPaths_PollShiftKey` and forces a
rebuild the instant it changes). Deliberately not the always-on default —
a route can expand into dozens of spline segments, and the world frame's
per-tick reposition/rescale costs the client proportionally more the more
`Line` children it has (see `.claude-docs/gotchas.md`), so curving every
route all the time visibly lags dragging with "always show" on; as an
on-demand glance it's fine.

`TWM_IsFlightmasterVisible(faction)` (`FlightPaths.lua`) is the single
source of truth for "should this faction's flight masters be shown right
now" (Neutral, or matches the player's own faction, or
`TWMOption.ShowEnemyFlightmasters` is on) — both `sets/flightmasters.lua`
(whether to place the marker at all) and `FlightPaths.lua` (whether to draw
a route to/from that marker) call it.

Flight master icons always draw above every other marker type
(`sets/flightmasters.lua`'s `setuppoint` bumps its pooled frame's level to
parent + 8, vs. the shared parent + 4 baseline every other set gets at
creation) — `Points.lua`'s `TWMP_Clear` resets that back to the baseline
every time a pooled frame is cleared, so the raised level doesn't stick once
that same physical frame gets recycled for some other, non-elevated point
type on a later redraw.

## The custom tooltip (`TWMTooltip`)

Not the Blizzard `GameTooltip` — a fully custom frame
(`TWMTooltipTemplate`, `TerrainWorldMap.lua`) with its own pooled "line"
button rows. It follows the cursor (`Points.lua`'s
`TWMFrameViewFrame_UpdatePointTooltip`, repositioned every tick while any
point is hovered) instead of a fixed XML anchor. Its row buttons must never
call `EnableMouse(true)` (see gotchas.md) — they have no interaction of
their own and doing so silently swallows clicks meant for whatever is under
the tooltip (e.g. a map-drag).
