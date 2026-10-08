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
  in-frame dropdown menu (gear button in the control strip: its menu is "Options" plus one checkbox per point set, `TWM_ShowOptionsMenu`, Points.lua).
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
`Settings.lua`'s Browser tab, not just the in-frame dropdown) add an
`AddMarkerCheckbox("<name>", ...)` call there (bound to `PointCfg["<name>"]`).

All three settings tabs (main, World Map, Browser) are native vertical-layout
Settings categories built by `CreateTab` in `Settings.lua` (Blizzard lays them
out and scrolls them). Each option is a proxy setting (`AddCheckbox`/`AddSlider`/
`AddDropdown`, getter/setter over `TWMOption`); the Browser tab has four groups
(Window, Map Markers, Flight Paths, Extras). The panel's global "Defaults"
button, which offers to reset all game settings, is hidden for these tabs
(`hooksecurefunc` on `SettingsPanel.DisplayCategory`); the Browser tab has its
own reset button.

**Follow mode** (Goto Player toggled on, view on a continent; `TWMFrameTemplate:FollowTick`
in `TerrainWorldMap.lua`): every 1/30s the view is re-centered on the unit.
Tiles go through the normal `SetLocation`. Icons are anchored to `vf.panAnchor`
(`GetPanAnchor`, `Points.lua`), not to the ViewFrame itself, so a small view
move is one `SetPoint` on the anchor (`TWMPoints_Pan`) instead of a full
`TWMPoints_Update`. The full layout reruns when the view drifts more than
`FOLLOW_REFRESH_PX` from the last layout, and it culls with a
`FOLLOW_MARGIN_PX` border so nothing pops in at the edges meanwhile. Zoom/resize
pass `forceupdate`, which always takes the full layout (the pan anchor is only
valid for the zoom it was laid out at). The unit's own marker is updated in
the follow tick (the 0.5s `players` set update would visibly lag); the zone
dropdown refreshes once a second. Dragging the map cancels tracking. The same pan shortcut is used while the map is being
dragged with the mouse (`UsesPanning` in `Points.lua`: follow mode or `ViewFrame.dragme`); when the drag ends
`TWMFrame_RelayoutPoints` does one full icon layout at the final position.

