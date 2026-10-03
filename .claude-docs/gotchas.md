---
tags: [memory/repo, gotcha]
---

# Gotchas

## A WMO group's own local index (`GroupNum`) is not unique across a whole map

`gen_wmo_tiles.js`'s WMO tile group management feature (`Twm_WMOTiles[map]` as
an array of `{group_id, group_name, tiles}`, checkbox per group) first keyed
`group_id` by `WMOMinimapTexture.GroupNum` alone. That's only unique *within
one placed WMO* — a map with more than one WMO placement (the common case for
outdoor maps: PVPLordaeron places at least 10 distinct buildings, not just the
arena) has each placement numbering its own groups from 0 independently, so
two unrelated buildings' group 0/1/2/... collide. Grouping by `GroupNum` alone
silently merged them: whichever placement processed last overwrote the
earlier one's name and tiles in the output. Confirmed live comparing
PVPLordaeron's generated group names against a direct wow.export inspection
of its actual arena WMO (`world/wmo/pvp/buildings/lordaeron/pvp_lordaeron_arena.wmo`,
`WMOID=4839`, verified byte-for-byte via a raw MOGI/MOGN dump: 5 real groups,
2 unnamed + "Arena"/"InteriorStatues"/"InteriorStatuesTop") — the shipped data
showed a completely different name set, because a *different* building's
groups had overwritten the arena's own.

Fixed: `group_id` is now `"<WMOID>-<GroupNum>"` (`WMOID` already resolved per
placement from the root WMO's own `MOHD` offset 32 — see the listfile gotcha
below) — unique per real physical group on the whole map, not just within one
building. Sorting is numeric on the `(WMOID, GroupNum)` pair, not a string
sort of the compound ID (which would put `"10-0"` before `"2-0"`).

## The community listfile can list a WMO minimap tile that doesn't exist in this build

`gen_wmo_tiles.js` used to find a WMO's baked minimap tiles by pattern-matching
filenames in the community listfile (`<stem>_<group>_<blockX>_<blockY>.blp`).
Razorfen Downs' group 010 (20 tiles) showed up this way and got shipped, but
those files don't exist in this build's actual CASC archive (0 extracted
across two attempts, including a full wildcard sweep of the WMO's minimap
directory) — the listfile is an aggregate across many historical builds, and
this one apparently dropped them. (The DB2 table below is not a complete cure
either: it can also list FileDataIDs that the build lacks — see "WMO tile whose
BLP is absent from the client is skipped" at the end of this file.) In-game this rendered as a solid bright
green tile (`SetTexture` on an unresolvable FileDataID).

Fixed by reading each WMO's real tile list from the `WMOMinimapTexture` DB2
table instead (`GroupNum, BlockX, BlockY, FileDataID`, keyed by `WMOID`) —
generated fresh per build, so it can't carry this staleness. `WMOID` is
**not** a FileDataID (confirmed: Razorfen Downs' root `.wmo` FileDataID is
109503, but its `WMOMinimapTexture` rows all carry `WMOID=1356`) — it's a
separate `uint32` field in the WMO root file's own `MOHD` chunk, offset 32
(right after `ambColor`, right before the bounding box). Switching to this
source silently fixed the same class of stale tile on 8 other TBC dungeons/
raids that had never been individually diagnosed.

## Dungeon/interior minimap tiles are a completely different system from outdoor `mapCC_RR` tiles

Investigated while prototyping a "show a real map inside dungeons" feature (not yet
implemented — see SESSION notes/conversation for status). Outdoor continents use
`world/minimaps/<continent>/mapCC_RR.blp`, addressed by a uniform 533.333-yard grid
(`TWM_Big2Mini_Coord`). Dungeon/instance interiors (built from a single big WMO, not
ADT terrain) use a **completely unrelated** system:

- **There is a dedicated DB2 table, `WMOMinimapTexture`** (`WMOID, GroupNum, BlockX,
  BlockY, FileDataID`) — this is the actual source of truth for which texture belongs
  to which WMO group. Don't try to reverse-engineer it from the tile filenames'
  sequential numbering (`<name>_NNN_00_00.blp`) — that numbering happening to match
  `GroupNum` 1:1 is a coincidence of simple cases, not a rule (`BlockX`/`BlockY` are
  nonzero for groups too big for one 256x256 texture, tiling further).
- **Fixed PPU = 2** pixels per world unit, for every WMO minimap universally — NOT
  derived from any particular group's own bounding-box-to-texture-size ratio (that
  was my first wrong guess; it produces confidently-wrong-looking "sensible" numbers
  that are still wrong).
