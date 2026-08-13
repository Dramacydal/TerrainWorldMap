# TerrainWorldMap map-data generation scripts

Regenerates `Data_<Flavor>/mapdata_continents.lua` and
`Data_<Flavor>/mapdata_tiles.lua` from real client data. Not loaded by the
addon (`.js`/`.ps1` files are ignored by the WoW addon loader).

Pipeline: `init_workdir.ps1` (fetch client data) → `gen_mapareas.js` (zone
boxes) → `parse_wdt.js` (tile validity + AreaIDs).

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

## When to re-run

Re-run for a flavor when: its `.build.info` version changes, `mapdata_*.lua`
data turns out stale/wrong for some zone, or the flavor's data hasn't been
generated yet.