**Tile grid cost while panning** (`SetLocation`): a tile (col, row) always lives in pooled texture
`(col % wzoom_real, row % hzoom_real)`, so crossing a tile border re-textures only the entering column/row (`tex.twmPath`
tracks what a texture shows; `TWM_GetCachedTilePath` caches tile -> texture per map, cleared by `TWM_RefreshFrameTiles`).
Only the first and last slot per axis are cropped; the whole-tile slots in between are anchored to `self.tileAnchor` (moved
by one `SetPoint` per pan) and re-anchored only when their slot number or the zoom changes (`twmInner/twmK/twmJ`). `SetZoom`
resets this per-texture bookkeeping. `/twm debug` uses the plain slot order and the old per-tile passes. The WMO overlay has
the same shortcut (`TWM_WMOOverlay_Pan`).
Non-continent maps keep the old "re-center when the unit leaves the view" logic
in `OnWorldMapUpdateU`. Inside a dungeon/raid/scenario that is in our lists (`TWM_GetPlayerInstanceMap`: `GetInstanceInfo()`'s
instanceID against the lists' `.mapID`) Goto Player only switches to that instance's map (`SelectMap`), no positioning; this
is checked before the continent lookup because `C_Map`'s parent walk can return the outdoor continent for an instance.
Clicking a dungeon/raid entrance marker on a continent opens that instance's map: `Points.lua` calls a set's optional
`onclick(dat, frame)` on a left click that moved less than 4 screen pixels (`TWMP_EnableDragThrough`); `sets/dungeons.lua`'s
`onclick` -> `TWM_OpenPortalTarget` (target Map.csv ID -> list key, hidden/dev maps are not opened; else the outdoor
continent by Directory; then `CenterOnBig` on the arrival point). The same markers exist INSIDE dungeon/raid maps (exits,
links such as Blackrock Depths -> Molten Core, Blackrock Spire -> Blackwing Lair): `Twm_instances[<map key>]` entries are
`{kind, target MapID, name, x, y [, target Directory, tx, ty]}`, kind "Exit" = to an outdoor map. Generated by
`gen_poi_instances.js`; trigger and teleport coordinates are world coordinates (X north, Y west) and every marker uses
Big = (world Y, world X), continents and instance maps alike. The tiles of the WMO-only instance maps (no ADT; the root WMO
is the global placement (0,0,0) in the WDT) are NOT in that system today (they sit around (O - X, O - Y), O = MAP_ORIGIN),
so markers on those maps are off by the offset of the root WMO until `gen_wmo_tiles.js` places them in world coordinates.

**Frame chrome** (`TerrainWorldMap.xml`): no title/portrait. `TWMFrameViewFrame` fills the frame with a 4px inset (flat 1px
backdrop border from `TWMFrame_OnLoadExtra`). Controls (two dropdowns, Goto Player, Settings, Lock, Close) live in
`TWMFrameHeader`, a 32px strip overlaid on the top of the map (frame level above `TWM_WMO_FRAME_BAND`); it is also the drag
handle for moving the frame (forwards to `TWMFrame`'s own `OnDragStart/OnDragStop`) and forwards the mouse wheel to zoom. The
`TWMFrameFooter` is the mirror strip along the bottom (same look, drag handle, wheel zoom): it holds the zoom-popup
button, the Show Terrain / Show WMO Layers checkboxes (placed after the zoom button by `TWM_LayoutFooterChecks`: each
visible one follows the previous visible one, so a hidden one leaves no gap) and the WMO height-cutoff slider (anchored to
its right end, left of the resize grip; its name is a hover tooltip). The WMO group list hangs from the ViewFrame's
top-right below the header. The resize grip is offset to stay clear of the strips.

**Narrow window** (`TWM_LayoutHeader`, run on every size change): the header is one row (35px, `TWMFrameHeaderRow` centers the
icon, first dropdown and right-hand buttons on it) while everything fits. Narrower: both dropdowns shrink to
`TWM_HEADER_DROPDOWN_MIN_WIDTH`; narrower still: the second dropdown (and Goto Player, anchored to it) moves to a second
row (header height 61) and both dropdowns get their full width back, shrinking again as the window narrows. The left/right extents of the first row are measured from the real frames. The resize
bounds follow what is visible (`TWM_UpdateMinSize`: header minimum, plus the footer's checkboxes/slider widths, floored by
`TWM_FRAME_MIN_WIDTH`/`TWM_FRAME_MIN_HEIGHT`), so nothing overlaps; the window is widened if a map change makes the
footer need more room.

**The two header dropdowns** (`TerrainWorldMap.lua`; Blizzard_Menu `DropdownButton`s, see gotchas.md): the left one is a category tree (Continents / Dungeons > expansion /
Raids / Scenarios / Battlegrounds / Arenas). For a continent the right one lists its zones (`zonepulldowns`) and shows the
zone under the view center (`UpdateDropDown2`). For any other map `TWM_GetMapGroup(map)` (set in `SetMap` as
`frame.mapGroupText`/`frame.mapGroup`) makes the left one read "Dungeons: Vanilla" (just "Dungeons" when the flavor has
one expansion) and the right one list that group's maps; picking one calls `TWM_PickMap` (`SelectMap`; the menu closes itself).
`UpdateDropDown2` runs from `SetLocation` AFTER `opt.Location` is stored (it reads it).

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
creation; both plus `TWM_WMO_FRAME_BAND`, see the WMO overlay section) — `Points.lua`'s `TWMP_Clear` resets that back to the baseline
every time a pooled frame is cleared, so the raised level doesn't stick once
that same physical frame gets recycled for some other, non-elevated point
type on a later redraw.

## Arenas — no `UiMapAssignment` at all, and the WMO minimap-tile overlay

Arena maps (`Map.csv` `InstanceType=4`, `dbc_enums.js`'s `INSTANCE_TYPE_ARENA`)
have **zero `UiMapAssignment` rows** on every checked flavor — no box, no
`UiMapID`, no `C_Map.GetPlayerMapPosition`/`GetMapInfo` at all, unlike
continents/battlegrounds/dungeons. `scripts/gen_arenas.js` derives each
arena's `Twm_mapareas` box from its own WDT valid-tile extent
(`Twm_WDTValidTiles`, already generated by `parse_wdt.js`) instead of any
DB2 row, and there is no `Twm_ArenaMapID` table — arenas are display-only
(`TWM_ARENAS`, built at load from `Twm_ArenaNames`), never position-tracked.

**WMO minimap-tile overlay** (`TWM_WMOOverlay_Update`, `TerrainWorldMap.lua`;
data in `Twm_WMOTiles`, `Data_<Flavor>/mapdata_wmo_tiles_{dungeons,raids,arenas}.lua`,
generated by `scripts/gen_wmo_tiles.js`). Used by arenas, dungeons and raids.
Some maps have real ADT terrain but no baked minimap art for it (Dalaran
Sewers), pure-WMO instances have no terrain at all; the only real minimap art
is the placed WMO's own baked group tiles. A map can have both (Orgrimmar
Arena) — they are generated independently.

`Twm_WMOTiles[map]` is an array of groups,
`{group_id = "<WMOID>-<GroupNum>", group_name, tiles = {...}}`; each tile is
`{fileID, cx, cy, width, height, yawDeg, z, c1x,c1y, c2x,c2y, c3x,c3y, c4x,c4y}`
(Big coordinates; `z` = placement `MODF.position[1]` + the group's lowest
bbox Z, the same key wow.export orders by; the corners are the real, possibly
rotated outline). Tiles are plain `Texture`s (`SetTexture(fileID)`, raw
FileDataID), anchored to `<frame>ViewFrame` (clipped/panned like the base
tiles and point icons), positioned with the mini-coordinate formula
`Points.lua`'s `TWMP_SetOffset` uses: for a mini-coord point `(mx,my)` the
offset from the viewframe's TOPLEFT is `((mx-Lx)*z, (Ly-my)*z)`, with
`(Lx,Ly) = frame.opt.Location` and `z = frame:GetZoom()`. Refreshed from the
same hook `TWMPoints_OnMove` uses (`TWMFrameTemplate:SetLocation`).

**Stacking order.** Groups overlap heavily (real dungeons stack 30+ of them),
and a texture only has 16 draw sublevels, so ordering by sublevel is not
possible. Instead every enabled group is ranked by `z` ascending (ties keep
data order) and gets its own child frame of ViewFrame with frame level
`ViewFrame + 1 + rank`; its tiles are that frame's textures (tiles of one
group never overlap). Frame levels are global within a strata, so everything
else on ViewFrame is lifted above that range by `TWM_WMO_FRAME_BAND`
(`Points.lua`): point markers, flight masters, the flight path frame, and the
zoom/terrain/WMO buttons. The debug borders/labels (`/twm debug`) sit on a
dedicated frame just above the groups. See gotchas.md, "WMO overlay stacking".

