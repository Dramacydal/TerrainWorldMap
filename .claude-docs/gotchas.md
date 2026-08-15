---
tags: [memory/repo, gotcha]
---

# Gotchas

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

## `UIDropDownMenu` entries need `tooltipOnButton = true` to show a tooltip on hover

Setting `info.tooltipTitle`/`info.tooltipText` on a dropdown button (e.g.
`Settings.lua`'s tile-filter dropdown) is not enough by itself — without
`info.tooltipOnButton = true`, the tooltip only shows for a disabled entry
(`tooltipWhileDisabled`), not on a normal hover.

## The custom tooltip's row buttons must not call `EnableMouse(true)`

`TWMTooltipTemplate:GetNext()` (`TerrainWorldMap.lua`) used to create each
tooltip line as a mouse-enabled `Button`, despite having no `OnEnter`/
`OnClick` of its own — visibility in the tooltip is driven entirely by
`MouseIsOver()`, a pure geometry check that doesn't need mouse input
enabled. The stray `EnableMouse(true)` caused the tooltip box to silently
swallow clicks that landed on it — e.g. a map-drag that happened to start
while the cursor-following tooltip was sitting under it. Removed; tooltip
rows are now click-through.
