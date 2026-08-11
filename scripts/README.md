# TerrainWorldMap map-data generation scripts

Node.js scripts (run outside the game, `node <script>.js ...`) used to (re)generate
TerrainWorldMap's map data from real client data instead of hand-collecting/guessing it.
Not loaded by the addon itself — `.js` files are ignored by the WoW addon loader
(only files listed in one of the `TerrainWorldMap_<Flavor>.toc` files get loaded),
so this folder is safe to keep in the addon directory or delete entirely once
you're done with it.

Both scripts print progress/warnings to stderr and write a **complete,
ready-to-use Lua file** you drop straight into the addon, overwriting the
previous one wholesale — no manual merging/pasting into the middle of
another file needed.

**Multi-flavor note:** TerrainWorldMap ships one `.toc` per client flavor
(`TerrainWorldMap_TBC.toc`, `_Vanilla.toc`, `_Mists.toc`, ...). The data these
scripts generate is flavor-specific (continent/zone uiMapIDs and terrain
differ per expansion), so it lives under `Data_<Flavor>/` (e.g.
`Data_TBC/mapdata_continents.lua`), never in the flavor-agnostic root
`mapdata_zones.lua`/`mapdata_poi.lua`. Point `<out-file.lua>` at the
`Data_<Flavor>/` copy for whichever client you exported the CSVs/WDTs from.

You only need to re-run these for a given flavor if Blizzard reshapes that
expansion's world again (another Cataclysm-style event), ships a client
build where the current `Data_<Flavor>/mapdata_continents.lua`/
`mapdata_tiles.lua` data turns out to be stale/wrong for some zone, or
you're filling in a flavor's data for the first time (see the `TODO`
comments in `Data_Vanilla/`/`Data_Mists/`).

## gen_mapareas.js — zone bounding boxes (`Data_<Flavor>/mapdata_continents.lua`)

Rebuilds `Data_<Flavor>/mapdata_continents.lua` — the Azeroth/Kalimdor/Expansion01
`Twm_mapareas[...]` assignments (per-zone bounding boxes used for the
zone dropdown, click-to-center, and zone-name lookups) — straight from
Blizzard's own `Map`/`UiMap`/`UiMapAssignment` DBC tables, instead of the
addon's original ~2011 hand-collected coordinates (which, it turns out, are
measurably stale — see "why regenerate" below).

`Data_<Flavor>/mapdata_continents.lua` loads right after the root
`mapdata_zones.lua` (which just declares an empty `Twm_mapareas = {}` table)
in that flavor's `.toc` — `mapdata_continents.lua` adds the continent keys to
it, so it's safe to overwrite on its own without touching `mapdata_zones.lua`.
TerrainWorldMap only ever renders the continents it's told about (3 for TBC:
Azeroth/Kalimdor/Expansion01), so no other keys (battlegrounds, dungeons,
raids) belong in this table.

The same file also emits `Twm_UiMapID2Zone[uiMapID] = {continent, areaID}`,
a straight index from a WorldMapFrame-style uiMapID to its
`Twm_mapareas[continent][areaID]` box. `WorldMapOverlay.lua` uses it as
ground truth ahead of any C_Map-hierarchy guess, because a few zones (the
Draenei and Blood Elf starting isles) are filed under a *different*
continent's DBC `MapID` than where C_Map's own uiMap tree nominally parents
them for world-map navigation -- e.g. Eversong Woods is a "child" of Eastern
Kingdoms in C_Map's hierarchy (Blizzard draws a compressed inset icon for it
near Tirisfal), but its real `UiMapAssignment` row -- and its real WDT
terrain -- is filed under Expansion01/Outland, same as the original
hand-collected TerrainWorldMap data already had it.

**Usage:**
```
node gen_mapareas.js <csv-dir> [<out-file.lua>]
```
- `<csv-dir>` — a folder containing `Map.*.csv`, `UiMap.*.csv`, and
  `UiMapAssignment.*.csv` for the client build you're targeting (filenames
  are matched by prefix, so e.g. `Map.2.5.6.69110.csv` works fine).