**Controls.** The "Show Terrain"/"Show WMO Layers" checkbox pair
(`TWMFrameShowTerrainButton`/`TWMFrameShowWMOOverlayButton`, in the footer strip) appears only for a map that has BOTH ADT terrain and `Twm_WMOTiles`
(`TWM_UpdateOverlayButtons`); a map with only one of them always draws it. When
the tiles span more than one height a horizontal height-cutoff `Slider` is
shown (lazily built, `TWM_WMOOverlay_EnsureHeightSlider`); `frame.wmoOverlayHeightCutoff`
(runtime-only) hides any tile whose `z` is above it. With the "WMO Tile
Management" option (Settings, Browser tab) on, a scrolling dropdown at the view's top-right lets the
user hide single groups (`TWM_EnsureWMOGroupDropdown`, Blizzard_Menu checkboxes): a "Show all" item first
(derived: checked while every group is enabled; click enables all, or disables all when checked), then the groups:
a name shared by several groups is ONE checkbox that is also a submenu (it toggles all of them; checked while all are on;
the submenu has a checkbox per group, labeled by group_id), a name with one group is a plain checkbox. Blizzard_Menu
supports a checkbox with children (it gets the submenu arrow). The choice is runtime-only (`frame.wmoGroupEnabled`) and resets on every map change and when the frame is reopened.

