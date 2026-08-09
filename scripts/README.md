# Yatlas map-data generation scripts

Node.js scripts (run outside the game, `node <script>.js ...`) used to (re)generate
Yatlas's map data from real client data instead of hand-collecting/guessing it.
Not loaded by the addon itself — `.js` files are ignored by the WoW addon loader
(only files listed in `Yatlas.toc` get loaded), so this folder is safe to keep
in the addon directory or delete entirely once you're done with it.

Both scripts print progress/warnings to stderr and write a **complete,
ready-to-use Lua file** you drop straight into the addon, overwriting the
previous one wholesale — no manual merging/pasting into the middle of
another file needed.

You only need to re-run these if Blizzard reshapes the world again (another
Cataclysm-style event) or ships a client where the current
`mapdata_continents.lua`/`mapdata_tiles.lua` data turns out to be stale/wrong for
some zone.

## gen_mapareas.js — zone bounding boxes (`mapdata_continents.lua`)

Rebuilds `mapdata_continents.lua` — the Azeroth/Kalimdor/Expansion01
`Yatlas_mapareas[...]` assignments (per-zone bounding boxes used for the
zone dropdown, click-to-center, and zone-name lookups) — straight from
Blizzard's own `Map`/`UiMap`/`UiMapAssignment` DBC tables, instead of the
addon's original ~2011 hand-collected coordinates (which, it turns out, are
measurably stale — see "why regenerate" below).

`mapdata_continents.lua` loads right after `mapdata_zones.lua` in `Yatlas.toc`.
`mapdata_zones.lua` just declares an empty `Yatlas_mapareas = {}` table —
`mapdata_continents.lua` adds the three continent keys to it, so it's safe
to overwrite on its own without touching `mapdata_zones.lua`. Yatlas only
ever renders these 3 continents, so no other keys (battlegrounds, dungeons,
raids, Northrend) belong in this table.

**Usage:**
```
node gen_mapareas.js <csv-dir> <out-file.lua>
```
- `<csv-dir>` — a folder containing `Map.*.csv`, `UiMap.*.csv`, and
  `UiMapAssignment.*.csv` for the client build you're targeting (filenames
  are matched by prefix, so e.g. `Map.2.5.6.69110.csv` works fine).
- `<out-file.lua>` — where to write the generated Lua (point this straight
  at `../mapdata_continents.lua` to overwrite it in place, or write
  elsewhere first and diff/copy it over by hand if you want to sanity-check
  the output first).

**Getting the CSVs:** export `Map`, `UiMap`, and `UiMapAssignment` for your
client's build via wow.export's DBC export tab (or any other WDBX/DBD-based
DBC-to-CSV tool) and put them in one folder.

**Coordinate transform** (documented in full in the script's header comment):
Yatlas's box format is `{x1,x2,y1,y2} = {maxX, minX, maxY, minY}` in its own
"Big" (world-yard) coordinate space. `UiMapAssignment`'s `Region_0..5` fields
are a raw world-space AABB (`Region_0/1/2` = min X/Y/Z, `Region_3/4/5` = max
X/Y/Z). The transform that matches Yatlas's convention is:
```
Yatlas{x1,x2,y1,y2} = {Region_4, Region_1, Region_3, Region_0}
```
i.e. Yatlas-X = world Y, Yatlas-Y = world X, with **no additional offset or
scale** — verified as an *exact* match against the old hand-collected data
for multiple Outland zones (Hellfire Peninsula, Nagrand).

**Why regenerate at all:** Outland was never touched by Cataclysm, so its
old hand-collected data and freshly-generated CSV data should agree exactly
if the transform above is right — confirmed. But applying the *same*
transform to Eastern Kingdoms/Kalimdor zones (e.g. Dun Morogh) produces
values that differ from the ~2011 Yatlas data by up to a few hundred yards,
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

If Blizzard ever renumbers the continent uiMapIDs (`ourUiMapID` in the
script, currently Azeroth=1415/Kalimdor=1414/Expansion01=1945 — used only to
pick out the `[0]` whole-continent box), get the current values in-game with:
```
/run for _,v in ipairs(C_Map.GetMapChildrenInfo(946, Enum.UIMapType.Continent, true)) do print(v.mapID, v.name) end
```

## parse_wdt.js — real terrain existence (`Yatlas_WDTValidTiles`, `mapdata_tiles.lua`)

Determines which map tiles have **real terrain** in this specific client
build, and generates the `Yatlas_WDTValidTiles` table (`mapdata_tiles.lua`) that
Yatlas actually gates its tile rendering on.

**Why this exists:** a map tile's *minimap preview texture*
(`World\Minimaps\<continent>\mapXX_YY.blp`, what Yatlas actually draws) and
its *real terrain* are two independent pieces of data in Blizzard's own
`.wdt` files — a tile can have a valid preview texture left over from a
*later* expansion (e.g. Cataclysm's Twilight Highlands/Vashj'ir) while
having **zero real terrain** in a TBC-era client. Every other approach we
tried (`C_Map.GetMapInfoAtPosition`, `C_Map.GetMapPosFromWorldPos`, a pure
`Yatlas_mapareas` bounding-box check) was an *indirect* proxy for "is there
real terrain here" and each had false positives or false negatives near
zone edges/coastlines/continent corners. Reading the `.wdt` file directly
gives the actual ground truth Blizzard's own tools use (confirmed by
reverse-engineering `wow.export`, specifically `src/js/3D/loaders/WDTLoader.js`
and `src/js/map-viewer/TerrainRenderer.js`'s `!entry.rootADT` check).

**Usage** (pass as many `.wdt`/name pairs as you like in one run):
```
node parse_wdt.js <out-file.lua> <path-to-.wdt> <ContinentName> [<path-to-.wdt> <ContinentName> ...]
```
Example — regenerating the addon's actual `mapdata_tiles.lua` from all 3 continents
in one shot:
```
node parse_wdt.js ../mapdata_tiles.lua azeroth.wdt Azeroth kalimdor.wdt Kalimdor expansion01.wdt Expansion01
```
Point `<out-file.lua>` straight at `../mapdata_tiles.lua` to overwrite it in place.

Writes one complete file containing all the continents you passed:
```lua
Yatlas_WDTValidTiles = {}
Yatlas_WDTValidTiles["Azeroth"] = {
    ["35x24"] = true,
    ...
}
Yatlas_WDTValidTiles["Kalimdor"] = { ... }
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
Yatlas tile key "COLxROW"  <->  WDT tile (x = ROW, y = COL)
```
i.e. Yatlas's tile-key "column" is the WDT's tile **Y** index, and Yatlas's
tile-key "row" is the WDT's tile **X** index. This is baked into the script
as `yatlasCol = y; yatlasRow = x`. If tiles look systematically
transposed/mirrored after a re-run, this is the first place to check.

**Validity rule:** for FileDataID-based WDTs (`MAID` chunk present, true for
every currently-live client), a tile counts as valid iff its `rootADT` field
is non-zero — completely ignoring whether `minimapTexture` is set. Falls
back to the older boolean `MAIN`-chunk-only flag if no `MAID` chunk exists
(pre-FileDataID clients, not expected to matter for any currently-live
build, included for completeness/future-proofing).
