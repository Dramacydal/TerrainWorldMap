---
tags: [memory/repo, gotcha]
---

# Gotchas

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
(`Data_<Flavor>/mapdata_tiles.lua`, baked in by `parse_wdt.js --listfile`)
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

## `UIDropDownMenu` entries need `tooltipOnButton = true` to show a tooltip on hover

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

`gen_wmo_tiles.js`'s local→world formula for WMO minimap tiles (rotation≈0
placements only), current/correct state:

1. `local.X = box.min[0] + blockX*128`, `local.Y_raw = box.min[1] + blockY*128`
   — `box` is the WMO group's own MOGP bounding box, a plain `(X,Y,Z=height)`
   `C3Vector` (NOT the same axis order as `MODF.position`/`rotation`, which are
   `(X,height,Y)` — index 1 is the real horizontal Y, index 2 is height).
   `blockX`/`blockY` read directly against `box[0]`/`box[1]`, no swap.
2. Y-flip: compute `trueGlobalMinY`/`trueGlobalMaxY` — the min/max of every
   GROUP's own real `box.min[1]`/`box.max[1]` used by this placement (group-
   level, continuous geometry, NOT block-quantized, NOT per-tile), then
   `local.Y = (trueGlobalMinY + trueGlobalMaxY) - local.Y_raw - 128`. Must be
   ONE shared value for the whole placement, never per-group — a per-group
   reference can be numerically identical between groups (block counts
   coincide) while still being anchored to a different absolute point per
   group, silently breaking their relative alignment even though within-group
   adjacency looks fine. Must also be the group's TRUE bbox edge, not a
   block-quantized one — see step 4 for why that distinction is itself worth
   ~14 units of real, measured error.
3. 90°-CW orientation fix: Blizzard's own WMO-group minimap baking pipeline
   is rotated 90° from world axes (a real, fixed property — also true for
   WMO dungeon interiors, see the entry above). Apply
   `(local.X, local.Y) -> (-local.Y, local.X)` right here, before local ever
   becomes a world position — NOT as a render-time rotation around a pivot
   (tried both a computed centroid and the placement's real anchor; both
   worked but are unnecessary, since rotating `local` directly is provably
   identical and needs no runtime pivot at all).
4. **Two rounds of re-anchoring were needed to get step 2 onto the
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
