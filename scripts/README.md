# TerrainWorldMap map-data generation scripts

Regenerates `Data_<Flavor>/mapdata_continents.lua` and
`Data_<Flavor>/mapdata_tiles.lua` from real client data. Not loaded by the
addon (`.js`/`.ps1` files are ignored by the WoW addon loader).

Pipeline: `init_workdir.ps1` (fetch client data) → `gen_mapareas.js` (zone
boxes) → `parse_wdt.js` (tile validity + AreaIDs) → `gen_poi_areas.js`
(sub-area/POI labels).

## Setup

```bash
cd scripts
npm install
```

Requires: Node.js, PowerShell 7+ (`pwsh`), `curl.exe` (bundled with Windows
10/11), a WoW install (for local extraction) or internet access (for
`-Online`).

## Product codes

From `.build.info` in the WoW install root (current as of this writing —
Blizzard can add/rename product codes over time, e.g. for new anniversary
editions, so re-check `.build.info` if a code below stops matching):

| Flavor | Product code | `Data_<Flavor>` |
|---|---|---|
| Vanilla | `wow_classic_era` | `Data_Vanilla` |
| TBC | `wow_anniversary` | `Data_TBC` |
| Mists | `wow_classic` | `Data_Mists` |

## Step 1 — `init_workdir.ps1`: fetch client data

```powershell
./init_workdir.ps1 -Product <product> -WorkDir <dir> -Storage <wow-install-path> [-Proxy <url>] [-Force]
./init_workdir.ps1 -Product <product> -WorkDir <dir> -Online [-Proxy <url>] [-Force]
```

- **`-Product`** (required) — TACT product code (table above)
- **`-WorkDir`** (required) — output root; gets `WorkDir/CASCConsole` (tool, shared) and `WorkDir/<Product>` (per-product data)
- **`-Storage`** (required, unless `-Online`) — path to a local WoW install
- **`-Online`** (optional) — pull from Blizzard CDN instead of `-Storage`
- **`-Region`** (optional, default `eu`) — CDN region
- **`-Locale`** (optional, default `enUS`) — extraction locale
- **`-Proxy`** (optional) — curl `-x/--proxy` format: `scheme://[user:password@]host[:port]` (`http`, `https`, `socks4`, `socks4a`, `socks5`, `socks5h`)
- **`-Force`** (optional) — re-download CASCConsole/listfile/DB2 CSVs even if already present

Downloads the CASCConsole tool + community listfile once per `WorkDir`, then
per product: 4 DB2 CSVs (`AreaTable`/`Map`/`UiMap`/`UiMapAssignment`) and the
WDT/root-ADT/noLiquid-minimap files for every open-world continent.

**Examples:**
```powershell
./init_workdir.ps1 -Product wow_classic_era -Storage "C:\Program Files\World of Warcraft" -WorkDir C:\wow-data

./init_workdir.ps1 -Product wow_anniversary -Online -WorkDir C:\wow-data -Proxy socks5h://user:pass@127.0.0.1:8883
```

Output lands in `<WorkDir>/<Product>/` — pass this path as `<csv-dir>` /
`--flavor-dir` to the next two scripts.

## Step 2 — `gen_mapareas.js`: zone bounding boxes

```bash
node gen_mapareas.js <csv-dir> [<out-file.lua>]
```

- `<csv-dir>` — folder containing `Map.*.csv`, `UiMap.*.csv`,
  `UiMapAssignment.*.csv` (matched by prefix). This is `<WorkDir>/<Product>`
  from step 1.
- `<out-file.lua>` — optional. Point it at `Data_<Flavor>/mapdata_continents.lua`
  to overwrite in place. Omit to just print the continent name list.

**Example:**
```bash
node gen_mapareas.js C:\wow-data\wow_classic_era Data_Vanilla/mapdata_continents.lua
```

stdout, line 1: the exact case-sensitive continent names to pass to
`parse_wdt.js` in step 3, e.g.:
```
Azeroth Kalimdor
```

## Step 3 — `parse_wdt.js`: tile validity + AreaIDs

```bash
node parse_wdt.js --flavor-dir <dir> --out <out-file.lua> [--noliquid] [--areatable-dir <dir>] <ContinentName> [<ContinentName> ...]
```