**Coordinates** (full derivation and the reusable lessons in gotchas.md,
"WMO-tile world position"): `local.X = box.min[0] + blockX*128` against the
group's own MOGP bbox (no swap), the model's local Y is mirrored about local
0, local coordinates get a fixed 90° clockwise rotation (a real property of
Blizzard's WMO-minimap baking), and the placement is
`Big = (MAP_ORIGIN - MODF.position[x,z]) + rotateOnly(y, x)` with the yaw
applied (`MAP_ORIGIN = 32*(1600/3)`). All of it lives in `gen_wmo_tiles.js`;
`TWM_WMOOverlay_Update` has no rotation/flip logic beyond `SetRotation` for
the texture itself. The one thing that is Lua-only is the texture-CONTENT
rotation (`TWM_WMOOverlay_EnsureTexture`'s `SetTexCoord(0,1, 1,1, 0,0, 1,0)`,
the 8-param form). Only yaw is supported: a placement with pitch/roll is
skipped by the generator with a warning. A tile whose BLP is not in the
client is skipped too.

**Which maps are listed.** The dungeon/raid/scenario dropdown lists
(`TWM_DUNGEONS`/`TWM_RAIDS`/`TWM_SCENARIOS`, built from
`Twm_DungeonNames`/`Twm_RaidNames`/`Twm_ScenarioNames`) are filtered by
`TWM_IsMapHidden(mapID)`: `Twm_DevelopmentMaps` (`mapdata_development.lua`, all
flavors) are hidden unless the "Show Development Maps" option is on, and
`Twm_SeasonOnlyMaps` (`Data_Vanilla`/`Data_Forever` `mapdata_seasons.lua`) are
shown only while `C_Seasons.GetActiveSeason()` equals the listed season (where
`C_Seasons` does not exist, e.g. Forever, they stay hidden). When only one
expansion is left in a category the expansion submenu level is skipped.

## Capital-city WMO tiles on the world map (`Twm_CityWMOTiles`)

The "Draw tiles on city maps" option has three modes (`TWM_GetCityMapTilesMode`,
saved as `WorldMapOverlayCityMode`; the menus show it as a checkbox -- Off <-> On +
Buildings on click -- with the modes as its submenu, the Settings tab as a dropdown):
Off, On (terrain only), On + Buildings. In the last one, on a capital's world map
(`Twm_CityMapIDs`) `WorldMapOverlay.lua` draws the city's WMO minimap tiles over its terrain
(`DrawCityWMOTiles`: one child frame per WMO group, frame level = rank by height,
tiles positioned/rotated like `TWM_WMOOverlay_Update`'s, mapped to the overlay's
pixels through the zone box like the terrain). Data:
`Data_<Flavor>/mapdata_wmo_tiles_cities.lua`, `Twm_CityWMOTiles[<uiMapID>]`, from
`gen_wmo_tiles.js --city-boxes-file` (see `scripts/README.md`: only the WMOs and
tiles that intersect the city's zone box are unpacked). The standalone window draws
the same tiles on the continent's map: at load, `TerrainWorldMap.lua` merges the
cities' groups into `Twm_WMOTiles[<continent>]` (a list marked `cull`, groups shared
with `Twm_CityWMOTiles`) so the regular `TWM_WMOOverlay_Update` machinery applies.
The terrain stays always on there; "Show WMO Layers" (alone, no Show Terrain) is
offered only while WMO tiles are in view and the footer has room for it
(`TWM_UpdateOverlayChecks`, `frame.wmoInView`/`wmoChecksActive`; the window is not
widened for it, unlike on instance maps). A `cull` list lays out only tiles in
the view (plus `TWM_PAN_MARGIN_PX`) and only from `TWM_WMO_CULL_MIN_ZOOM` up -- a
continent holds ~1000 city tiles/groups, one frame each -- and `TWM_WMOOverlay_Pan`
redoes the layout (and the "tiles in view" check behind the checkbox) once the view
has moved `TWM_PAN_REFRESH_PX`, the same distances as the icons' pan anchor in
`Points.lua`; its group list dropdown and height slider are not offered. A city's WMOs are placed on the
continent (per-ADT MODF, ADT coordinates), unlike a pure-WMO instance.

## The custom tooltip (`TWMTooltip`)

Not the Blizzard `GameTooltip` — a fully custom frame
(`TWMTooltipTemplate`, `TerrainWorldMap.lua`) with its own pooled "line"
button rows. It follows the cursor (`Points.lua`'s
`TWMFrameViewFrame_UpdatePointTooltip`, repositioned every tick while any
point is hovered) instead of a fixed XML anchor. Its row buttons must never
call `EnableMouse(true)` (see gotchas.md) — they have no interaction of
their own and doing so silently swallows clicks meant for whatever is under
the tooltip (e.g. a map-drag).

## Leatrix Maps integration (`integrations/LeatrixMaps.lua`)

Leatrix's dungeon/raid icons on the World Map carry no map ID, only a
localized name, a description and a position on the zone map. A left click
(hooks on `LeaMapsGlobalPinMixin`'s `OnAcquired`/`OnMouseUp`, installed once
the mixin exists, on `PLAYER_ENTERING_WORLD`) looks the instances of
`Twm_instances` up, one per target map, among the instances reachable from the
icon's continent (its own entrance list, then the lists of the instances it
enters, like Blackwing Lair from Blackrock Spire; never through an "Exit", so a
name from another continent, e.g. Coilfang on Outland, does not match an icon
in the Eastern Kingdoms). Only when none of those matches by name, the
selector's maps no entrance marker leads to are tried
(`TWM_LeatrixMarkerlessGroup`: new maps whose entrances are not in the data;
found by name only, opened like the others, never the maps still in
development): used as extra candidates they would join a match already made
(the old Scholomance next to the one the marker leads to). By name, in
tiers (case-insensitive through the game's own `string.lower`, which lowers
Cyrillic too -- unlike plain Lua's, checked in game with `/dump
string.lower("ПРИвет!")`; the icon's name has
color codes -- Leatrix's level color is malformed, `|cffffff 0` -- the level and
"(...)" notes removed): the first tier with a hit wins. The names compared are
`GetRealZoneText` of the Map ID, the name our map selector shows and its
`alias` names (generated: dungeon finder and top-level area names, e.g. "The
Black Morass" for "Opening of the Dark Portal"; see scripts/README.md, Step
11). An icon Leatrix names so that no locale matches ours is pinned to its Map ID in
`TWM_LEATRIX_NAME_FIXES` (matched as the first tier; "The Ruins of Lordaeron" in
Forever's Leatrix, which has no translation of it at all; remove the entry when
Leatrix is fixed). Tiers: the icon's name equals the instance's; equals one of its
":"-separated parts ("Auchindoun: Mana-Tombs"); the instance's name is in the
icon's description (an icon for
a whole complex such as Blackrock Mountain, "Ahn'Qiraj"; there the entrances
around the nearest one are added, and it counts as a complex whenever the
description lists two or more names). When no name matches, by position: the
click is converted to Big coordinates (same math as
`TWM_GetUnitContinentPosition`) and the entrances within
`TWM_LEATRIX_MATCH_RADIUS` of the zone's larger side are taken, only those of
the icon's own kind (its `atlasName`, "Dungeon" or "Raid": a raid icon does not
take the dungeons next to it; not for a complex's icon, which has both); if there are
none, the single nearest one within `TWM_LEATRIX_FAR_RADIUS`. One instance
opens in `TWMFrame` through `TWM_OpenPortalTarget` without an arrival point
(the map is fitted to the window, like a pick from the list); several -- a
context menu at the cursor with our entrance icons. `/twm debug` prints what
was compared for each click.

The file lives in `integrations/` (one file per other addon). The feature has an
option, `TWMOption.LeatrixMapsClick` (default on, `TWM_LeatrixClickEnabled`),
in the "Integrations" settings tab (`Settings.lua`), a tab that is created only
when Leatrix_Maps is loaded (`IsAddOnLoaded`, so an installed but disabled one
does not count), which is checked on `PLAYER_LOGIN`, after every addon has
loaded. (`GetAddOnEnableState(name, UnitName("player"))` at file load was not
reliable: the tab was still created for a disabled addon.) Off: the icons behave as
without TerrainWorldMap.

Two kinds of Leatrix Maps exist. The Classic Era (1.15.x), Anniversary (2.5.x)
and Mists (5.1.x) one makes its icons map
pins (`LeaMapsGlobalPinMixin`, hooked as above). The Forever one (1.60.x) has no
mixin: it draws plain frames on the map's canvas (`isLeaMapsPin`, data in
`pin.data` = `{kind, x%, y%, name, description, atlas, minLevel, maxLevel}`) that
take no mouse input and finds the icon under the cursor itself by their
footprint. For that one `TWM_LeatrixInstallCanvasClicks` adds a canvas click
handler (`WorldMapFrame:AddCanvasClickHandler`, called for a real click only,
not a drag) and repeats that hit test (`TWM_LEATRIX_HIT_SCALE`). The handler
returns true when it took the click: that stops the map's own handling, which
would otherwise navigate to the zone under the cursor (an icon near the edge of
the map, like Uldaman's in Forever, is over the neighbouring zone as well).
The data is turned into the same `info`
table (`TWM_LeatrixInfoFromData`), so everything below is shared. Its icons
cannot be told from the other kind's by anything but these two paths.

The result is worked out once per map, for all of its dungeon/raid icons
together (`TWM_LeatrixAssign`, on the first click on that map; Leatrix's icon
data is private to its addon and its icons are all created at once when a map is
shown, so they are read from the pin pool), and cached by map and icon
position. An instance an icon matched by name (the first two tiers) belongs to
that icon: other icons of the map do not take it by position. Without that, the
Frozen Halls icon, which stands next to Icecrown Citadel's, got the Citadel into
its list.