- Per-group placement: `absX = min(group.bbox.x0, group.bbox.x1) * 2 + blockX*256`
  (same for Y). Canvas placement is a **Y-flip**, not a full X/Y transpose:
  `canvas_y = (max_y - 256) - absY`. (I initially "confirmed" a transpose hypothesis
  visually against a colored-rectangle diagnostic — that was a false positive; this
  particular dungeon's layout happens to look plausible under several different wrong
  transforms. Don't trust a single visual confirmation on a symmetric-ish layout.)
- A group whose texture is smaller than a full 256x256 block (cropped) is anchored to
  the **bottom-left** of its cell, not top-left and not stretched to fill.
- Reference implementation: `wow.export`'s `src/js/wmo-minimap.js`
  (github.com/Kruithne/wow.export) — read this before reinventing any part of this
  again. Its own code comment is the source for the PPU and the model→world relation
  below.
- **Skip fully-transparent source texels (`alpha === 0`)** when compositing — the
  padding around a group's actual footprint within its 256x256 canvas is transparent,
  not black; blit it as opaque and you paint over neighboring groups' content.
- **Round every pixel coordinate to an integer before using it as a typed-array
  index.** A fractional index (`png.data[3.7]`) is not an error and does not throw —
  it's simply a silent no-op per the TypedArray spec (non-canonical numeric key). One
  missing `Math.round()` here presented as "almost the whole composite is empty/black
  except one tile" and cost a long detour before the actual cause was found.
- **The apparent "why do I need an extra 90° rotation on top of everything" step is
  not a fudge factor** — it falls out of composing two already-known facts: (a) for a
  global WMO placed at the WDT origin with no rotation, `wow.export`'s own code notes
  "model->world is a straight negate" (`world = -model`), and (b) this addon's own
  `Big-X = world-Y, Big-Y = world-X` convention (already used for continents). Chain
  those two together and the net pixel-space relationship between `wow.export`'s raw
  output and this addon's own Big-coordinate convention is exactly a 90° rotation.
  For a WMO placed with a *real* rotation (see the Shadowfang case below), this
  shortcut doesn't apply — the actual `MODF` rotation has to be applied honestly.
- **FileDataID is global, but content is per-build.** The same
  `world/minimaps/wmo/dungeon/.../foo_000_00_00.blp` FileDataID returned visibly
  different bytes when extracted from `wow_classic_beta` vs `wow_anniversary` for the
  literal same dungeon (Stockade) — and the WMO root file itself differed too (27
  groups in one build, 26 in the other). Extracting the WMO root, the
  `WMOMinimapTexture` DB2 rows, and the BLP tiles must all come from **the same
  product/build** — mixing them (e.g. geometry from one build, textures from another)
  produces a plausible-looking but wrong composite that's very hard to distinguish
  from "my math is still off" by eye. If a composite looks like two half-overlapping
  copies of the same layout, suspect a mismatched data source before suspecting the
  math again.

## Detecting a "pure WMO" dungeon/instance map vs a real (if small) ADT map

`MPHD.flags & 0x1` (`wdt_uses_global_map_obj`, documented at wowdev.wiki/WDT) is the
authoritative signal. Confirmed against two real cases:

- **Stockade** (`stormwindjail.wdt`): flag set. `MAIN`/`MAID` exist structurally but
  every tile's `rootADT` is 0 (no real terrain at all) — `parse_wdt.js`'s
  `getValidTiles()` already naturally returns an empty list for a map like this, for
  free. A single WDT-level `MODF` places the one global WMO at `pos=(0,0,0), rot=0`.
- **Shadowfang Keep** (`shadowfang.wdt`): flag NOT set. 25 real ADT tiles (courtyard
  terrain) in a 5x5 grid, no WDT-level `MODF` at all. The castle itself is a WMO
  placed the same way any outdoor building is: a normal `MODF` entry inside one of
  those tiles' own `_obj0.adt`, with a real position **and rotation**
  (confirmed: `rot=(0, 68.5, 0)` for Shadowfang's interior/castle WMO — not the
  trivial no-rotation case, so its group bounding boxes can't be placed by translation
  alone, unlike Stockade's).

Don't assume a WMO asset that merely *exists* in the listfile under a dungeon's own
folder is actually placed in the live map — `ld_shadowfang.wmo` (a separate,
plausibly-named "exterior" file sitting right next to `ld_shadowfanginterior.wmo` in
the same CASC folder) turned out to be referenced **nowhere** in any of Shadowfang's
25 tiles' `MODF` chunks when exhaustively scanned; the interior WMO's own
exterior-facing groups are what's actually rendered as the castle's outside walls/roof.
Confirm placement by scanning actual `MODF` FileDataIDs across every tile that has
one, not by name-based inference.

## `C_Map.GetPlayerMapPosition` returns `nil` inside many classic-era instance maps

Confirmed in-game (Stockade, `wow_anniversary`/TBC client): `C_Map.GetBestMapForUnit`
returns a perfectly valid `UiMapID` while inside the instance, but
`C_Map.GetPlayerMapPosition(thatMapID, "player")` reliably returns `nil` anyway. This
isn't a missing-argument bug or an occasionally-flaky thing — classic-era dungeon/raid
maps as a category never got real coordinate-to-pixel mapping data configured (unlike
every outdoor zone, and unlike retail's own dungeon maps). Don't spend time trying to
work around this with a different API call; there's nothing to read here on these
clients. (Relevant if a "player position inside dungeons" feature is ever revisited —
it isn't retrievable at all for the maps tested, not just "sometimes".)

## WoW: Forever/Camelot can't load minimap tiles by path string — use FileDataID

Every flavor's tile rendering (`TerrainWorldMap.lua`'s standalone-window
`SetZoom` and `WorldMapOverlay.lua`'s World Map overlay) called
`Texture:SetTexture("World\Minimaps\<continent>\mapXX_YY")` — a plain path
string — and this had worked on every flavor since the addon existed.  On
WoW: Forever (Camelot beta), the overlay/standalone window showed every
frame, POI, and the black backdrop correctly, but no terrain at all —
confirmed (via `/run` in-game) that `SetTexture` with this exact path
resolves to `nil` on Forever specifically, while the same tile's numeric
`FileDataID` (looked up from a community listfile, since it's not in any
DB2 table) loads fine, and a totally unrelated `Interface\Icons\...` path
string still resolves normally — so this isn't "all path-based SetTexture
is broken", just this addon's specific `world/` asset category on this one
flavor. CASCConsole confirmed the actual `.blp` files are still there in
CASC, unrenamed, at the exact same path — so it's a client-side resolution
restriction, not missing/moved data.

Fixed with `TWM_GetTileTexture(continent, filename)` (`TerrainWorldMap.lua`):
returns the numeric FileDataID from `Twm_TileFileID[continent][filename]`
(`Data_<Flavor>/mapdata_tiles_<kind>.lua` -- continents/battlegrounds/arenas, baked in by `parse_wdt.js --bake-tile-fileids`)
when that flavor's data has one, otherwise falls back to the old path
string — so Vanilla/TBC/Mists are untouched, only Forever needed
regenerating with the new flag. Both `TerrainWorldMap.lua`'s and
`WorldMapOverlay.lua`'s own `SetTexture` call sites go through this one
shared function now instead of each concatenating `"World\Minimaps\"..`
themselves.

## `Slider:SetValueStep` doesn't stop mouse-dragging from giving fractional values

`Settings.lua`'s `CreateSlider` calls `slider:SetValueStep(step)`, which
looks like it should be enough to keep e.g. the Flight Path Curve Smoothing
slider (step 1) landing on whole numbers. It isn't: `SetValueStep` only
snaps keyboard arrow-key nudges. Dragging the thumb with the mouse ignores
it entirely and reports whatever exact pixel-derived fraction the mouse
position maps to, unless `slider:SetObeyStepOnDrag(true)` is also set. Now
set once in `CreateSlider` itself so every slider in this addon gets it,
not just the one where it happened to be noticed.

## `Frame:SetClipsChildren(true)` clips children to the frame's rect for free

The tile grid (`TerrainWorldMap.lua`'s own grid, `WorldMapOverlay.lua`'s
`DrawTiles`) clips every tile manually via intersection-rect math against
the target draw area — that's necessary there because tiles are drawn into
an arbitrary sub-rect of a shared texture pool (e.g. an inset zone on the
World Map), not because WoW frames clip children by default. When
`FlightPaths.lua` first drew flight routes, a line to an off-screen flight
master rendered straight through past `TWMFrameViewFrame`'s own edges —
fixed not by replicating that manual clipping math, but by calling
`viewframe:SetClipsChildren(true)` once (`Templates.xml`'s
`TWMFrameViewTemplate` `OnLoad`) — every child texture (tiles, lines, points)
now gets clipped to the ViewFrame's rect at the GPU level automatically.
Guarded with `if(self.SetClipsChildren) then ... end` since it's a
comparatively modern API, even though it's expected to exist on all 3
flavors (they run on the same modern client engine as retail).

## Battleground entrances have no `areatrigger_teleport` row at all

`scripts/gen_poi_instances.js` finds dungeon/raid entrances by joining
`AreaTrigger.db2` against a `--teleport-csv` reference table (`id ->
target_map`). Battleground entrances (Warsong Gulch, Arathi Basin, Alterac
Valley, ...) will **never** show up via this join, no matter how complete
the reference table is — entering a BG isn't a direct teleport-by-trigger
the way a dungeon door is; it's handled through the battlemaster queue
system, so there's no `id -> target_map` row for them to begin with.
Confirmed empirically for Vanilla's known BG entrance trigger IDs (2412,
2413, 3650, 3654, 3953, 3954) — none exist in `areatrigger_teleport.csv`.

If BG entrances are ever wanted, they need a different, text-based
detector: `AreaTrigger.Message_lang` matches
`/in the (Alliance|Horde) and at least \d+\w* level to enter/i` — this
pattern is unique to faction-gated BG entrances (dungeon entrances only ever
say "You must be at least level N to enter.", no faction clause) and comes
in clean same-level Alliance/Horde pairs. No `target_map`/name is available
this way, though — the map name would have to be hand-mapped from the
(small, stable) set of trigger IDs, since there's no DB2 link to resolve it
automatically. Scenarios (`Map.InstanceType` 5) are excluded from
`gen_poi_instances.js`'s output for the exact same reason — also queue-based
entry, also zero `--teleport-csv` rows, confirmed empirically for Mists.

## Icon frames are pooled across point types — always set VertexColor explicitly

`TWMPoints_GetPoint`'s `TWMP_Clear` resets the icon's texture and text but
**not** `SetVertexColor`. Because the same physical icon frame gets reused
across completely different point types as the viewport scrolls (e.g. a
frame that drew a blue Landmarks circle one frame can draw a Graveyard icon
the next), any `set.setuppoint` that doesn't call `bg:SetVertexColor(...)`
inherits whatever tint the *previous* occupant left behind. Even "no tint,
use the texture's own colors" must be spelled out as
`SetVertexColor(1,1,1,1)` — omitting the call entirely is not the same as a
neutral tint, it's "whatever was there before."

## `Twm_poi_areas`/`Twm_instances` entry formats changed — check indices before reading

- `Twm_poi_areas[map]` entries are `{AreaID, "Name", x, y}` (AreaID added
  as the first field so `sets/capitals.lua` can match an entry back to a
  known AreaID). Older code reading `v[1]` as the name will silently read
  the AreaID instead — always index from `v[2]` for name, `v[3]/v[4]` for
  x/y.
- `Twm_instances[map]` entries are `{"Type", MapID, "Name", x, y}` —
  `"Type"` is `"Dungeon"`/`"Raid"` (also the icon-name suffix), `MapID` is
  `Map.ID` for use with `GetRealZoneText`, `"Name"` is a fallback only (see
  architecture.md's live-name-resolution section).

## `TWMPoints_OnMove`'s cache check only looks at map-center (x,y), not viewport size

A window **resize** changes the viewport's pixel dimensions without
necessarily moving the map's center (x,y) — `TWMPoints_OnMove`'s original
"skip if x,y unchanged" cache check therefore skipped the whole POI
viewport re-cull on resize, leaving stale visible-point lists (POI that
should now be on/off-screen didn't update). Fixed by threading a
`forcePointsUpdate` flag through `SetLocation`/`AdjustLocation`/`SetZoom`,
independent from the tile-grid's own `forceupdate` flag. Don't force it on
every single live-resize tick, though — that re-cull walks every visible
point across every set and doing it on every `OnSizeChanged` tick (which
fires continuously during a drag) visibly lags the resize. `TWMFrame_OnResizeStop`
only forces it once the size has moved `TWM_POINTS_RESIZE_REFRESH_STEP` (40)
pixels since the last re-cull, plus always on the final mouse-up — and the
very first resize of a session must force immediately (no delta to compare
against yet), not silently wait for the threshold.

## The resize grip must sit exactly at the frame's true corner

`TWMFrame:StartSizing("BOTTOMRIGHT")` snaps that corner to the cursor's
*current* position the instant it's called — it's not purely relative
tracking. `TWMFrameResizeButton` used to be offset `(-4, 4)` from the
frame's actual bottom-right corner; clicking anywhere within that 16x16 grip
(which, given the offset, was never exactly at the true corner) caused an
immediate few-to-~20px jump before any mouse movement, confirmed via
`GetPoint()`/`GetSize()` logging around `OnMouseDown`. Fixed by anchoring the
grip at `(0, 0)` instead. (A leftover manual-anchor-collapse workaround from
an earlier, wrong hypothesis — that `StartSizing` needed the frame's anchor
pre-normalized like `StartMoving` does — was tried and removed; it didn't
address the actual cause.)

## Changing only `filterMode` on an already-bound `Texture:SetTexture` can silently not apply for a frame

Calling `tex:SetTexture(path, wrapH, wrapV, filterMode)` with the *same*
`path` as what's already bound, but a different `filterMode`, doesn't
reliably take effect on the very next render -- confirmed with the "Tile
Filtering" Settings option: switching it while stationary didn't visibly
change anything until the map was panned/zoomed afterward, even though the
exact same `SetTexture(...)` call (with the new `filterMode`) runs
immediately either way (`TWM_RefreshFrameTiles`/`RefreshOverlay` force a
full tile-grid rebuild synchronously, same code path a real pan/zoom uses).

Attempts that did NOT reliably fix it: (1) `SetTexture(nil)` immediately
before the real per-tile `SetTexture(...)` call, interleaved tile-by-tile in
the same draw loop (flashed black); (2) toggling through a different
`filterMode` on the same path before the real one, still interleaved
per-tile; (3) a deferred second rebuild via `C_Timer.After(0, ...)` on top
of the normal immediate one.

Current attempt (`TWM_SetTileFilter`, `WorldMapOverlay.lua`): clear ALL
currently-allocated tile textures to nil first, as a separate, complete pass
over both texture pools (`TWM_ClearFrameTileTextures` in
`TerrainWorldMap.lua`, `ClearOverlayTileTextures` in `WorldMapOverlay.lua`)
-- fully unbinding everything -- and only afterwards call
`RefreshOverlay`/`TWM_RefreshFrameTiles` to rebind them all with the new
filter. Unconfirmed whether this actually resolves it; if not, the
asynchronous-BLP-load theory itself may be wrong and the real cause is still
unidentified.

## Point icons sit above the ViewFrame, so a drag starting on one never reaches it

`TWMPoints_GetPoint`/`TWMPoints_AllocMobilePoint` (`Points.lua`) create each
marker as a mouse-enabled `Button` (needed for `TWMP_OnEnter`'s hover
tooltip) parented to the ViewFrame at a higher frame level. WoW only
delivers a mouse event to the topmost mouse-enabled frame under the cursor,
so starting a click-drag with the cursor over a marker never reached the
ViewFrame's own `OnDragStart` (`TWMFrameViewTemplate` in `Templates.xml`,
which sets `self.dragme = true` to start map panning) — the map silently
failed to pan whenever a drag happened to start on an icon.

First fix attempt: give the icon its own `RegisterForDrag` +
`OnDragStart`/`OnDragStop`, mirroring the ViewFrame's own template script.
This looked right but broke differently — one pixel of pan, then nothing
for the rest of the hold. Root cause: point icons are pooled and get
recycled (`TWMP_Clear`, which calls `:Hide()`) for a different point
mid-pan as the view moves, and WoW silently cancels an in-progress drag
gesture the instant the frame that started it gets hidden — so the very
pan the drag caused could recycle the icon out from under its own still-held
gesture.

Working fix: don't tie the drag's lifetime to the icon at all.
`TWMP_EnableDragThrough` only sets `viewframe.dragme = true` on the icon's
plain `OnMouseDown` (no `RegisterForDrag`/`OnDragStart`) — and
`TWMFrameViewFrame_OnDrag` (`TerrainWorldMap.lua`) polls
`IsMouseButtonDown` itself every tick to detect release and clear
`dragme`, instead of relying on an `OnDragStop` tied to a specific frame
that might not survive the whole gesture.

## (Historical, classic menu only) `UIDropDownMenu` entries need `tooltipOnButton = true` to show a tooltip on hover

Setting `info.tooltipTitle`/`info.tooltipText` on a dropdown button (e.g.
`Settings.lua`'s tile-filter dropdown) is not enough by itself — without
`info.tooltipOnButton = true`, the tooltip only shows for a disabled entry
(`tooltipWhileDisabled`), not on a normal hover.

## A frame's `SetPoint` offsets are in ITS OWN (already-scaled) units, not its parent's

`FlightPaths.lua`'s "world frame" trick (see architecture.md) repositions
one shared frame per tick instead of every line individually:
`wf:SetScale(z); wf:SetPoint("TOPLEFT", viewframe, "TOPLEFT", offsetX, offsetY)`.
First attempt passed `offsetX = -x*z` (mirroring the old per-line pixel-math
formula) — this silently flung `wf` thousands of pixels off-screen (every
line invisible, in every mode, no Lua error). Cause: the `x, y` offsets
passed to `SetPoint` are interpreted using the *calling frame's own*
effective scale — since `wf:SetScale(z)` already applies that
multiplication, passing an already-`z`-multiplied offset doubles it.
Fix: pass the raw, unscaled `-x` (no `*z`) and let `wf`'s own scale apply
the multiplication once. The same rule is why each line's own local anchor
inside `wf` (`BigToWorldOffset`) is expressed in pre-scale units too — it's
relative to `wf`, so `wf`'s scale (not the line's own, which doesn't exist
for a plain region) does that multiplication for it.

## Repositioning a frame with many children costs the engine per child, even with an unchanged Lua-side cost

`FlightPaths.lua`'s per-tick `wf:SetPoint()`/`wf:SetScale()` call is O(1) on
the Lua side regardless of how many lines are anchored to `wf` — but
dragging the map with Shift held (switching every route to its full curved
`TaxiPathNode` spline, which can be dozens of segments per route instead of
one straight line) visibly lags anyway, even though the `lastSignature`/
`lastZoom` dirty-checks correctly skip all of *this addon's own* redraw
work during a pure pan. Cause: whenever a parent frame's transform changes,
the client itself (not this addon's Lua) has to resolve the final on-screen
position of every descendant anchored to it, every rendered frame — that
cost is real and scales with child count, and no amount of caching in Lua
can skip work the engine does beneath a moved/rescaled parent. Mitigation:
keep the common case (straight lines) cheap by making the expensive one
(full spline, many more `Line` children) opt-in per-glance (hold Shift)
rather than a persistent display mode.

Related: a `Hide()`-d region is skipped from this per-frame position
resolution entirely (nothing to compute for something that won't render) —
but a `Show()`-n region that's merely clipped out of view by
`SetClipsChildren` still costs the same per-frame resolution as a fully
visible one; clipping only skips the final rasterization step, not the
position math. `FlightPaths.lua`'s `ReleaseLinesFrom` relies on this:
everything beyond `activeLineCount` is genuinely `Hide()`-d, not just
positioned off-screen, specifically so unused pool slots stay cheap.

## The custom tooltip's row buttons must not call `EnableMouse(true)`

`TWMTooltipTemplate:GetNext()` (`TerrainWorldMap.lua`) used to create each
tooltip line as a mouse-enabled `Button`, despite having no `OnEnter`/
`OnClick` of its own — visibility in the tooltip is driven entirely by
`Region:IsMouseOver()`, a pure geometry check that doesn't need mouse input
enabled. The stray `EnableMouse(true)` caused the tooltip box to silently
swallow clicks that landed on it — e.g. a map-drag that happened to start
while the cursor-following tooltip was sitting under it. Removed; tooltip
rows are now click-through.

## Don't blindly reapply this addon's "Big-X = world-Y, Big-Y = world-X" convention to a MODF-derived position

`gen_wmo_tiles.js` first computed a WMO placement's Big coordinates
as `Big-X = MAP_ORIGIN - World.Y, Big-Y = MAP_ORIGIN - World.X` — copying
the cross-swap convention used everywhere else in this addon (e.g.
`gen_mapareas.js`'s header). This looked plausible (still landed inside
the arena's own coarse `Twm_mapareas` box) but rendered visibly wrong
in-game (user: "looks like there's an extra rotation, clockwise or
counterclockwise"). The correct mapping, for a value built from
`MODF.position` (see the axis-order entry below), is the DIRECT one —
`Big-X = MAP_ORIGIN - World.X, Big-Y = MAP_ORIGIN - World.Y`, no
cross-swap. Confirmed empirically, not just asserted: computed each WMO
tile's Big box both ways and checked which one falls inside its own
hosting ADT tile's Big box — that box computed completely independently,
via `TWM_Mini2Big_Coord`'s trusted col/row formula applied to the ADT
filename (e.g. `orgrimmararena_32_30_obj0.adt` → col=32, row=30). The
cross-swap version placed every tile in the transposed quadrant relative
to its own hosting tile; the direct version landed cleanly inside it, for
both Dalaran Sewers and Orgrimmar (independently checked). Lesson: this
addon's Big-coordinate cross-swap convention isn't a universal law, it's
calibrated per-source against whatever that source's own "X"/"Y" already
mean — reusing it against a raw chunk struct (MODF) without checking is
exactly how this addon's OWN combination of "two already-known facts"
elsewhere (the dungeon-interior 90°-rotation note, above) produces a
correct result in one case and a double-transpose in another. When in
doubt, check against an independently-computed ground truth box, not
just "still inside the coarse overall box" (too weak a check — it passed
here even with the bug present).

## MODF and MOGP store their 3-float vectors in DIFFERENT axis orders

`MODF.position`/`MODF.rotation` (ADT placement struct) store `(X, height,
Y)` — confirmed earlier (Dalaran Sewers' own placement:
`position=(16278.01, 6.17, 15765.27)`, the tiny middle value is obviously
height). `MOGP`'s own bounding box (WMO group file chunk) is a plain
`C3Vector`, `(X, Y, Z=height)` — the STANDARD order, NOT the same
reordering MODF uses. `gen_wmo_tiles.js` originally read MOGP's
index 2 for local Y (copying MODF's convention onto MOGP by mistake) —
this silently produced tiles that still landed inside the arena's own
(coarse) `Twm_mapareas` box, so the earlier "validated against the known
box" check didn't catch it, but they rendered visibly wrong in-game (user
described it as looking rotated). Confirmed wrong by checking real data:
a WMO group whose tile filenames include both `blockY=0` and `blockY=1`
must have a >128-model-unit span along its true Y axis — true for MOGP
bbox index 1 (~147/~157 units) but not index 2 (~77/~38 units, which
would only ever need one block). Fixed by reading index 1 for local Y.
**When combining ANY two of this addon's own raw-chunk vectors, check each
struct's own documented axis order separately — never assume they match.**

## WMO-tile world position: the final formula, and the reusable lessons behind it

`gen_wmo_tiles.js`'s local→world formula for WMO minimap tiles (yaw is
applied; placements with pitch/roll are skipped), current/correct state:

1. `local.X = box.min[0] + blockX*128`, `local.Y_raw = box.min[1] + blockY*128`
   — `box` is the WMO group's own MOGP bounding box, a plain `(X,Y,Z=height)`
   `C3Vector` (NOT the same axis order as `MODF.position`/`rotation`, which are
   `(X,height,Y)` — index 1 is the real horizontal Y, index 2 is height).
   `blockX`/`blockY` read directly against `box[0]`/`box[1]`, no swap.
2. **No flip about a tiled-groups pivot.** The model's local Y is mirrored
   about local 0 (anchor = raw `MODF.position`): the tile's true model Y range
   is `[box.min[1] + blockY*128, + realH/PPU]`, passed as the first argument
   of `toBig` (`Big = (MAP_ORIGIN - pos) + rotateOnly(y, x)`). The earlier
   version reflected about the centre P of the *tiled groups'* bbox instead of
   about 0, which is only right when P equals the whole-model bbox centre
   (single-group maps, e.g. Orgrimmar Arena) and puts everything else off by
   `rotOnly(-2P, 0)`; the interim fix that re-anchored from `MODF.extents`
   shifted that error to `rotOnly(2(bcy-P), 0)` (Sunwell: ~127 raw, ~463
   extents-anchored, both measured). Found via
   `scripts/audit_wmo_extents.js`: baked extents centre = `pos + R*(bboxCx,
   -bboxCy)` within 1 unit for 875/951 placements. Remaining outliers are
   pitch/roll/scaled WMOs and WDT-level placements (see next entry).
3. 90°-CW orientation fix: Blizzard's own WMO-group minimap baking pipeline
   is rotated 90° from world axes (a real, fixed property — also true for
   WMO dungeon interiors, see the entry above). Apply
   `(local.X, local.Y) -> (-local.Y, local.X)` right here, before local ever
   becomes a world position — NOT as a render-time rotation around a pivot
   (tried both a computed centroid and the placement's real anchor; both
   worked but are unnecessary, since rotating `local` directly is provably
   identical and needs no runtime pivot at all).
4. **(Historical -- step 2's pivot is gone, see above.) Two rounds of re-anchoring were needed to get step 2 onto the
   placement's own true range, not an implicit zero or a quantized
   approximation of it** — both invisible to every relative/adjacency
   check, only found via one arena's rare independent ground truth
   (Orgrimmar Arena also has real ADT-baked outdoor minimap tiles for the
   SAME building its WMO overlay draws — a pixel-for-pixel comparison
   between the two was the only thing that surfaced either bug):
   - **Round 1**: step 2's flip started as a faithful, verbatim port of
     wow.export's real `compute_minimap_layout()` (confirmed by reading its
     actual GitHub source, not a paraphrase) — `local.Y = (globalMaxLocalY
     - 128) - local.Y_raw`, where `globalMaxLocalY = max(local.Y_raw+128)`
     across every tile. But that function builds a `canvas_y` PIXEL
     coordinate, valid only for arranging tiles relative to EACH OTHER on a
     composited image — wow.export's own, separate `build_world_meta()`
     (the actual real-world-position function) does NOT use `canvas_y` at
     all; it reads the raw, unflipped value directly (`world = -model`).
     Treating `canvas_y` as if it were a real local coordinate re-anchors
     the whole placement onto the canvas's own arbitrary zero — confirmed
     as a real, large (~160-unit), single-axis offset against Orgrimmar's
     real minimap tile. First fix: add back `trueMinLocalY` (the minimum
     RAW, still block-quantized, local Y across the placement) — reduced
     the error to ~14-40 units (measurement-method-dependent), a big
     improvement but not zero.
   - **Round 2**: that remaining ~14 units turned out to be a second,
     smaller instance of the exact same mistake, one level down —
     `globalMaxLocalY`/`trueMinLocalY` are both built from block-quantized
     `local.Y_raw` values (`box.min[1] + blockY*128`), not the group's own
     TRUE, continuous bbox edge. A group's real geometry need not exactly
     fill a whole number of 128-unit blocks (Orgrimmar's own group spans
     241.6 real units of Y but reads as 2 full blocks = 256 units — a
     14.4-unit slack). wow.export's own `max_y` inherits this same slack
     (its `build_world_meta` uses the SAME block-quantized `max_y` from
     `compute_minimap_layout`, so wow.export never has to notice), but this
     addon has ground truth wow.export doesn't — so it doesn't have to
     inherit wow.export's imprecision here. Fixed by using each involved
     GROUP's own real `box.min[1]`/`box.max[1]` (not per-tile, not block-
     quantized) for the shared reference — see step 2's final form.
   Both rounds are one GLOBAL constant/reference shared across the whole
   placement, so neither could ever disturb Dalaran's already-verified
   ~21.575-unit group-to-group offset (confirmed numerically, exactly
   preserved, after each round, before shipping either). Verified after
   round 2 by re-rendering the Orgrimmar overlay-vs-real-ADT-tile
   comparison and measuring the gap directly (color-thresholded pixel
   scan across 5 rows, not eyeballed): ~14 units before round 2, ~3-5
   units after (down at the noise floor of the measurement method itself)
   — visually, the WMO overlay now fully covers the real building with no
   visible gap anywhere.
5. `World = MODF.position + local` (plain addition). NOT subtraction —
   wow.export's own source comment "for a global wmo at the wdt origin,
   model->world is a straight negate" describes a different special case (a
   *global* WMO at the WDT origin), not the general MODF-placement rule.
6. `Big-X = MAP_ORIGIN - World.X`, `Big-Y = MAP_ORIGIN - World.Y` — no
   cross-swap (this addon's usual "Big-X = world-Y" convention is calibrated
   for other sources, not a value already in MODF's own axis order).
7. Texture content: identity UV for steps 1-2, but needs its own 90°-CW
   `SetTexCoord(0,1, 1,1, 0,0, 1,0)` (8-param form) to match step 3 — a
   separate concern (pixel content) from box position.

Reference implementation: wow.export's real GitHub source
(`src/js/wmo-minimap.js`, `git clone` it — a locally-installed build can be an
old version that lacks this file entirely). Its `compute_minimap_layout`
(per-tile PNG-canvas arrangement, presentation-only) and `build_world_meta`
(single whole-image corner-to-world mapping) solve different problems —
don't port one where the other applies.

**Reusable lessons** (each cost real time to relearn once, some twice):
- A flip/rotation needs ONE pivot shared across everything it's applied to.
  A per-group or per-tile pivot can look correct on every local check
  (adjacency, even a numerically-identical-looking reference value) while
  still producing a wrong absolute result.
- A reflection (sign flip on an absolute offset, e.g. `pos - local` instead
  of `pos + local`) is invisible to adjacency checks, pixel-mirror proofs,
  and even coarse bounding-box containment (it keeps everything inside the
  same ADT tile) — it only shows up as the whole result being mirrored
  relative to independent ground truth. When a position bug survives every
  relative check, suspect the one step that ISN'T relative.
- A comment documenting the right formula next to code that doesn't match it
  is worthless — check the two against each other, don't just trust the
  comment.
- If a fix can be phrased as "rotate/transform the final result around a
  reference point," check whether that point is just a fixed offset from an
  earlier pipeline stage (here, the placement anchor is `local = 0`) and
  apply the correction there instead — no runtime pivot to get wrong.
- A reference tool's PRESENTATION coordinate (built for arranging pixels on
  its own canvas/image) and its WORLD coordinate can both derive from the
  same raw data yet be genuinely different values, not just different units
  — porting the former where the latter is needed reproduces the right
  *relative* arrangement while silently re-anchoring the whole result onto
  the presentation coordinate's own arbitrary origin. This class of bug is
  invisible to every relative check (adjacency, cross-referencing against
  the same tool's own output) and only shows up against independent ground
  truth — here, comparing the WMO overlay directly against Orgrimmar's own
  real ADT-baked tile of the identical building, pixel-for-pixel, was what
  finally surfaced it.

## A WDT-level (pure-WMO) MODF has no usable position/rotation/extents-centre

`pos=0`, `rot=0`, `uniqueId=0xFFFFFFFF`, and its `extents` are the raw
model-space bbox, so comparing extents' centre to a computed one is
meaningless for these (only the size is comparable) -- `audit_wmo_extents.js`
flags them `wdtLevel` and scores size only. MODF dedup in
`gen_wmo_tiles.js` is by `uniqueId` (one placement repeats across the ADT
tiles it straddles); deduping by `nameId` silently dropped distinct
placements of the same WMO (Sunwell's ship x4, Hillsbrad/Stratholme small
WMOs, ...).

## An arena's "map key" is Map.csv's `Directory` value, exact case — not the on-disk folder name

Every `Twm_*[map]` table (`Twm_mapareas`, `TWM_ARENAS`, `frame.opt.Map`) is
keyed by `Map.csv`'s `Directory` column value verbatim, e.g. `DalaranArena`,
`OrgrimmarArena` — mixed case. The real on-disk extracted folder name for
these two specifically is all-lowercase (`world/maps/dalaranarena/`), and
because Windows filesystem paths are case-insensitive, a script that reads
its arena argument straight off the extracted folder listing and both (a)
uses it to build a filesystem path AND (b) writes it verbatim as a Lua
table key runs to completion with no error, but produces a table keyed
with the wrong case — `Twm_WMOTiles[frame.opt.Map]` (exact,
case-sensitive Lua string match) then always misses. Confirmed this
happened for `gen_wmo_tiles.js`'s first run (args
`dalaranarena orgrimmararena`, silently wrong keys — no WMO tiles or
checkbox ever appeared in-game, no error anywhere). Fix: always pass this
script the map key exactly as it appears as a `Twm_mapareas`/`Twm_ArenaNames`
key already (check `Data_<Flavor>/mapdata_arenas.lua` first), not whatever
case `ls`/`dir` shows for the extracted folder.

## XML comments can't contain a literal `--`

`<!-- ... -->` is standard XML; a literal `--` anywhere inside the comment
body (not just at the very end) is illegal and fails the client's XML
parser with `not well-formed (invalid token)`, naming the `.xml` file and a
line/column that points at the `--` itself, not necessarily at the comment
start. This has recurred multiple times in this addon's XML files
(`TerrainWorldMap.xml`, `Templates.xml`) specifically because this
codebase's Lua comments use `--` as their own comment delimiter, and it's
easy to carry that habit into an adjacent XML comment (e.g. writing
`<!-- some data -- rest of note -->` as an em-dash-style aside). Reword to
avoid the literal `--` (a semicolon, period, or single hyphen all work)
instead of trying to escape it — XML comments have no escape mechanism.

## Draw order among same-layer, same-sublevel textures is undefined -- don't rely on creation order

The arena WMO overlay (`TWM_WMOOverlay_Update`) originally relied on
`vf:CreateTexture(nil, "OVERLAY")` call order to stack a higher-height WMO
tile visually on top of a lower one -- textures created later were assumed
to draw on top, matching how the rest of this addon's own pooled-texture
systems (the base tile grid, `Points.lua`'s icons) are already written.
Confirmed via community reports (wowinterface.com) this is **not**
documented or guaranteed behavior: draw order for multiple textures
sharing the same layer AND sublevel is unreliable, and can visibly change
just from reconfiguring a texture (exactly what happens here every time a
pooled tile texture is reused for a different map). Fixed by setting each
tile's sublevel explicitly (`Texture:SetDrawLayer(layer, sublevel)`,
sublevel range `[-8,7]`) from its rank in an already-sorted list, instead
of trusting call order. If any other part of this addon ever needs a
specific, non-obvious stacking order among several same-frame textures,
use an explicit sublevel the same way -- don't assume creation order will
hold.

**Superseded for the WMO overlay:** a sublevel only has 16 steps, far fewer than
real dungeons stack, so the overlay now orders its groups by frame level instead
(see "WMO overlay stacking" at the end of this file). The explicit-sublevel rule
above still holds for anything that stays within a few overlapping textures.

## `Slider:SetReverseValues` doesn't exist at all -- confused with `StatusBar:SetReverseFill`

Used once, for the arena WMO height-cutoff slider (`TWM_WMOOverlay_EnsureHeightSlider`,
`TerrainWorldMap.lua`), to try to flip a vertical `Slider`'s default
max-at-bottom layout to the more natural min-at-bottom/max-at-top. Crashed
live: `attempt to call a nil value`. Initially assumed (wrongly, without
checking) this meant "exists on retail, missing on this Classic client" —
corrected after research: `Slider:SetReverseValues` isn't documented
anywhere (checked warcraft.wiki.gg's `UIOBJECT_Slider` page and Blizzard's
own auto-generated API dump, `Blizzard_APIDocumentationGenerated` in
`Gethe/wow-ui-source`) and doesn't appear to exist on ANY client — this was
very likely confabulated from the real, differently-scoped
`StatusBar:SetReverseFill`/`GetReverseFill` (a real, documented API, but
for `StatusBar`, not `Slider`). Fixed without it: store/read the
**negated** value as the slider's own min/max/value
(`SetMinMaxValues(-maxH, -minH)`, `SetValue(-maxH)`, then
`actualHeight = -value` in `OnValueChanged`) — achieves the same reversal
through plain arithmetic instead of a method call. Lesson: when a
plausible-sounding Blizzard API method errors as nil, don't assume it's a
real method missing on this client specifically -- check whether it exists
on ANY client first, the same way `MouseIsOver`/`SetClipsChildren` below
were actually confirmed (not assumed) to be client-dependent.

## The global `MouseIsOver(frame)` function doesn't exist on every client

`Points.lua`'s `TWMFrameViewFrame_UpdatePointTooltip` used to call the
global `MouseIsOver(v)` to check point-icon hover state — worked fine on
Vanilla/TBC/Mists, but spammed `attempt to call a nil value` on WoW: Forever
(patch 12.1.5), which removed this global entirely along with a batch of
other old convenience globals (`GetItemInfo`, `GetMouseFocus`, etc. — see
Forever's known-issues notes). Fixed with `TWM_IsMouseOverFrame(frame)`
(`Points.lua`): tries the equivalent `Region:IsMouseOver()` method first
(present on every supported flavor, Forever included), falling back to the
bare global only if a frame somehow lacks that method — same guarded-API
pattern as Templates.xml's `SetClipsChildren` check. Use this helper for
any future hover check instead of either form directly.

## This Classic client's `GlobalStrings.db2` does NOT carry `EXPANSION_NAME<N>` -- don't rely on client globals for expansion names

Needed a localized "Classic"/"The Burning Crusade"/etc. name per
`Map.db2.ExpansionID` for the Dungeons/Raids expansion-selection dropdown
(`gen_instance_maps.js`'s `expansion` field, `TWM_GetExpansionName`). Retail
addons commonly read `_G["EXPANSION_NAME"..id]` for this — a real Blizzard
global, localized for free, no addon-side translation needed. Checked
whether it exists here before relying on it: extracted `wow_anniversary`'s
own `dbfilesclient/globalstrings.db2` (FileDataID 1394440, confirmed present
per-locale via CASCConsole's `Info` mode) via wago.tools'
`db2/GlobalStrings/csv?product=wow_anniversary` — only 509 rows total, none
matching `EXPANSION_NAME` at all. This Classic build's `GlobalStrings.db2`
apparently only carries strings added on top of some older baseline (no
expansion-trial/character-select UI exists in Classic), so the global is
simply undefined here — reading it would silently return `nil`, not a wrong
value, so this is easy to ship un-noticed until someone opens the affected
dropdown.

Fixed by sourcing real client-verified names from `Achievement_Category`
instead (`wago.tools/db2/Achievement_Category/csv?product=<flavor>&locale=<locale>`)
— achievement category headers for per-expansion dungeon/raid groups are
real, always-localized in-game strings that exist on every flavor with
achievements at all. This also caught a real translation trap: ruRU/deDE
achievement categories keep expansion titles **untranslated** ("The Burning
Crusade", "Wrath of the Lich King", etc., verbatim English) — a fan
translation (e.g. ru "Пылающий Легион") would have been wrong. zhCN, by
contrast, genuinely translates them (巫妖王之怒, 大地的裂变, ...). Baked into
`Locale/*.lua`'s `TWM_EXPANSION_<N>` as plain hand-authored constants
(same pattern as every other `TWM_CATEGORY_*`/`TWM_OPTIONS_*` string in this
addon) rather than a client-global lookup — lesson: **verify a Blizzard
global actually exists on THIS product/flavor via real extracted data
before depending on it for anything user-facing**, don't assume retail's
API surface carries over to Classic just because the identifier sounds
generic enough to be shared.

## `\w+` in a CASC extraction regex silently excludes any Directory with a space or apostrophe

Six scripts (`gen_wmo_tiles.js`, `parse_wdt.js`, `gen_poi_areas.js`,
`gen_area_centroids.js`, `gen_mapareas.js`, `preview_wmo_tiles.js`) built
their own CASCConsole extraction pattern with a `\w+_...\.adt`/`\w+_obj0\.adt`
alternative for "this map's own tile/obj0 filename" — `\w` is
`[A-Za-z0-9_]` only, no space, no apostrophe. A tile ADT's real filename on
disk embeds the map's own `Directory` stem as a literal prefix
(`stratholme raid_37_24_obj0.adt`, `zul'gurub_33_52_obj0.adt`) — for any map
whose `Directory` has either character, this pattern matched nothing, ever,
for that map's own tile files.

Confirmed the actual damage this caused: `gen_wmo_tiles.js`'s own
"already extracted, skip unless --force" cache check (`needsExtraction`)
scans a map's directory for at least one obj0 file matching this same
pattern's shape — since it silently never found one for `Stratholme Raid`/
`Zul'gurub`, the check stayed permanently `true` for any map list containing
either, forcing a full CASCConsole re-extraction on **every single run**,
`--force` or not (confirmed: two back-to-back runs against already-extracted
data both re-triggered extraction, only fixed after correcting the regex).

Fixed everywhere by replacing `\w+` with `[^/]+` (matches anything except a
path separator — same convention the `.wdt` alternative next to it already
used, `[^_/]+\.wdt`). Lesson: when building a regex to match "this file,
whatever its exact name", don't reach for `\w+` as a stand-in for "any
filename character" — a real Directory/filename can and does contain
punctuation `\w` excludes, and the failure mode (silently matches zero
files, no error) is exactly the kind of thing that looks like an unrelated
caching bug until you check the regex itself against a real problem
filename.

## `gen_arenas.js`/`gen_instance_maps.js` needed a "discovery" pass before a real one, or they'd silently ship empty

Both scripts derive their own box from `--tiles-file` (`Twm_WDTValidTiles`,
written by `parse_wdt.js`), but before `scripts/gen_candidates.js` existed,
the only way to learn an arena's/dungeon's own `Directory` name (to pass to
`parse_wdt.js`) was to run `gen_arenas.js`/`gen_instance_maps.js` itself
first and read its own stdout — meaning the documented pipeline order was:
run once (get names via stdout, `--tiles-file` doesn't have this map's data
yet so it silently produces a coarser box or nothing), run `parse_wdt.js`
with those names added, run again for the real output. Skipping the first
pass (or the reader assuming a single call was enough, since nothing errors)
produces an empty `Twm_ArenaNames`/no usable dungeon boxes with no warning
beyond an easy-to-miss stderr line.

Confirmed this broke `Data_TBC/mapdata_arenas.lua` for real: running
`gen_arenas.js` exactly once, against a `--tiles-file` that hadn't been
told about arena zones yet, produced `Twm_ArenaNames = {}` — silently
overwriting 3 real, working arenas with nothing (recovered from git, not
lost, but shipped-empty is shipped-empty until someone notices the dropdown
is missing every arena). Fixed architecturally, not by "remembering to run
it twice": `gen_candidates.js` now computes every category's map-name list
upfront (`candidates/<kind>.json`), so `parse_wdt.js --candidates <kind>`
already knows every zone it'll ever need to cover before anything else
runs, and `gen_arenas.js`/`gen_instance_maps.js` need exactly one real
invocation each, always. Lesson: a generator whose own correctness depends
on *which order* two independent scripts are invoked in is a footgun
waiting for a clean-slate run to prove it — compute the shared prerequisite
data upfront instead of letting one consumer's own stdout be the other's
discovery mechanism.

## `skip_lists.js`'s own header claimed `skipMaps` applied to `gen_arenas.js`/`gen_battlegrounds.js` -- it never actually did

`skip_lists.js`'s header comment lists `skipMaps` as applying to "every
consumer (`gen_arenas.js`/`gen_battlegrounds.js`/`gen_instance_maps.js`'s
own candidate list)". Only `gen_instance_maps.js`'s `findCandidates` ever
actually imported `skip_lists.js` and filtered on it — `findArenas`
(`gen_arenas.js`) and `findBattlegrounds` (`gen_battlegrounds.js`) never
did, since neither script ever needed this in practice (`skipMaps` only
ever held dungeon-category dev-junk rows, CashTest/`test`, so the gap never
had anything to actually exclude). Surfaced when `gen_candidates.js` (which
imports all three `find*` functions to build one consistent set of
candidate lists) made the inconsistency visible for the first time. Fixed:
both now take a `flavor` parameter and filter via `isSkipped(skipMaps,
flavor, r.ID)`, matching `findCandidates`'s own pattern exactly, so the
doc comment is now actually true. Lesson: a doc comment describing
cross-file behavior ("every consumer does X") is a claim about code that
lives elsewhere and can silently drift the moment a new consumer is added
without re-verifying the old ones still hold — grep for the actual import,
don't trust the comment.

## `gen_candidates.js` existing wasn't the same thing as scripts actually reading it

When `gen_candidates.js` first landed, `gen_arenas.js`/`gen_battlegrounds.js`/
`gen_instance_maps.js` kept calling their own `findArenas`/`findBattlegrounds`/
`findCandidates` directly against a freshly-parsed `Map.csv`, exactly as
before -- `gen_candidates.js` only centralized who else (`parse_wdt.js`,
`gen_wmo_tiles.js`, `gen_poi_areas.js`) could learn a category's map list
without running one of these three first. That's a real, working half of
the fix (it's what actually removes the multi-pass requirement, see the
entry above), but it left the *other* half of the point silently unfinished:
these three scripts were still independently re-running the exact same
discovery/filter logic `gen_candidates.js` had just centralized, one
`Map.csv` parse each, all after `gen_candidates.js` had already computed the
identical, JSON answer. Fixed: `findArenas`/
`findBattlegrounds`/`findCandidates` now run *only* inside `gen_candidates.js`;
the three scripts' own `main()` reads `candidates/<kind>.json` back (by
`Map.csv` `ID`, for whatever locale-independent fields aren't in the
lightweight JSON) instead of re-deriving. Lesson: "component A now produces
data B" is not the same claim as "component C now consumes B instead of
recomputing it" -- verify the actual call site changed, not just that the
new data source exists and is theoretically available.

## Map box (`Twm_mapareas`) of pure-WMO maps goes stale after a `gen_wmo_tiles.js` regen

`gen_instance_maps.js` derives the box of a pure-WMO dungeon/raid from the corners in `mapdata_wmo_tiles_<kind>.lua`
(`--wmo-tiles-file`). Regenerating the tiles WITHOUT re-running `gen_instance_maps.js` for the same flavor leaves the
old box: the map centres on empty space next to the WMO cluster (seen: BlackrockDepths X shifted ~580 units after
the placement fix). Always re-run both together, per flavor and kind.

## WMO tile whose BLP is absent from the client is skipped, not drawn at a guessed size

`gen_wmo_tiles.js` reads each tile's real width/height from its BLP. Tiles are extracted by FileDataID
(`ensureExtractedFileDataIds`, CASCConsole `-m FileDataId`, one call for a comma-separated batch), straight from the
IDs in `WMOMinimapTexture` -- the community listfile is not needed for that, and a brand-new build's tiles usually
have no name in it yet (Forever 1.60.1.70170's rebuilt Blackrock Depths: 123 tiles, none named). CASCConsole puts a
named file at its own path and an unnamed one at `unknown/FILEDATA_<id>` (no extension); the script reads both.
If the FileDataID is in `WMOMinimapTexture` but the build has no such file (CASCConsole prints "not found in root"),
the tile is dropped with a `not in client -- skipped` warning. It used to be kept at a 256x256 fallback, which could
never render anyway. Seen: Mists QuarryofTears/IcecrownCitadel (2510652-55), COTDragonblight (2510634/35); Forever
Shadowfang (213723, 213755). Map boxes (`gen_instance_maps.js`) are derived from the kept tiles, so re-run it after this.
Do not run a second CASCConsole while a pipeline run is going: both read `CASCConsole/listfile.csv` and one of them
dies with "being used by another process" (which silently drops that run's extraction and looks like missing files).

## WMO overlay stacking: one frame per group, frame levels, and TWM_WMO_FRAME_BAND

Real dungeons stack 30+ groups on top of each other (measured overlap depth: Gnomeregan 31, Karazhan 34), but a
texture draw layer only has 16 sublevels, so ranking tiles by sublevel (the old `i - 9` clamp) collapsed everything
past rank ~15 onto one sublevel and the order became arbitrary. `TWM_WMOOverlay_Update` now ranks the enabled groups
by `tile[7]` (= `anchorHeight + min(bbox z)` of the group, wow.export's own `zOrder`, ties keep data order) and puts
each group's textures into its own child frame of ViewFrame with level `ViewFrame + 1 + rank`.
Frame levels are global within a strata, so every other ViewFrame child (point markers, flight masters, flight
path frame, zoom/terrain/WMO buttons, TWMFOO) is lifted by `TWM_WMO_FRAME_BAND` (Points.lua) -- a new ViewFrame child
that must draw above the tiles needs `+ TWM_WMO_FRAME_BAND` in its level too. The debug borders/labels live on a
dedicated frame at `ViewFrame + TWM_WMO_FRAME_BAND`. Side effect: the ADT-tile debug borders (OVERLAY 7 on ViewFrame
itself) now draw under the WMO tiles.

## Point tooltip sometimes never appears: `OnEnter` and `Region:IsMouseOver()` disagree at the icon's edge
The tooltip is driven by polling in the ViewFrame's `OnUpdate`, which runs only while `vf.inpoint` is set (by the icon's
`OnEnter`) and clears it as soon as the poll finds nothing hovered. If the poll's `IsMouseOver` is false right after an
`OnEnter` (the engine hit test and the exact float rect can differ by a pixel; 1 UI unit = 1.5 px at scale 0.8), polling
stops and no new `OnEnter` comes while the cursor moves inside the icon. Fix (Points.lua): `OnEnter`/`OnLeave` maintain
`point.hovered`, and `TWM_IsPointHovered` = `IsMouseOver` OR (`hovered` and shown) is used for both add and remove.
Tooltip width: `TWMTooltipTemplate:FixSize` = text offset (8 margin + 24 icon column) + widest text + 8; it was text + 64,
leaving ~30px empty on the right.

## All dropdowns/menus are Blizzard_Menu (`DropdownButton`, `MenuUtil`), not `UIDropDownMenu`
The two header dropdowns (`TWMFrameDropDown`, `TWMFrameDropDown2`) are `DropdownButton` + `WowStyle1DropdownTemplate`
(menus built by `TWM_GenerateMapMenu`/`TWM_GenerateZoneMenu` in `TerrainWorldMap.lua`, set up by `TWM_SetupDropdowns`).
The "Show Points" button (`TWMFOO_OnClick`, Points.lua) opens `MenuUtil.CreateContextMenu` with checkboxes added by each
set's `configmenu(menu, name, lm)` via `TWMFOO_AddToggle` (checkbox response is Refresh, so the menu stays open). The
Settings tile filter is a `DropdownButton` with radios. No `UIDropDownMenu` code is left; the next two sections are
historical. Notes for the header dropdowns: the button text is always set explicitly
(`TWM_SetDropdownText` -> `OverrideText`, which ignores radio selection); `OverrideText` is skipped when the text is
unchanged because `UpdateDropDown2` runs on every pan; menus are regenerated on every open, so `IsSelected` callbacks see
current state; long lists use `SetScrollMode`. Dev-map orange is a `|cff...|r` prefix in the radio text. Blizzard source
(extracted from CASC): `interface/addons/blizzard_menu/{dropdownbutton,menutemplates,menu}.lua`, the usage guide is
`11_0_0_menuimplementationguide.lua` in the same folder.

## (UIDropDownMenu only) Entries 9..N of a level-3 dropdown list are invisible: two frames named `DropDownList3`
Symptom (Anniversary, the Dungeons > Classic list, 19 entries): rows 1-8 render, the list frame has room for all 19, but
rows 9..N are blank and unclickable; which rows depended on the CURRENT map (Eastern Kingdoms: 9-19, Outland: 9-15,
arena: none). Cause: Blizzard's classic `UIDropDownMenu` starts with `UIDROPDOWNMENU_MAXLEVELS = 2` and builds
`DropDownList3` lazily, creating a new list under the same global name, and `UIDropDownMenu_Initialize` runs the
initializer IMMEDIATELY (it does not just store it). `SetMap` called `UIDropDownMenu_Initialize(zoneDropdown, ...)`, so at
every map change the Zone dropdown's `AddButton`s ran (EK 25 zones, Outland 15, arenas 0) and raised
`UIDROPDOWNMENU_MAXBUTTONS` long before any menu was opened. The buttons created before the new level-3 list existed kept
the old, hidden list as parent: `DropDownList3Button9:GetParent()` was a hidden frame named `DropDownList3`, `Button16`'s
the shown one (so `IsShown()` was true but nothing was drawn).
Fix: `SetMap` uses `UIDropDownMenu_SetInitializeFunction` (stores the callback, which is what the old comment already
claimed); `ToggleDropDownMenu` initializes the list when the dropdown is opened. Verified in game that this alone is
enough (a re-parenting workaround was tried first and removed).
How it was found: in-game `/run ... :GetParent()==DropDownList3` / `:IsShown()` on a visible and an invisible button,
plus Blizzard's own `UIDropDownMenu.lua` extracted from CASC (`interface/addons/blizzard_sharedxml/classic/`).
Lessons: "the frame exists and `IsShown()` is true" says nothing about visibility if a parent is hidden -- compare the
parents. Use `UIDropDownMenu_SetInitializeFunction`, not `UIDropDownMenu_Initialize`, to register a callback without
side effects on the shared lists. Do not call `UIDropDownMenu_CreateFrames` yourself (it writes secure globals).
Root mechanism (read from `blizzard_sharedxml/classic/uidropdownmenu.lua` + `.xml`, identical in Anniversary 2.5.6 and
Mists 5.5.4): the XML declares `DropDownList1..3` but the Lua starts with `UIDROPDOWNMENU_MAXLEVELS = 2`, so the first
level-3 menu makes `UIDropDownMenu_CreateFrames` create a SECOND frame named `DropDownList3` (with buttons 9..MAXBUTTONS).
The global name, and the list that is actually shown, stay with the XML one, which only has the template's 8 buttons;
buttons 9+ exist only in the hidden second list (verified in game: `DropDownList3Button9:GetParent()` had 31 children and
`~= DropDownList3`, which had 10). Entries 9..N of a level-3 list are invisible. Raising `UIDROPDOWNMENU_MAXBUTTONS` alone
does not help (tried). Fix: `TWM_PreGrowDropDownButtons` (VARIABLES_LOADED) raises the button count through the public
`UIDropDownMenu_AddButton` (levels 1-2) and creates buttons 9..MAXBUTTONS inside the XML `DropDownList3` itself; the
later duplicate list then cannot take over the names. Check in game right after login: `/run print(UIDROPDOWNMENU_MAXBUTTONS)`
(not 8) and, with a long level-3 list open, `DropDownList3Button9:GetParent()==DropDownList3`. Do not write
`UIDROPDOWNMENU_MAXLEVELS` yourself (taint). WoW: Forever uses the newer dropdown implementation (no
`UIDROPDOWNMENU_MINBUTTONS`/`MAXBUTTONS` globals, no second list): `TWM_PreGrowDropDownButtons` returns early there.

## Two maps with the same name overwrite each other in the dungeon/raid/scenario/arena lists
`TWM_DUNGEONS`/`TWM_RAIDS`/`TWM_SCENARIOS`/`TWM_ARENAS` are keyed by the localized map name. Mists has both `SchoolofNecromancy`
(ID 289, enUS "Scholomance OLD") and `NewScholomance` (ID 1007); in ruRU/deDE/frFR/koKR both are named alike, so the later
one replaced the earlier. `TWM_DisplayNames` (TerrainWorldMap.lua) appends the map's enUS name (its ID when that equals the
shared name) to EVERY entry of a shared name, so e.g. ruRU shows "Некроситет (Scholomance OLD)" and "Некроситет (Scholomance)".
Names that are unique in the locale stay untouched.

## Instance maps listed with no drawable tiles: the WDT/MAID and the listfile describe other builds too
Symptom (Mists): dropdown entries (Abyssal Maw outer, Deathwing fight, Stormgarde Keep, Mogu Island Loot Room, ...) that
show nothing at all. Cause: `Twm_WDTValidTiles` was built from the WDT's `rootADT` MAID slot only, but a tile's minimap
texture (`minimapTexture` slot, FileDataID) can be named in the WDT and in the community listfile without this client
shipping the file (verified: CASC extraction by name and by FileDataID returns nothing for those maps).
Fix: `parse_wdt.js` (`findTilesWithArt`, kinds dungeons/raids/scenarios only) keeps a tile only if its minimap BLP is
really extractable from the client (by the MAID `minimapTexture` FileDataID, by path when the WDT has no MAID);
`gen_instance_maps.js` does not list a map with neither ADT nor WMO tiles (when a `--wmo-tiles-file` is given). Continents,
battlegrounds and arenas keep WDT-only validity. A map that must be hidden although it has tiles goes into
`mapdata_development.lua` (`Twm_DevelopmentMaps`), not into a skip list.

## Icons / tiles shimmer or change width by 1px while the map moves: align everything to physical pixels
Symptom: POI icons (thin glyphs like "!" most of all) get 1px wider/narrower and jitter against the terrain, both when
dragging and in follow mode. Cause: the view moved in UI units (1 unit = 1.5 physical px at UI scale 0.8 / 1440p) while
tiles are drawn with pixel snapping off (sub-pixel) and icons with the client's default snapping, so each icon's edges and
texels were rounded differently from position to position.
Fix (Points.lua / `TWMFrameTemplate:SetLocation`): the drawn view position is snapped to whole physical pixels
(`opt.Location` stays exact -- drags add deltas to it, so snapping it would drift); icon offsets are snapped in ABSOLUTE
screen coordinates (`SnapToPixel` with the view's `GetLeft()/GetTop()` as origin -- the view edge itself usually sits on a
half pixel, which made the client's rounding flip on exact ties); icon size is a whole number of pixels
(`TWM_GetIconSize`). Pixel size in view units =
`UIParent:GetHeight()*UIParent:GetEffectiveScale()/physicalHeight/viewEffectiveScale` (`GetPixelSize`).
What did NOT help (tried and removed): turning pixel snapping off for icons (worse -- whole icon shimmers at
sub-pixel positions), snapping offsets relative to the view origin only, texel snapping off, a quarter-pixel offset from
the grid line, a 0.002 texcoord shift, linear icon filtering, integer icon scale (32/64px), anchoring the icon texture
straight to the pan anchor, and dropping the pan anchor for a full relayout per tick. Measured in game: the followed
unit's per-tick steps and the icon's on-screen steps are smooth and monotone. What remains is a faint "breathing" of the
edges of "!" icons: Icon-Exclaim.tga has a wide soft halo (~250 semi-transparent pixels), so its edges blend with the
moving NEAREST-sampled ground; only a sharper icon texture would remove it. Do not floor the tile pixel offset in `SetLocation` while the view can
be fractional: tile 1's texcoord uses the exact fraction, so a floored offset shears the other tiles by up to 1px.
Follow mode: the followed unit's marker is anchored to the view center (`TWMP_CenterOnView`), not placed by its true
position, otherwise it jitters by the view's snapping error.

## (Historical) "Show Points" checkmarks vanish while the map is dragged: `UIDropDownMenu_SetSelectedID` touches the shared open list
No longer applies (no classic `UIDropDownMenu` code left); only relevant if one is reintroduced. Symptom: with the "Show Points" menu (TWMFOO) open, dragging the map (or follow mode, once a second) clears/moves its
checkmarks; the saved `PointCfg` is fine and reopening the menu shows the right state. Cause:
`TWMFrameTemplate:UpdateDropDown2` refreshed the Zone dropdown with `UIDropDownMenu_SetSelectedID`, which updates the
buttons of the shared, currently open `DropDownList` regardless of which dropdown owns it.
Fix: `TWM_SetZoneDropdown` writes `dd2.selectedID` directly and only sets the text when `UIDROPDOWNMENU_OPEN_MENU` is
ANY other menu -- also the map/dungeon list (guarding only "Show Points" made the follow tick's once-a-second refresh
check the dungeon-list entry with the same index as the current zone). Any other code that refreshes a dropdown's
selection while a different menu may be open needs the same guard (`UIDropDownMenu_ClearAll` in `SetMap` is unguarded,
only runs on map change).

Related, not a bug of ours: in this client (2.5.6) `UIDropDownMenuButton_OnClick` hides only the clicked list; upper
levels stay until the autohide timer, so a click handler that must close a multi-level menu calls
`CloseDropDownMenus()` itself (`TWM_PickMap`). Blizzard source: `interface/addons/blizzard_sharedxml/classic/uidropdownmenu.lua`.