- **`--flavor-dir`** (required) — `<WorkDir>/<Product>` from step 1
- **`--out`** (required) — output path, e.g. `Data_<Flavor>/mapdata_tiles.lua`
- **`--noliquid`** (optional) — also detect underwater tiles (noLiquid minimaps) — only meaningful for flavors with submerged zones (Mists onward: Vashj'ir, Pandaria coastline)
- **`--areatable-dir`** (optional, defaults to `--flavor-dir`) — folder containing `AreaTable.*.csv`
- **`<ContinentName>...`** (required) — case-sensitive, must match `gen_mapareas.js`'s stdout line 1 exactly

**Examples:**
```bash
node parse_wdt.js --flavor-dir C:\wow-data\wow_classic_era --out Data_Vanilla/mapdata_tiles.lua Azeroth Kalimdor

node parse_wdt.js --flavor-dir C:\wow-data\wow_anniversary --out Data_TBC/mapdata_tiles.lua Azeroth Kalimdor Expansion01

node parse_wdt.js --flavor-dir C:\wow-data\wow_classic --out Data_Mists/mapdata_tiles.lua --noliquid Azeroth Kalimdor Expansion01 Northrend HawaiiMainLand Deephome LostIsles MaelstromZone Gilneas2 TolBarad MoguIslandDailyArea
```

Prints per-continent diagnostics to stderr, including `*** MISMATCH ***`
lines from built-in sanity checks — investigate before trusting the output
if any appear (a mismatch against Vanilla-era reference tiles on a
post-Cataclysm client, e.g. reshaped Azeroth tiles, is expected, not a bug).

## Step 4 — `gen_poi_areas.js`: sub-area/POI labels (`Twm_poi_areas`)

```bash
node gen_poi_areas.js --flavor-dir <dir> --mapareas-file <mapdata_continents.lua> --out <out-file.lua> [--areatable-dir <dir>] <ContinentName> [<ContinentName> ...]
```

- **`--flavor-dir`** (required) — `<WorkDir>/<Product>` from step 1 (needs `AreaTable.*.csv` and the extracted ADTs)
- **`--mapareas-file`** (required) — the flavor's own already-generated `Data_<Flavor>/mapdata_continents.lua` (step 2's output)
- **`--out`** (required) — output path, e.g. `Data_<Flavor>/mapdata_poi_areas.lua`
- **`--areatable-dir`** (optional, defaults to `--flavor-dir`) — folder containing `AreaTable.*.csv`
- **`<ContinentName>...`** (required) — must match a key in `--mapareas-file`'s `Twm_mapareas`

Algorithm (no `AreaPOI` DB2 involved — an earlier version of this script
used it, but its `Icon` field turned out to be a numeric atlas index that
shifts between client builds, plus assorted non-settlement noise):
1. **A** = the AreaIDs this continent actually displays — the keys of
   `Twm_mapareas["<Continent>"]` in `--mapareas-file`, minus the `[0]`
   whole-map sentinel.
2. **B** = every `AreaTable` row whose parent chain (`ParentAreaID`,
   walked all the way up) passes through some zone in A — every real
   sub-area/POI nested anywhere under a displayed zone.
3. Each entry in B is positioned by its own centroid — the average MCNK
   chunk position across every root ADT of that continent (same
   world→Big transform as `gen_mapareas.js`, computed straight from the
   `IndexX`/`IndexY`/`areaid` fields already used in `parse_wdt.js`). An
   AreaID never actually painted on any ADT chunk in this build is
   skipped. Chunks that fall outside their resolved top-level zone's own
   `Twm_mapareas` box (padded by `BOX_PADDING`, 2000 yards) are excluded
   from the average — some sub-areas have a near-identical duplicate copy
   of their own terrain painted thousands of yards away elsewhere on the
   same continent (confirmed for Outland's Draenei starting zone, Ammen
   Vale/Emberglade/The Sacred Grove under Azuremyst Isle — almost
   certainly a private copy used only during the starting-zone intro
   sequence); averaging both blindly lands the centroid in open ocean
   between them.

Known caveat: this also picks up large non-settlement sub-areas whose
`ParentAreaID` happens to point at a displayed zone — e.g. "The Great
Sea"/"The Veiled Sea" (open ocean, spread along the whole coastline, one
AreaTable row per stretch of coast). Left in as-is; prune by name/AreaID
by hand if it bothers you.

**Example:**
```bash
node gen_poi_areas.js --flavor-dir C:\wow-data\wow_anniversary --mapareas-file Data_TBC/mapdata_continents.lua --out Data_TBC/mapdata_poi_areas.lua Azeroth Kalimdor Expansion01
```

## Other scripts

- **`gen_area_centroids.js`** — standalone diagnostic tool, not part of the
  pipeline above. Dumps every AreaID's centroid for a continent
  (`Twm_area_centroids["<Continent>"][areaID] = {x, y}`) and, given
  `--mapareas-file`, self-checks each zone's rolled-up centroid against
  its `Twm_mapareas` bounding box. Useful for validating the ADT
  chunk-position formula (`gen_poi_areas.js` duplicates the same
  computation internally) or just inspecting where a given AreaID
  actually sits.

## When to re-run

Re-run for a flavor when: its `.build.info` version changes, `mapdata_*.lua`
data turns out stale/wrong for some zone, or the flavor's data hasn't been
generated yet.