- `<out-file.lua>` — where to write the generated Lua (point this straight
  at `../Data_<Flavor>/mapdata_continents.lua` to overwrite it in place, or
  write elsewhere first and diff/copy it over by hand if you want to
  sanity-check the output first). **Optional** — omit it to skip writing
  anything and just print the detected continent names.

**Getting the continent name list** — run with just `<csv-dir>`, no
`<out-file.lua>`:
```
node gen_mapareas.js ../Data_Mists
```
prints 4 lines to stdout:
```
Azeroth Kalimdor Expansion01 Northrend Deephome LostIsles Gilneas2 MaelstromZone TolBarad HawaiiMainLand MoguIslandDailyArea
minimaps/(azeroth|kalimdor|expansion01|northrend|deephome|lostisles|gilneas2|maelstromzone|tolbarad|hawaiimainland|moguislanddailyarea)/noliq
(azeroth|kalimdor|expansion01|northrend|deephome|lostisles|gilneas2|maelstromzone|tolbarad|hawaiimainland|moguislanddailyarea)\.wdt
maps/(azeroth|kalimdor|expansion01|northrend|deephome|lostisles|gilneas2|maelstromzone|tolbarad|hawaiimainland|moguislanddailyarea)/\w+_\d+_\d+\.adt
```
- Line 1 — case-sensitive names, paste straight as `parse_wdt.js`'s trailing
  `<ContinentName>` args.
- Lines 2-4 — ready-to-paste search regexes for wow.export's file-list
  search box (one per extraction target: noLiquid minimaps, WDTs, root
  ADTs), all-lowercase (the real wow.export folder names) so you don't have
  to type/match each continent by hand.

This only needs `Map`/`UiMap`/`UiMapAssignment` CSVs (the same ones
`gen_mapareas.js` always needs) — no WDT/ADT required to find out what to extract.

**Getting the CSVs:** export `Map`, `UiMap`, and `UiMapAssignment` for your
client's build via wow.export's DBC export tab (or any other WDBX/DBD-based
DBC-to-CSV tool) and put them in one folder.

