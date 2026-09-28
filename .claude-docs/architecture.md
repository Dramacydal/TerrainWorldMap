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

**Flight masters and arenas are the exception** — neither has an
AreaID/MapID (flight masters) or a live uiMapID (arenas) for anything like
`Twm_areadb`/`GetRealZoneText`/`C_Map.GetMapInfo` to resolve, so their
generators (`scripts/gen_poi_flightmasters.js`, `scripts/gen_arenas.js`)
bake in every supported client locale's name at generation time instead
(`Twm_flightmasters[continent][n].name` / `Twm_ArenaNames[n].name`, keyed by
locale — fetched once per locale from `TaxiNodes.db2` / `Map.db2`, see
`scripts/README.md`'s steps 7 and 9). `TaxiRoutes.lua`'s
`TWM_ResolveLocaleName` (a generic `{locale: name}` resolver despite living
in that file) picks the current client's own locale out of that table once,
at load time, falling back to `enUS` if that locale's data is missing (or
for `enGB`/`ptPT` clients, aliased to `enUS`/`ptBR` since wago.tools doesn't
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

**Curve smoothing** (`Spline.lua`): the WoW UI API has no native curve/spline
primitive at all -- `Frame:CreateLine` only draws straight segments (same as
Blizzard's own talent-tree connectors), and there's no known community
library for this either. `TWM_CatmullRomInterpolate(points, maxExtraPerSegment)`
is this addon's own tiny Catmull-Rom implementation, adding extra calculated
points between each pair of `Twm_taxipathnodes` points before `DrawRoute`
turns them into `Line` segments -- purely cosmetic smoothing on top of the
already-real curved data, not a replacement for it. How many extra points a
given segment gets scales with that segment's own length relative to the
longest segment in the same path (`TWMOption.FlightPathInterpolation`,
Settings.lua slider, only caps the longest one), so a long open-world leg
gets proportionally more subdivision than a short hop near a hub instead of
both getting the same flat count. **Deliberately hover-preview-only** --
`DrawRoute`'s `allowInterpolation` parameter is `true` only for the
currently-hovered flight master's own routes (at most a handful), and
always `false` for "Toggle Flight Paths"' full-continent view (which can
already be hundreds of routes) -- since more points per route means more
`Line` children on the shared world frame, and that's precisely the cost
that already makes Shift-curved "always show" laggy (see below).

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

## Arenas — no `UiMapAssignment` at all, and the WMO minimap-tile overlay

Arena maps (`Map.csv` `InstanceType=4`, `dbc_enums.js`'s `INSTANCE_TYPE_ARENA`)
have **zero `UiMapAssignment` rows** on every checked flavor — no box, no
`UiMapID`, no `C_Map.GetPlayerMapPosition`/`GetMapInfo` at all, unlike
continents/battlegrounds/dungeons. `scripts/gen_arenas.js` derives each
arena's `Twm_mapareas` box from its own WDT valid-tile extent
(`Twm_WDTValidTiles`, already generated by `gen_tiles.js`) instead of any
DB2 row, and there is no `Twm_ArenaMapID` table — arenas are display-only
(`TWM_ARENAS`, built at load from `Twm_ArenaNames`), never position-tracked.

**"Show WMO Layers" overlay** (`TWM_ArenaWMO_Update`/`TWM_ArenaWMO_EnsureTextures`,
`TerrainWorldMap.lua`; data in `Twm_ArenaWMOTiles`,
`Data_<Flavor>/mapdata_arena_wmo_tiles.lua`, generated by
`scripts/gen_arena_wmo_tiles.js`): a few arenas (Dalaran Sewers, Orgrimmar)
have real ADT terrain but no baked minimap art for it at all — the only real
minimap art there is the placed WMO building's own baked group-minimap
tiles (this can be true even for arenas whose outdoor terrain DOES have its
own real minimap art too, e.g. Orgrimmar Arena — the two aren't mutually
exclusive, and both are generated independently; see `gen_arena_wmo_tiles.js`
in `scripts/README.md`). `Twm_ArenaWMOTiles[key]` is a plain array of
`{fileID, xMax, xMin, yMax, yMin, height}` boxes (same box convention as
`Twm_mapareas`), one per WMO group tile, **emitted in ascending-height
order** (`height` = `MODF.position[1]` of that tile's own WMO placement
PLUS that specific tile's own WMO GROUP's height-axis center — tracked per
group, not just per placement, since one placement's groups can be at
meaningfully different real heights, e.g. a raised walkway over the main
floor).

Rendered as a small pooled set of plain `Texture`s (`SetTexture(fileID)`
directly — raw `FileDataID`, no path string), children of
`<frame>ViewFrame` (so they're clipped/panned exactly like the base map
tiles and point icons are), positioned with the same mini-coordinate
formula `Points.lua`'s `TWMP_SetOffset` uses for icons: for a mini-coord
point `(mx,my)`, pixel offset from the viewframe's TOPLEFT is
`((mx-Lx)*z, (Ly-my)*z)` where `(Lx,Ly) = frame.opt.Location` and
`z = frame:GetZoom()`. Refreshed from the same hook `TWMPoints_OnMove` uses
(`TWMFrameTemplate:SetLocation`), so it pans/zooms in sync automatically —
no separate per-tick driver needed. **Stacking order**: draw order among
multiple textures sharing the same layer AND sublevel is undefined in
WoW's UI engine (not creation-order guaranteed, despite that being a
common assumption — confirmed via community reports, see gotchas.md), so
each tile's sublevel is set explicitly
(`Texture:SetDrawLayer("OVERLAY", sublevel)`) from its rank in the
already-height-sorted list, clamped to the `[-8,7]` range.

Coordinate derivation (see gotchas.md's "WMO-tile world position" entry for
the full formula, the reference implementation used, and the reusable
lessons behind it): `box[0]`/`box[1]` (a WMO group's own MOGP bounding box)
pair directly with `blockX`/`blockY`, no swap; local Y gets one flip shared
across the whole placement (never per-group), anchored onto the TRUE,
continuous group geometry (`trueGlobalMinY`/`trueGlobalMaxY` — each
involved group's own real `box.min[1]`/`box.max[1]`, not a block-quantized
approximation of it — a block-quantized reference is off by a real,
measured amount whenever a group's geometry doesn't exactly fill a whole
number of 128-unit blocks, e.g. ~14 units for Orgrimmar); local coordinates
then get a fixed 90°-clockwise rotation
(`(localX,localY)->(-localY,localX)`, correcting for a real property of
Blizzard's own WMO-minimap-tile baking convention — also true for WMO
dungeon interiors); `World = MODF.position + local` (plain addition); then
the usual `Big = MAP_ORIGIN - World`, no cross-swap. All of this lives in
`gen_arena_wmo_tiles.js` — `TerrainWorldMap.lua`'s `TWM_ArenaWMO_Update`
itself has no rotation/flip logic at all, it just reads the already-correct
Big coordinates the same direct way the base map tiles do. The one thing
that DOES still live in Lua is the matching texture-CONTENT rotation
(`TWM_ArenaWMO_EnsureTextures`' `SetTexCoord(0,1, 1,1, 0,0, 1,0)`, the
8-param form, for the same 90° reason) — a separate concern (what each
tile's own pixels show, not where its box goes).

The checkbox itself (`TWMFrameShowArenaWMOButton`, top-right of the view,
default checked — `TWM_FRAME_OPTION_DEFAULTS.ShowArenaWMOLayers`) is
shown/hidden per-map from `TWMFrameTemplate:SetMap`
(`TWM_UpdateArenaWMOButton`), based solely on whether
`Twm_ArenaWMOTiles[map]` exists — most maps never have this data. When an
arena's placements span more than one distinct height, the same function
also shows a vertical height-cutoff `Slider`
(`TWMFrameArenaWMOHeightSlider`, lazily created in Lua via
`TWM_ArenaWMO_EnsureHeightSlider` — no XML needed, its range is per-arena)
anchored below the checkbox, reset to "show everything" on every map
change. `frame.arenaWMOHeightCutoff` (runtime-only, not persisted — an
absolute height from one arena means nothing on another) hides any tile
whose own placement height exceeds the slider's current value, letting a
multi-level arena's upper layer be peeled back in `TWM_ArenaWMO_Update`.

The Big-coordinate transform for a WMO placement (from its ADT `_obj0.adt`
MODF entry) is `BigX = MAP_ORIGIN - MODF.position[2]`,
`BigY = MAP_ORIGIN - MODF.position[0]` (`MAP_ORIGIN = 32*(1600/3)`,
`position` is world-space X/height/Y). `gen_arena_wmo_tiles.js` only emits
tiles for placements whose rotation magnitude is `<= 0.05` degrees (skips,
with a console warning, anything else) — the rotation (yaw) transform is
not implemented, so any arena whose minimap-bearing WMO is actually rotated
(e.g. Tol'Viron Arena, Ring of Valor) currently gets zero WMO tiles instead
of misplaced ones.

## The custom tooltip (`TWMTooltip`)

Not the Blizzard `GameTooltip` — a fully custom frame
(`TWMTooltipTemplate`, `TerrainWorldMap.lua`) with its own pooled "line"
button rows. It follows the cursor (`Points.lua`'s
`TWMFrameViewFrame_UpdatePointTooltip`, repositioned every tick while any
point is hovered) instead of a fixed XML anchor. Its row buttons must never
call `EnableMouse(true)` (see gotchas.md) — they have no interaction of
their own and doing so silently swallows clicks meant for whatever is under
the tooltip (e.g. a map-drag).