**Coordinate transform** (documented in full in the script's header comment):
TerrainWorldMap's box format is `{x1,x2,y1,y2} = {maxX, minX, maxY, minY}` in its own
"Big" (world-yard) coordinate space. `UiMapAssignment`'s `Region_0..5` fields
are a raw world-space AABB (`Region_0/1/2` = min X/Y/Z, `Region_3/4/5` = max
X/Y/Z). The transform that matches TerrainWorldMap's convention is:
```
TerrainWorldMap{x1,x2,y1,y2} = {Region_4, Region_1, Region_3, Region_0}
```
i.e. TerrainWorldMap-X = world Y, TerrainWorldMap-Y = world X, with **no additional offset or
scale** — verified as an *exact* match against the old hand-collected data
for multiple Outland zones (Hellfire Peninsula, Nagrand).

**Why regenerate at all:** Outland was never touched by Cataclysm, so its
old hand-collected data and freshly-generated CSV data should agree exactly
if the transform above is right — confirmed. But applying the *same*
transform to Eastern Kingdoms/Kalimdor zones (e.g. Dun Morogh) produces
values that differ from the ~2011 TerrainWorldMap data by up to a few hundred yards,
even for zones nobody would call "revamped." Conclusion: Cataclysm's
Shattering event subtly recalibrated Azeroth/Kalimdor's terrain coordinates
world-wide, not just in the zones it visibly reshaped — so regenerating from
this exact client's own DBC data is more accurate than trusting the old
snapshot, for any continent other than Outland.

**Bonus effect:** regenerating this way naturally drops any zone that
doesn't exist in the target client's own data (no `UiMapAssignment` row) —
this is how Vashj'ir, Twilight Highlands, Southern Barrens, Uldum, and
Kalimdor's Hyjal all disappeared from the zone dropdown, with no manual
Cataclysm-zone blocklist needed.

Continents (including small "island" maps like Deepholm) are auto-detected
straight from `Map.csv`/`UiMapAssignment.csv` — see `findContinents()`'s
header comment in the script for the exact rule and why it doesn't need a
hardcoded per-flavor list of names or uiMapIDs.

## parse_wdt.js — real terrain existence (`Twm_WDTValidTiles`, `Data_<Flavor>/mapdata_tiles.lua`)

Determines which map tiles have **real terrain** in this specific client
build, and generates the `Twm_WDTValidTiles` table (`Data_<Flavor>/mapdata_tiles.lua`)
that TerrainWorldMap actually gates its tile rendering on.

**Why this exists:** a map tile's *minimap preview texture*
(`World\Minimaps\<continent>\mapXX_YY.blp`, what TerrainWorldMap actually draws) and
its *real terrain* are two independent pieces of data in Blizzard's own
`.wdt` files — a tile can have a valid preview texture left over from a
*later* expansion (e.g. Cataclysm's Twilight Highlands/Vashj'ir) while
having **zero real terrain** in a TBC-era client. Every other approach we
tried (`C_Map.GetMapInfoAtPosition`, `C_Map.GetMapPosFromWorldPos`, a pure
`Twm_mapareas` bounding-box check) was an *indirect* proxy for "is there
real terrain here" and each had false positives or false negatives near
zone edges/coastlines/continent corners. Reading the `.wdt` file directly
gives the actual ground truth Blizzard's own tools use (confirmed by
reverse-engineering `wow.export`, specifically `src/js/3D/loaders/WDTLoader.js`
and `src/js/map-viewer/TerrainRenderer.js`'s `!entry.rootADT` check).

**Usage:**
```
node parse_wdt.js --root <wow.export-flavor-root> --out <out-file.lua> [--noliquid] [--areatable-dir <dir>] <ContinentName> [<ContinentName> ...]
```
`<ContinentName>` is **case-sensitive** and used as-is for the
`Twm_WDTValidTiles`/`Twm_mapareas` Lua table key (e.g. `HawaiiMainLand`,
matching `gen_mapareas.js`'s own `mapdata_continents.lua` key). The script
derives every file path itself (lowercased) under `--root`, matching
wow.export's own extraction layout:
```
<root>/world/maps/<lowercase>/<lowercase>.wdt        (WDT -- MAIN/MAID)
<root>/world/maps/<lowercase>/<lowercase>_C_R.adt     (root ADT files)
<root>/world/minimaps/<lowercase>/                   (only scanned with --noliquid)
```
Example — regenerating Mists' `mapdata_tiles.lua` from all 11 continents in
one shot, with underwater-tile detection and AreaTable-based zone resolution:
```
node parse_wdt.js --root "C:/Users/you/wow.export/_mop_" --out ../Data_Mists/mapdata_tiles.lua --noliquid --areatable-dir ../Data_Mists Azeroth Kalimdor Expansion01 Northrend HawaiiMainLand Deephome LostIsles MaelstromZone Gilneas2 TolBarad MoguIslandDailyArea
```
Point `--out` straight at `../Data_<Flavor>/mapdata_tiles.lua` to overwrite
it in place.

**`--noliquid`** — omit to skip the underwater step entirely
(`Twm_NoLiquidTiles` won't even be declared, which is also how the addon's
"Show underwater terrain" option/menu-entry decide whether to show up at all
— see `TWM_HasNoLiquidData()` in `TerrainWorldMap.lua`). Pass it to also scan
each continent's `<root>/world/minimaps/<lowercase>/` for
`noLiquid_mapXX_YY.blp`/`noliquid_mapXX_YY.blp` files (underwater zones like
Vashj'ir ship a second minimap texture per tile that the client swaps to when
submerged, so the water tint baked into the normal tile doesn't muddy the
minimap). This must be the **actual extracted files** from `world/minimaps/`
for this specific client (e.g. wow.export's "Raw Client Files" bulk export)
— **not** a community listfile. A listfile is the union of every path that
has ever existed across every patch in WoW's history, so a path being
*listed* proves nothing about whether it exists in *this* client's CASC
storage; only a real extracted file is proof.
Continents whose minimap folder wasn't extracted (or that just have no
underwater tiles) are skipped/empty with a log line, not an error.

**Root ADT files** under each continent's own `<root>/world/maps/<lowercase>/`
are always read if present — no separate flag needed, same folder as the
`.wdt`. If found, majority-votes each tile's real `AreaID` straight out of
its own ADT's 256 `MCNK` sub-chunks (`areaid` field, offset `0x34`) and uses
that instead of plain `true` — see `getDominantAreaID()` for why this is
both more accurate (irregular real zone borders, not a rectangle) and fully
offline compared to a live `C_Map.GetMapInfoAtPosition()` scan. Only root
`.adt` files are read (not `_tex0`/`_obj0`/`_obj1`), matched by filename
ending in `_<col>_<row>.adt`. A continent with no ADTs found just keeps
plain `true` for every tile (existence only) — not an error.

**`--areatable-dir <dir>`** — omit to use each MCNK's raw `AreaID` as-is,
which can be a sub-area/POI (e.g. "Garadar") rather than the top-level zone
("Nagrand") — won't match any `Twm_mapareas`/zone-dropdown key. Pass a
directory containing `AreaTable.<version>.csv` (wow.export's DBC export tab)
to instead resolve every chunk's `AreaID` up its `ParentAreaID` chain to the
top-level zone (`ParentAreaID=0`) **before** majority-voting — this also
fixes spurious "a border cuts through this tile" warnings caused by a zone's
own POIs/sub-areas splitting votes against its own base terrain. This is the
only thing in this script that needs `csv-parse` (see "Setup" below) — the
rest (WDT/ADT parsing) has no CSV dependency at all, so omitting this flag
also means you don't need `npm install` for the rest to work.

Writes one complete file containing all the continents you passed:
```lua
Twm_WDTValidTiles = {}
Twm_WDTValidTiles["Azeroth"] = {
    ["35x24"] = true,
    ...
}
Twm_WDTValidTiles["Kalimdor"] = { ... }
```

Also runs a few built-in sanity checks (tiles we've already manually
verified by hand — e.g. `45x06` on Expansion01 should come back VALID,
the Twilight Highlands ghost tiles on Azeroth should NOT) and flags any
`*** MISMATCH ***` loudly — if you change the axis-mapping assumption (see
below) or re-run this against a very different client build, check these
still pass before trusting the output.

**Getting the `.wdt` files:** wow.export → **Raw Client Files** tab → search
for (note: lowercase path)
```
world/maps/azeroth/azeroth.wdt
world/maps/kalimdor/kalimdor.wdt
world/maps/expansion01/expansion01.wdt
```
select, Export.

**Axis mapping** (important if this ever looks wrong): a WDT's `MAIN`/`MAID`
chunks index tiles by `(x, y)` in a 64x64 grid, world-coordinate-aligned the
same way as `Region_0..5` in `gen_mapareas.js` above. Empirically verified
(by matching a real bug screenshot pixel-for-pixel against the script's
output — ocean tiles and Wetlands tiles present, the ghost Twilight
Highlands tiles absent, on the exact same grid coordinates) that:
```
TerrainWorldMap tile key "COLxROW"  <->  WDT tile (x = ROW, y = COL)
```
i.e. TerrainWorldMap's tile-key "column" is the WDT's tile **Y** index, and TerrainWorldMap's
tile-key "row" is the WDT's tile **X** index. This is baked into the script
as `twmCol = y; twmRow = x`. If tiles look systematically
transposed/mirrored after a re-run, this is the first place to check.

**Validity rule:** for FileDataID-based WDTs (`MAID` chunk present, true for
every currently-live client), a tile counts as valid iff its `rootADT` field
is non-zero — completely ignoring whether `minimapTexture` is set. Falls
back to the older boolean `MAIN`-chunk-only flag if no `MAID` chunk exists
(pre-FileDataID clients, not expected to matter for any currently-live
build, included for completeness/future-proofing).
