# TerrainWorldMap map-data generation scripts

Regenerates `Data_<Flavor>/mapdata_continents.lua` and
`Data_<Flavor>/mapdata_tiles_<kind>.lua` from real client data. Not loaded by
the addon (`.js`/`.ps1` files are ignored by the WoW addon loader).

Pipeline: `init_workdir.ps1` (fetch shared tools) → `bootstrap.ps1` (set
WORK_DIR/CLIENT_DIR/FLAVOR/PROXY for the rest of this shell session) →
`gen_candidates.js` (writes `candidates/<kind>.json` — the map-name list
every later step reads instead of taking one as an argument) →
`gen_mapareas.js` (zone boxes) → `parse_wdt.js` (tile validity + AreaIDs,
once per `--candidates <kind>`) → `gen_poi_areas.js` (sub-area/POI labels) →
`gen_poi_graveyards.js` (graveyards) → `gen_poi_instances.js` (dungeon/raid
entrances) → `gen_poi_flightmasters.js` (flight masters + routes) →
`gen_battlegrounds.js`/`gen_arenas.js`/`gen_instance_maps.js` (battleground/
arena/dungeon+raid+scenario maps, each run independently of the rest — see
their own steps below). Every step runs **exactly once** per category now —
no step needs re-running with a bigger map list once a later step discovers
more candidates (see `gen_candidates.js`'s own header for why).

Every script below is self-sufficient: given `--work-dir`/`--flavor` (and
`--client-dir`/`--online` for the ones that need real game files, not just
DB2 CSVs), it downloads/extracts exactly what *it* needs into
`<work-dir>/<flavor>/`, via the shared [`extract.js`](extract.js) module.
Anything already there (DB2 CSVs, locale exports, extracted WDT/ADT/WMO
files, the downloaded Wowhead page) is skipped on a re-run unless `--force`
is passed — same as `curl`-based tools everywhere else, "already present,
skipping". `--proxy <url>` (curl's `-x/--proxy` format) is accepted by every
script that downloads anything.

`--work-dir`/`--client-dir`/`--flavor`/`--proxy` are all also readable from
the environment (`WORK_DIR`/`CLIENT_DIR`/`FLAVOR`/`PROXY`, `envOr` in
`extract.js`) — **the environment variable wins whenever it's set to a
non-empty value**, the CLI flag is only the fallback for an invocation
without having sourced `bootstrap.ps1` at all. Source it once per shell
session (see Setup below) and every command below drops those four flags
entirely.

Any script that used to take a list of map names as bare trailing arguments
(`parse_wdt.js`, `gen_wmo_tiles.js`, `gen_poi_areas.js`,
`gen_area_centroids.js`) now takes exactly one of **`--candidates <kind>`**
(reads `candidates/<kind>.json`, written once by `gen_candidates.js`) or
**`--maps <Name1,Name2,...>`** (an explicit, comma-separated override for
ad-hoc/manual use — comma, not space, so a Directory containing a space,
e.g. `Stratholme Raid`, needs no special handling).

## Setup

```bash
cd scripts
npm install
```

```powershell
. .\bootstrap.ps1 -Flavor wow_anniversary
```
Sets `WORK_DIR`/`CLIENT_DIR`/`FLAVOR`/`PROXY` for the rest of this shell
session (dot-source it, a plain `.\bootstrap.ps1` wouldn't persist the env
vars into your shell). Edit the defaults inside `bootstrap.ps1` to match
your own machine — it's personal config, your local edits don't need to be
committed.

Requires: Node.js, PowerShell 7+ (`pwsh`, for `init_workdir.ps1` only),
`curl.exe` (bundled with Windows 10/11), a WoW install (for local
extraction via `--client-dir`) or internet access (for `--online`).

## Product codes

From `.build.info` in the WoW install root (current as of this writing —
Blizzard can add/rename product codes over time, e.g. for new anniversary
editions, so re-check `.build.info` if a code below stops matching):

| Flavor | Product code | `Data_<Flavor>` |
|---|---|---|
| Vanilla | `wow_classic_era` | `Data_Vanilla` |
| TBC | `wow_anniversary` | `Data_TBC` |
| Mists | `wow_classic` | `Data_Mists` |
| Forever | `wow_classic_beta` | `Data_Forever` |

Forever (WoW: Forever, Classic+) is still in beta as of this writing --
`wow_classic_beta` is the product code for now, but expect Blizzard to swap
it for a permanent one at launch (re-check `.build.info` if it stops
matching). Its continent list is `Azeroth`/`Kalimdor`/`2991` -- `2991` is
Zephras Isle, a new beta zone with no proper flavor-specific directory name
assigned yet (just its own numeric `Map.ID`, used as-is as the continent
key). No Outland/Northrend -- this flavor's world is Classic-era Kalimdor
and Eastern Kingdoms plus this one new island so far.

## Step 1 — `init_workdir.ps1`: fetch shared tools

```powershell
./init_workdir.ps1 -WorkDir <dir> [-Proxy <url>] [-Force]
```

- **`-WorkDir`** (required) — output root; gets `WorkDir/CASCConsole`
  (CASCConsole.exe + the community listfile, shared across every flavor)
- **`-Proxy`** (optional) — curl `-x/--proxy` format: `scheme://[user:password@]host[:port]` (`http`, `https`, `socks4`, `socks4a`, `socks5`, `socks5h`)
- **`-Force`** (optional) — re-download CASCConsole/listfile even if already present

That's all this script does — no product/flavor, no DB2 CSVs, no WDT/ADT
extraction. Every other script below takes `--work-dir <dir>` (this same
`-WorkDir`) plus its own `--flavor <product>` and self-downloads/extracts
whatever it personally needs into `<dir>/<product>/`.

**Example:**
```powershell
./init_workdir.ps1 -WorkDir C:\wow-data
```

## Step 1.5 — `gen_candidates.js`: map-name lists for every category

```bash
node gen_candidates.js --work-dir <dir> --flavor <product> [--force] [--proxy <url>]
```

Writes `<work-dir>/<flavor>/candidates/{continents,battlegrounds,arenas,dungeons,raids,scenarios}.json`
— run this once per flavor, **before anything else below**, including
`gen_battlegrounds.js`/`gen_arenas.js`/`gen_instance_maps.js` themselves now
(not just `parse_wdt.js`/`gen_wmo_tiles.js`/`gen_poi_areas.js`'s own
`--candidates <kind>`) — see each of their own steps for what they read
back and why. Doesn't re-implement any filtering logic — imports
`findContinents`/`findBattlegrounds`/`findArenas`/`findCandidates` straight
from `gen_mapareas.js`/`gen_battlegrounds.js`/`gen_arenas.js`/
`gen_instance_maps.js`, so there's exactly one place each category's own
filter rules live (those 4 files also keep an `if (require.main === module)`
guard so `require()`-ing them for this doesn't also trigger their own CLI
`main()`).

Each JSON file is an array of `{id, key}` (`key` = `Map.csv`'s `Directory`,
`id` = `Map.csv`'s `ID`, same as `skip_lists.js` keys on) — NOT the
localized display name, which every consumer still resolves for itself, per
locale, at generation time. `dungeons`/`raids`/`scenarios` entries also carry
`expansion` (`Map.csv`'s `ExpansionID` — `TerrainWorldMap.lua`'s own
expansion-selection dropdown needs it), `battlegrounds` entries also carry
`uiMapID` (live position tracking). Empty array, not a missing file, for a
category with nothing on this flavor (e.g. TBC's own `scenarios.json`).

**Why this exists:** see `.claude-docs/gotchas.md` for the two bugs this
replaced — `parse_wdt.js` used to need re-running up to 3 times with a
growing map list, and `gen_arenas.js`/`gen_instance_maps.js` needed their
own stdout as a "discovery" pass before a second, real pass; both silently
broke on a genuinely clean start. Knowing every category's map list
upfront removes that ordering dependency entirely — every script below
runs exactly once now.

**Example:**
```powershell
node gen_candidates.js
```

## Step 2 — `gen_mapareas.js`: zone bounding boxes + capital city maps

```bash
node gen_mapareas.js --work-dir <dir> --flavor <product> [--out <out-file.lua>] [--force] [--proxy <url>]
```

- **`--work-dir`** (required) — from step 1
- **`--flavor`** (required) — TACT product code (table above); also names the self-downloaded `<work-dir>/<flavor>/` cache dir
- **`--out`** — optional. Point it at `Data_<Flavor>/mapdata_continents.lua`
  to overwrite in place. Omit to just print the continent name list.

Self-downloads `Map`/`UiMap`/`UiMapAssignment`/`AreaTable` CSVs from
wago.tools into `<work-dir>/<flavor>/` first (skipped if already present).

Also emits `Twm_CityMapIDs` (capital-city `uiMapID`s, used by
`WorldMapOverlay.lua` to gate the terrain overlay on city sub-maps) by
reading `mapdata_zones.lua`'s own `Twm_CapitalAreaIDs` (hand-maintained
`AreaID` list, stable across the whole game's history) directly and
joining it against `UiMapAssignment`'s `AreaID`↔`UiMapID` mapping — no
per-flavor hand-collection needed.

**Which UiMapAssignment rows become a zone box:** a zone row's `UiMap.Type`
is `3` (`UI_MAP_TYPE_ZONE`) on Vanilla/TBC/Mists, but a build can also use
`6` (`UI_MAP_TYPE_ORPHAN`) for one (e.g. Gilneas on Mists) — the
per-continent zone-box loop accepts either (the initial "is this Map row
even a continent" check stays `UI_MAP_TYPE_ZONE`-only, so this doesn't pull
in unrelated Map rows as new continents, only fixes an already-included
continent's own zone list). Names per TrinityCore's
[`DBCEnums.h`](https://github.com/TrinityCore/TrinityCore/blob/master/src/server/game/DataStores/DBCEnums.h)
(`enum UiMapType`, `enum MapTypes` for `Map.InstanceType` — `3` there is
`MAP_BATTLEGROUND`, used throughout `gen_battlegrounds.js`).

A zone row is skipped from becoming its own box entry when its `AreaID`
has a non-zero `ParentAreaID` in `AreaTable` — a real displayed zone
(Mulgore, Durotar, Elwynn Forest, ...) is always a top-level `AreaTable`
entry, but Blizzard sometimes also gives a small starting-experience camp
carved out of one (Camp Narache/Mulgore, Valley of Trials/Durotar,
Northshire/Elwynn Forest, Gilneas City/Gilneas, ...) its own dedicated
zone-type row too; without this filter it shows up as a peer entry
alongside its own parent zone in the zone dropdown. It's still a real
`AreaTable` row and shows up as an ordinary sub-area POI
(`gen_poi_areas.js`) under its real parent zone, same as any other named
sub-area — this only excludes it from being its own separate top-level
zone box.

**Example:**
```bash
node gen_mapareas.js --work-dir C:\wow-data --flavor wow_classic_era --out Data_Vanilla/mapdata_continents.lua
```

(This continent list is also exactly `candidates/continents.json`, once
`gen_candidates.js` has run — its own stdout line 1 above is kept for a
one-off/no-workdir use, but `parse_wdt.js` below reads the JSON by default.)

## `Data_<Flavor>/mapdata_poi.lua` — hand-maintained, no generator

No script writes this file, and none of the steps here regenerate it (it is
loaded by every `.toc` right after `mapdata_continents.lua`). Edit it by
hand when a flavor gains or loses a continent-level map. It holds two tables:

- **`Twm_ContinentMapID`** — `{ [<Map.csv Directory>] = <uiMapID> }`, one entry
  per continent/standalone island that `candidates/continents.json` (see
  `gen_candidates.js`) lists for the flavor. The key is the same name
  `gen_mapareas.js` writes into `Twm_mapareas`; the value is the map's
  `uiMapID`, which the addon uses to read the live name and the player's
  position (`C_Map.GetMapInfo`/`C_Map.GetPlayerMapPosition`).
- **`TWM_MAPS`** — `{ [localized name] = {<Directory>} }` built from the table
  above via `C_Map.GetMapInfo(Twm_ContinentMapID[...]).name`, so the dropdown
  label always matches the client's own locale. One line per entry; add a line
  whenever an entry is added to `Twm_ContinentMapID`.

**Where the uiMapID comes from:** `<work-dir>/<flavor>/UiMapAssignment.csv`
(downloaded by `gen_mapareas.js`). Take the row whose `MapID` is the
continent's `Map.csv` `ID` and whose `AreaID` is `0` (the "whole map"
sentinel, same convention as `Twm_mapareas[continent][0]`); its `UiMapID` is
the value. When a map has several such rows (e.g. a standalone island with a
sub-zone like Lost Isles/Kezan), take the one `C_Map.GetMapInfo(uiMapID).name`
reports for the main map. Kalimdor `1414` and Eastern Kingdoms `1415` are
stable across Vanilla/TBC/Forever. Alternatively read it in game from
`C_Map.GetMapChildrenInfo(946, Enum.UIMapType.Continent, true)` (Vanilla/TBC
do this; Forever's Zephras Isle `"2991"` was derived from the CSV instead).

**`Twm_SeasonOnlyMaps` (Vanilla only, own file `Data_Vanilla/mapdata_seasons.lua`):** `{ [seasonID] = {"<Map.csv ID>", ...} }`,
hand-maintained list of dungeon/raid maps shown in the dropdown only while
`C_Seasons.GetActiveSeason()` equals the key (`2` = Season of Discovery). It is
matched against the `mapID` field that `gen_instance_maps.js` writes into every
`Twm_DungeonNames`/`Twm_RaidNames`/`Twm_ScenarioNames` entry. The DB2 tables
checked (`Map`, `LFGDungeons`, `MapDifficulty`, `GroupFinderActivity`) carry no
season field; SoD-only maps in `Map.csv` are the ones with a numeric `Directory`
(IDs from 2720). Add an ID here when a new seasonal map appears.

**`Twm_DevelopmentMaps` (all flavors, `mapdata_development.lua` in the addon root):**
hand-maintained `{"<Map.csv ID>", ...}` of maps still in development that already
have WMO or ADT data (so far: Emerald Dream, `169`). They are left out of the
dungeon/raid/scenario dropdown lists unless the "Show Development Maps" option
(`TWMOption.ShowDevelopmentMaps`) is on; matched on the same `mapID` field.

Per flavor: Vanilla has no `Expansion01` (no Outland), TBC has no Northrend,
Mists adds Northrend, Pandaria (`HawaiiMainLand`) and the standalone islands
(Deephome, LostIsles, Gilneas2, MaelstromZone, TolBarad,
MoguIslandDailyArea), Forever adds `"2991"` and has no Outland/Northrend.

## Step 3 — `parse_wdt.js`: tile validity + AreaIDs

```bash
node parse_wdt.js --work-dir <dir> --flavor <product> (--client-dir <wow-install-path> | --online) --out <out-file.lua> (--candidates <continents|battlegrounds|arenas|dungeons|raids|scenarios> | --maps <Name1,Name2,...>) [--noliquid] [--areatable-dir <dir>] [--bake-tile-fileids] [--force] [--proxy <url>]
```

- **`--work-dir`**/**`--flavor`** (required) — see step 2
- **`--client-dir`** — path to a local WoW install, for extraction
- **`--online`** — pull from the Blizzard CDN instead of `--client-dir`
- **`--client-locale`** (optional, default `enUS`) — CASCConsole's own extraction locale (`-l`); rarely needs changing
- **`--out`** (required) — output path, e.g. `Data_<Flavor>/mapdata_tiles_<kind>.lua` — one call per category now (see below), not one combined file
- **`--noliquid`** (optional) — also detect underwater tiles (noLiquid minimaps) — only meaningful for flavors with submerged zones (Mists onward: Vashj'ir, Pandaria coastline)
- **`--areatable-dir`** (optional, defaults to `<work-dir>/<flavor>`, self-downloaded) — folder containing `AreaTable.*.csv`, for the rare case you want to point it at a different snapshot
- **`--bake-tile-fileids`** (optional) — resolves each tile's minimap BLP `FileDataID` (from `<work-dir>/CASCConsole/listfile.csv`) into `Twm_TileFileID[continent][filename]`. **Only needed for a flavor where `Texture:SetTexture("World\Minimaps\...")` doesn't resolve by path string at all** — confirmed on WoW: Forever/Camelot (see `.claude-docs/gotchas.md`); every other flavor still loads fine by path and doesn't need this flag. A tile with no listfile entry gets a loud `WARNING` on stderr and falls back to the (broken, on that flavor) path string — not silently dropped.
- **`--candidates <kind>`** / **`--maps <Name1,Name2,...>`** (exactly one required) — see this README's intro; `--candidates` needs `gen_candidates.js` run first

Self-extracts (via CASCConsole) each map's own WDT/root-ADT/[noLiquid
minimap] into `<work-dir>/<flavor>/world/...` first, skipped per-map if its
own `.wdt` is already there (`--force` re-extracts).

`Twm_WDTValidTiles`/`Twm_NoLiquidTiles`/`Twm_TileFileID` are declared once,
centrally, in `mapdata_zones.lua` — this script's own output only ever
assigns `Twm_WDTValidTiles["<name>"] = {...}` per map, so one call per
category (`mapdata_tiles_continents.lua`, `mapdata_tiles_dungeons.lua`, ...)
coexists safely with the others regardless of `.toc` load order, and each
category is a single, non-repeated call — no more re-running this with a
bigger map list once `gen_battlegrounds.js`/`gen_arenas.js` discover their
own zone names (that's what `gen_candidates.js`, step 1.5, is for).

**Examples (one call per category — repeat for whichever categories this
flavor actually has, `--candidates scenarios` on a flavor with none just
prints "nothing to do" and exits cleanly):**
```bash
node parse_wdt.js --work-dir C:\wow-data --flavor wow_classic_era --client-dir "C:\Program Files\World of Warcraft" --out Data_Vanilla/mapdata_tiles_continents.lua --candidates continents

node parse_wdt.js --work-dir C:\wow-data --flavor wow_anniversary --online --out Data_TBC/mapdata_tiles_dungeons.lua --candidates dungeons

node parse_wdt.js --work-dir C:\wow-data --flavor wow_classic --client-dir "C:\Program Files\World of Warcraft" --out Data_Mists/mapdata_tiles_continents.lua --noliquid --candidates continents
```

Prints per-continent diagnostics to stderr, including `*** MISMATCH ***`
lines from built-in sanity checks — investigate before trusting the output
if any appear (a mismatch against Vanilla-era reference tiles on a
post-Cataclysm client, e.g. reshaped Azeroth tiles, is expected, not a bug).

## Step 4 — `gen_poi_areas.js`: sub-area/POI labels (`Twm_poi_areas`)

```bash
node gen_poi_areas.js --work-dir <dir> --flavor <product> (--client-dir <path> | --online) --mapareas-file <mapdata_continents.lua|mapdata_battlegrounds.lua> --out <out-file.lua> (--candidates <continents|battlegrounds> | --maps <Name1,Name2,...>) [--areatable-dir <dir>] [--force] [--proxy <url>]
```

- **`--work-dir`**/**`--flavor`**/**`--client-dir`**/**`--online`** (see step 3) — root ADTs are self-extracted per continent if not already present, same cache dir `parse_wdt.js` already populated
- **`--mapareas-file`** (required) — the flavor's own already-generated `Data_<Flavor>/mapdata_continents.lua` (step 2's output) for the usual continents pass, or `mapdata_battlegrounds.lua` (step 8's output) for the separate battleground-zone pass below
- **`--out`** (required) — output path, e.g. `Data_<Flavor>/mapdata_poi_areas.lua`
- **`--areatable-dir`** (optional, defaults to `<work-dir>/<flavor>`, self-downloaded) — folder containing `AreaTable.*.csv`
- **`--candidates <kind>`** / **`--maps <Name1,Name2,...>`** (exactly one required) — `continents` for the usual pass, `battlegrounds` for the battleground-zone pass; names must match a key in `--mapareas-file`'s `Twm_mapareas`

Algorithm (no `AreaPOI` DB2 involved — an earlier version of this script
used it, but its `Icon` field turned out to be a numeric atlas index that
shifts between client builds, plus assorted non-settlement noise):
1. **A** = the AreaIDs this continent actually displays — the keys of
   `Twm_mapareas["<Continent>"]` in `--mapareas-file`, minus the `[0]`
   whole-map sentinel.
2. **B** = every `AreaTable` row whose parent chain (`ParentAreaID`,
   walked all the way up) passes through some zone in A — every real
   sub-area/POI nested anywhere under a displayed zone — **plus** every
   top-level AreaID (`ParentAreaID` 0) not already in A. That second part
   exists for capitals with no zone box of their own — e.g. Northrend's
   Dalaran, which has no `Twm_mapareas` entry at all in some builds (no
   dedicated `UiMapAssignment` zone row) but is still real AreaTable data;
   `sets/capitals.lua` looks it up here as a fallback when `Twm_mapareas`
   has no box for a capital's AreaID.
3. Each entry in B is positioned by its own centroid — the average MCNK
   chunk position across every root ADT of that continent (same
   world→Big transform as `gen_mapareas.js`, computed straight from the
   `IndexX`/`IndexY`/`areaid` fields already used in `parse_wdt.js`). An
   AreaID never actually painted on any ADT chunk in this build is
   skipped (confirmed for Dalaran itself — it's a phased/WMO city with no
   real terrain chunks stamped with its AreaID, so it never gets a
   position at all, in any flavor). Chunks that fall outside their
   resolved top-level zone's own `Twm_mapareas` box (padded by
   `BOX_PADDING`, 2000 yards) are excluded from the average — some
   sub-areas have a near-identical duplicate copy of their own terrain
   painted thousands of yards away elsewhere on the same continent
   (confirmed for Outland's Draenei starting zone, Ammen Vale/Emberglade/
   The Sacred Grove under Azuremyst Isle — almost certainly a private copy
   used only during the starting-zone intro sequence); averaging both
   blindly lands the centroid in open ocean between them.

Each output entry is `{AreaID, "Name", x, y}` — the AreaID lets other code
(`sets/capitals.lua`) match an entry back to a known AreaID instead of just
a display name.

Known caveat: this also picks up large non-settlement sub-areas whose
`ParentAreaID` happens to point at a displayed zone — e.g. "The Great
Sea"/"The Veiled Sea" (open ocean, spread along the whole coastline, one
AreaTable row per stretch of coast). Left in as-is; prune by name/AreaID
by hand if it bothers you.

Output is one `Twm_poi_areas["<Name>"] = {...}` assignment per zone name
passed, not a single `Twm_poi_areas = {...}` literal — safe to run this
script more than once against different `--mapareas-file`s/`--out` files
(e.g. once for continents, once for battlegrounds) without one run
clobbering another's entries. `Twm_poi_areas = {}` itself is pre-declared
in root `mapdata_zones.lua`, loaded before any of these files.

**Example:**
```bash
node gen_poi_areas.js --work-dir C:\wow-data --flavor wow_anniversary --client-dir "C:\Program Files\World of Warcraft" --mapareas-file Data_TBC/mapdata_continents.lua --out Data_TBC/mapdata_poi_areas.lua --candidates continents
```

**Battlegrounds:** run this a second time against
`Data_TBC/mapdata_battlegrounds.lua`'s zone names (`PVPZone01` etc.),
writing to a separate `mapdata_poi_battlegrounds_areas.lua` (both files
assign into the same shared `Twm_poi_areas`, see the per-key-assignment
note above). A battleground has no per-zone boxes in `Twm_mapareas` (only
the `[0]` whole-map box), so "set A" for it is empty; the algorithm's
ancestor-match step accounts for this by also treating every top-level
AreaID (`ParentAreaID` 0) actually found in the map's own ADT data as a
valid ancestor, not just `--mapareas-file`'s keys — this is what lets a
battleground's real sub-areas (Frostwolf Keep, Tower Point, Stonehearth
Outpost, etc., all `AreaTable` rows parented to the battleground's own
AreaID) resolve correctly. Confirmed working for all 4 TBC/Anniversary
battlegrounds (23/2/7/4 sub-area POIs respectively).

The battleground's own top-level AreaID itself (e.g. Alterac Valley/2597)
is excluded from the output — it's the parent of the real sub-areas above,
not a sub-area itself, so including it would just duplicate the map's own
title. Detected structurally: a top-level AreaID found via the widened
ancestor-match above is excluded when something else in this same scan
resolves to it as an ancestor (i.e. it has children here); a genuine
standalone top-level landmark (Northrend's Dalaran) has none and stays.

**Example:**
```bash
node gen_poi_areas.js --work-dir C:\wow-data --flavor wow_anniversary --client-dir "C:\Program Files\World of Warcraft" --mapareas-file Data_TBC/mapdata_battlegrounds.lua --out Data_TBC/mapdata_poi_battlegrounds_areas.lua --candidates battlegrounds
```

## Step 5 — `gen_poi_graveyards.js`: graveyard/spirit-healer locations (`Twm_poi_graveyards`)

```bash
node gen_poi_graveyards.js --work-dir <dir> --flavor <product> --mapareas-file <target flavor mapdata_continents.lua> --out <out-file.lua> [--wowhead-html <saved Spirit Healer NPC page.html>] [--force] [--proxy <url>]
```

No DB2 or ADT source has graveyard locations, so this borrows Wowhead's own
["Spirit Healer" NPC page](https://www.wowhead.com/mop-classic/npc=6491/spirit-healer)
instead of hand-collecting the same data. That page embeds a
`var g_mapperData = {...}` object directly in its HTML (no JS execution
needed — plain `curl` gets it), shaped like:
```json
{"<AreaID>": [{"count": N, "coords": [[x, y], ...], "uiMapId": M, "uiMapName": "..."}]}
```
keyed by AreaTable's own **AreaID** (stable across flavors — `uiMapId` is
only carried along as a label, not used), with `coords` as 0-100
zone-relative percentages. Because the key is already a stable AreaID, no
uiMapId join is needed at all — each AreaID is looked up directly against
every continent in `--mapareas-file`.

Wowhead serves a **separately-scoped snapshot of this same NPC per game
version domain**, matching each flavor's own zone geometry — fetch the
domain matching the target flavor, not a mismatched one:

| Flavor | Wowhead domain | Confirmed scope |
|---|---|---|
| Vanilla | `wowhead.com/classic/npc=6491/spirit-healer` | 42 zones, 169 spawns — Vanilla content only |
| TBC | `wowhead.com/tbc/npc=6491/spirit-healer` | 55 zones, 251 spawns — adds Outland |
| Mists | `wowhead.com/mop-classic/npc=6491/spirit-healer` | 98 zones, 681 spawns — current post-Cataclysm world (Northrend/Pandaria/reshaped Azeroth+Kalimdor included) |
| Forever | `wowhead.com/forever/npc=6491/spirit-healer` | Classic+ content |

This script downloads the right domain itself, keyed off `--flavor`
(`wow_classic_era`→`classic`, `wow_anniversary`→`tbc`, `wow_classic`→`mop-classic`,
`wow_classic_beta`→`forever`), into `<work-dir>/<flavor>/spirit_healer.html` —
`curl -A "Mozilla/5.0" <url>` under the hood, cached same as everything else.
Pass `--wowhead-html <saved page.html>` to override this with your own saved
copy instead (offline work, manual testing, or a flavor not in the table
above).

- **`--work-dir`**/**`--flavor`** (required) — also self-downloads `AreaTable`/`UiMap`/`UiMapAssignment` CSVs, used for the fallback resolution below
- **`--mapareas-file`** (required) — the target flavor's own
  `mapdata_continents.lua`. Every continent block in it is scanned (not just
  one), and each `g_mapperData` AreaID is looked up directly against
  whichever continent actually declares that AreaID — supplies the zone's
  own box, in this flavor's own Big-coordinate space, via `Twm_mapareas`.
- **`--out`** (required) — output path, e.g. `Data_<Flavor>/mapdata_poi_graveyards.lua`
- **`--wowhead-html`** (optional) — overrides the self-downloaded page (see above)

An AreaID from the page with no matching box in `--mapareas-file` (e.g. a
zone from a later expansion this flavor doesn't have, **or** a small
starting-experience camp `gen_mapareas.js` excluded from the zone dropdown
for not being a top-level `AreaTable` entry — Camp Narache, Gilneas City,
...) still resolves via the self-downloaded `AreaTable`/`UiMapAssignment`:
its own box comes straight from `UiMapAssignment.csv` (not its parent
zone's box, which would place the point wrong, not just approximately — the
percentages are relative to that AreaID's own map), and which output
section it goes under comes from walking `AreaTable`'s `ParentAreaID` chain
up to whichever ancestor **is** in `--mapareas-file`. Confirmed for Mists:
Gilneas2 alone has two disjoint sets of real graveyards on Wowhead, one
keyed to Gilneas City, one to Gilneas itself — this fallback is what keeps
both instead of losing one silently.

Dedup (see below) runs per output continent across every AreaID that landed
there, not per AreaID — a zone and a sub-area of it (Gilneas/Gilneas City)
can each contribute points close enough together to be the same physical
graveyard, and only whole-continent dedup catches that. Skip count (fully
unresolvable AreaIDs) is printed to stderr; Mists still skips ~36 (non-open-
world/instance-only zones not part of this addon's continent list at all).

**Example:**
```bash
node gen_poi_graveyards.js --work-dir C:\wow-data --flavor wow_classic_era --mapareas-file Data_Vanilla/mapdata_continents.lua --out Data_Vanilla/mapdata_poi_graveyards.lua
```

## Step 6 — `gen_poi_instances.js`: dungeon/raid entrance markers (`Twm_instances`)

```bash
node gen_poi_instances.js --work-dir <dir> --flavor <product> --teleport-csv <id-to-target-map reference CSV> --mapareas-file <target flavor mapdata_continents.lua> --out <out-file.lua> [--force] [--proxy <url>]
```

Self-downloads `AreaTrigger`/`Map` CSVs from wago.tools. `--teleport-csv`
stays a manually-supplied file — no CASC/DB2 source has this mapping at all
(see below), so there's nothing to self-fetch there.

No official client DB2 table encodes which map an `AreaTrigger` teleports
you to — that link isn't part of what the client ever receives (confirmed
by exhaustively checking every `AreaTrigger`-related DB2 table:
`AreaTriggerActionSet` has no map reference, `AreaTriggerAction` doesn't
exist for these clients, and cross-referencing a trigger's outdoor position
against `Twm_poi_areas` mostly returns the wrong name — e.g. Deadmines'
entrance resolves to "Demont's Place", an unrelated nearby landmark). So
this needs a separate `id -> target_map` reference table (`--teleport-csv`,
columns: `id, target_map` at minimum — extra columns are ignored) from
outside the normal CASC/DB2 pipeline, one per flavor.

Algorithm:
1. Every `AreaTrigger` row whose `ContinentID` is a `Map.csv` row matching a
   continent actually declared in `--mapareas-file`'s `Twm_mapareas` (an
   open-world map, not some other random MapID).
2. ...that also has a matching row in `--teleport-csv` — i.e. it's an
   actually-functional teleport trigger, not some other kind of
   `AreaTrigger` (ambience, quest zones, PvP flags, etc.).
3. ...whose `target_map` is itself a dungeon or raid (`Map.InstanceType` 1
   or 2) — excludes battlegrounds/scenarios/whatever else teleports exist
   for (both are entered through their own queue systems, not a walk-through
   trigger, so they never have a `--teleport-csv` row to begin with).
4. `Map.MapName_lang` is written too, but only as a fallback — `sets/dungeons.lua`
   resolves the live, locale-correct name at render time via
   `GetRealZoneText(MapID)`, which accepts this same `target_map`/`Map.ID`
   value directly (confirmed: `GetRealZoneText(530)` returns `"Outland"`,
   and `530` is `Map.ID` for `Expansion01`). Type is `"Dungeon"` or `"Raid"`
   (from `InstanceType`), which doubles as the icon name this addon draws
   for it (`Icon-Dungeon` / `Icon-Raid` — see `sets/dungeons.lua`).

Each output entry is `{"Type", MapID, "Name", x, y}`.

Multiple trigger boxes for the same physical door (confirmed: Stratholme's
main gate and Karazhan's entrance each have 2 adjacent trigger boxes) are
merged by centroid if they're within `DEDUP_DISTANCE` (15 yards) of another
point with the exact same resolved name — distinct entrances to the same
dungeon (Dire Maul's 3 wings, Maraudon's 2 mouths, Scarlet Monastery's 4
wings) are far enough apart to survive as separate points, and two
different dungeons/raids are never merged into each other even if their
entrances happen to be close together. The distance threshold is a
compromise, not exact — some legitimately-separate doors on the same
building can be closer together than some duplicate boxes on one door, so a
dungeon can occasionally end up with 2 near-overlapping markers for what's
really one entrance (cosmetic only, not wrong data).

**Example:**
```bash
node gen_poi_instances.js --work-dir C:\wow-data --flavor wow_classic_era --teleport-csv C:\wow-data\areatrigger_teleport.csv --mapareas-file Data_Vanilla/mapdata_continents.lua --out Data_Vanilla/mapdata_poi_instances.lua
```

## Step 7 — `gen_poi_flightmasters.js`: flight master markers + routes (`Twm_flightmasters`, `Twm_taxipaths`, `Twm_taxipathnodes`)

```bash
node gen_poi_flightmasters.js --work-dir <dir> --flavor <product> --mapareas-file <target flavor mapdata_continents.lua> --out <out-file.lua> [--force] [--proxy <url>]
```

- **`--work-dir`**/**`--flavor`** (required) — also self-downloads `TaxiPath`/`TaxiPathNode`/`Map` CSVs, plus `TaxiNodes.<locale>.csv` into `<work-dir>/<flavor>/locales/` for every supported locale: `enUS`/`deDE`/`esES`/`esMX`/`frFR`/`itIT`/`koKR`/`ptBR`/`ruRU`/`zhCN`/`zhTW`. `enUS` is also the structural source of truth for every non-name field (`Flags`/`CharacterBitNumber`/`Pos`/`ContinentID` are identical across every locale's export of the same row, only `Name_lang` differs); a missing locale is skipped with a warning (not a hard failure).
- **`--mapareas-file`** (required) — the flavor's own `Data_<Flavor>/mapdata_continents.lua` (step 2's output)
- **`--out`** (required) — output path, e.g. `Data_<Flavor>/mapdata_poi_flightmasters.lua`

Flight masters have no AreaID/MapID of their own to resolve a live,
locale-correct name from at render time the way Landmarks/Capitals/Dungeons
do (see `.claude-docs/architecture.md`'s live-name-resolution section) — so
every locale's name is baked in at generation time instead, one column per
locale, and `TaxiRoutes.lua` (`TWM_ResolveLocaleName`) picks the
client's own locale out of that table at load time (falling back to `enUS`
if that locale's file was missing, or for `enGB`/`ptPT` clients, which
wago.tools doesn't export separately from `enUS`/`ptBR`).

Faction (`Twm_flightmasters`' second field) is derived from `TaxiNodes.Flags`,
a bitmask: bit `0x1` = Alliance, bit `0x2` = Horde (confirmed against
known-faction hubs, e.g. Stormwind/Ironforge = 1, Undercity/Tarren Mill = 2).
Neither bit set or both set both mean "usable by both factions" (confirmed
against Booty Bay/Gadgetzan — genuinely neutral — and the Eastern
Plaguelands faction-war towers — explicitly both-usable) — mapped to
`"Neutral"` either way, there's no behavioral difference between them here.

`TaxiNodes.db2` also carries rows that aren't real, player-choosable flight
points — boat/zeppelin dock waypoints (`"Transport, ..."`), one-off scripted
quest flights (`"Quest Path ...: ..."`), a dev-only island
(`"Programmer Isle"`), and generic scripted targets (`"Generic, ..."`).
Used to be filtered by a name-prefix heuristic, but every one of these rows
already has `Flags == 0` (neither faction bit) — confirmed empirically
across all 4 flavors' full `TaxiNodes` tables, 0 false negatives — so the
faction-flags check below already drops all of them on its own; the name
pattern never earned its keep over a plain DB2 field check, so it was
removed.

A node with zero `TaxiPath` rows referencing it (either direction) is
dropped too, regardless of name — confirmed against WoW: Forever's own
`"zzOLD..."` rows (Blizzard's rename-instead-of-delete convention for
deprecated/replaced data, e.g. `"zzOLDBolder'ok, Riverglades"`), which pass
every other check but lead nowhere at all. Structural, not a name pattern,
so it also catches anything similar in the future without needing an
update here.

`Twm_flightmasters[continent]` entries are
`{id, faction, name = {enUS = ..., deDE = ..., ...}, x, y}` — named fields
(unlike every other `Twm_poi_*` table's positional arrays) specifically to
fit the per-locale `name` table in cleanly. `id` is the TaxiNode ID, kept so
`TaxiRoutes.lua` can join it against `Twm_taxipaths` at load time.
`Twm_taxipaths` is the **raw** `TaxiPath.db2` table — `{ID, FromTaxiNode, ToTaxiNode}`
— filtered only to rows where both endpoints survived the junk/continent
filter above. Deliberately **not** deduped (`TaxiPath.db2` rows are
directional — both an A→B and a B→A row can exist for the same real route)
and **not** grouped/restricted by continent — `TaxiRoutes.lua` builds both a
per-node neighbor list (hover-preview lines) and a deduped, same-continent-only
route list (the "always show" toggle) from this raw data at load time,
since the dedup depends on which pairs resolve to the same continent, which
is runtime-only information.

`Twm_taxipathnodes[pathID]` holds `TaxiPathNode.db2`'s actual spline
points (`{x, y}`, ordered by `NodeIndex`), only for `PathID`s that survived
into `Twm_taxipaths` above (junk/filtered routes don't drag their spline
data along). `FlightPaths.lua` draws the straight endpoint-to-endpoint line
by default and only walks this curved spline while **Shift is held** — the
default stays cheap (one segment per route) and the curved view is opt-in
per-glance, not something drawn continuously (drawing hundreds/thousands of
spline segments at once is measurably more expensive to keep positioned
during a live pan/zoom than the straight-line default — see
`.claude-docs/gotchas.md`).

**Example:**
```bash
node gen_poi_flightmasters.js --work-dir C:\wow-data --flavor wow_classic_era --mapareas-file Data_Vanilla/mapdata_continents.lua --out Data_Vanilla/mapdata_poi_flightmasters.lua
```

## Capitals — no generator, computed live in Lua

Unlike the other POI categories above, capital-city markers (`sets/capitals.lua`,
`Icon-City`) have **no `gen_poi_*.js` script and no `Data_<Flavor>/mapdata_poi_*.lua`
file** — a capital's position is just its own zone box's center, which is
already sitting in `Twm_mapareas` (step 2's output), so there was nothing
worth precomputing. At runtime, for each AreaID in `mapdata_zones.lua`'s
`Twm_CapitalAreaIDs`, `sets/capitals.lua` takes `Twm_mapareas[map][areaID]`'s
box center, falling back to a `Twm_poi_areas` entry with the same AreaID
(step 4's top-level-zone case) for capitals with no zone box of their own
(e.g. Northrend's Dalaran). Names resolve live via `Twm_areadb`/
`C_Map.GetAreaInfo`, same as landmarks — see `.claude-docs/architecture.md`.

## Step 8 — `gen_battlegrounds.js`: battleground maps (`Twm_BattlegroundMapID`, `TWM_BATTLEGROUNDS`, `Twm_mapareas`)

```bash
node gen_battlegrounds.js --work-dir <dir> --flavor <product> --out <out-file.lua> [--force] [--proxy <url>]
```

- **`--work-dir`**/**`--flavor`** (required) — also self-downloads `Map`/`UiMapAssignment` CSVs
- **`--out`** (required) — output path, e.g. `Data_<Flavor>/mapdata_battlegrounds.lua`

Re-run whenever a flavor's battleground list changes (a DBC snapshot moving
on, e.g.). Same top-level-map shape as `gen_mapareas.js`'s
continents (`Map.csv` row with `ParentMapID=-1`, `MapType=1`), just
`InstanceType=3` instead of `0`. Unlike continents, a battleground has no
separate "whole map" `UiMapAssignment` root row (`Type=2`/`System=0`/`AreaID=0`)
— it's just one Zone row directly (unioned if a battleground ever has more
than one), which doubles as both the `[0]` box **and** the position-tracking
`UiMapID`. Every `UiMapAssignment` row for the battleground's `MapID` is
taken, with **no `UiMap.Type` filter** — the structural Map.csv filter above
already uniquely identifies a real battleground, and every one checked so
far has its own single, self-consistent `Type` across all its rows anyway
(`3`/`UI_MAP_TYPE_ZONE` on Vanilla/TBC/Mists, `6`/`UI_MAP_TYPE_ORPHAN` on
WoW: Forever/Camelot, `4`/`UI_MAP_TYPE_DUNGEON` for Silvershard Mines
specifically — Blizzard nests it like a dungeon since it's an underground
instance). An earlier version of this script whitelisted `Type` values
instead of just matching on `MapID`, which is exactly how Silvershard Mines
got silently missed for a while — don't reintroduce that.

A `Map.csv` row matching the structural filter but with zero matching
`UiMapAssignment` rows (checked, not just assumed) has no map data to
generate at all yet in that build and is skipped — e.g. Forever's "Battle
for Gilneas" (MapID 3005) as of this writing.

Deliberately writes `Twm_BattlegroundMapID`/`TWM_BATTLEGROUNDS` as their own
tables, separate from `Twm_ContinentMapID`/`TWM_MAPS` — see this script's own
header comment for why (short version: they're for a different dropdown
category, even though the runtime position-tracking code doesn't care which
table a map came from). `Twm_mapareas` entries are added under the
battleground's own key, into the same table `gen_mapareas.js`'s continents
already populate.

Battlegrounds are real outdoor ADT terrain, unlike dungeon/raid interiors —
`parse_wdt.js` handles them exactly like a small continent, via its own
`--candidates battlegrounds` pass (step 3), writing to its own
`mapdata_tiles_battlegrounds.lua` — safe as a separate file from the
continents' own `mapdata_tiles_continents.lua` because `Twm_WDTValidTiles`
is declared once, centrally, in `mapdata_zones.lua` (not reset per file
anymore).

**`gen_candidates.js` (step 1.5) is a hard prerequisite for this script
itself, not just for `parse_wdt.js`** — `findBattlegrounds` (the structural
Map.csv filter + `skipMaps`) only ever runs inside `gen_candidates.js` now;
this script's own `main()` reads back `candidates/battlegrounds.json` (by
`Map.csv` `ID`) instead of re-deriving the same candidate list a second
time, only re-deriving each one's box/`UiMapID` from `UiMapAssignment`
(not carried in the lightweight JSON). Run `gen_candidates.js` first.

**Example (TBC):**
```bash
node gen_battlegrounds.js --work-dir C:\wow-data --flavor wow_anniversary --out Data_TBC/mapdata_battlegrounds.lua
```

**Battlegrounds found per flavor** (as of this writing — re-run
`gen_battlegrounds.js` to pick up any new ones):
- **Vanilla**: PVPZone01 (Alterac Valley), PVPZone03 (Warsong Gulch), PVPZone04 (Arathi Basin)
- **TBC**: the above + NetherstormBG (Eye of the Storm)
- **Mists**: the above + NorthrendBG (Strand of the Ancients), IsleofConquest
  (Isle of Conquest), CataclysmCTF (Twin Peaks), STV_Mine_BG (Silvershard
  Mines), Gilneas_BG_2 (The Battle for Gilneas), EyeoftheStorm2.0 (Rated Eye
  of the Storm), ValleyOfPower (Temple of Kotmogu), GoldRushBG (Deepwind
  Gorge), WintergraspEpic (Wintergrasp), `2755` (Battle for Tol Barad) — 14
  total (was last regenerated missing 8 of these; the DBC snapshot had
  simply moved on without a re-run)
- **Forever**: PVPZone01/03/04 + `2997` (Darkspear Islands) — no Eye of the Storm/Wintergrasp/Tol Barad in this build yet

## Step 9 — `gen_arenas.js`: arena maps (`Twm_ArenaNames`, `Twm_mapareas`)

```bash
node gen_arenas.js --work-dir <dir> --flavor <product> --tiles-file <mapdata_tiles_arenas.lua, from parse_wdt.js --candidates arenas> --out <out-file.lua> [--force] [--proxy <url>]
```

Same structural Map.csv filter as `gen_battlegrounds.js` (`ParentMapID=-1`,
`MapType=1`), just `InstanceType=4` (`MAP_ARENA`) instead of `3`. Arenas
differ from battlegrounds in two ways that shape this whole script:

- **Zero `UiMapAssignment` rows at all** (checked directly on TBC and
  Mists — every arena MapID matches zero rows, not just zero Zone-type
  ones) — Blizzard never wired arenas into the World Map system, even
  though their terrain is real (a full WDT/ADT tile grid, same as any
  other map). So there's no Region box to read, and no UiMapID either —
  meaning no position tracking and no `TWM_GetContinentForMapID` hint are
  possible for an arena; selecting one from the dropdown is the only way
  to view it.
- Consequently this script needs two things no other generator does:
  - **`--tiles-file`**: a box derived from valid-tile extent instead of a
    DBC Region box. Run `parse_wdt.js --candidates arenas` first (step 3,
    needs `gen_candidates.js` run beforehand), then point this at that
    output (`mapdata_tiles_arenas.lua`). The tile index range is converted
    to Big coordinates through
    `TWM_Mini2Big_Coord`'s own formula (`TerrainWorldMap.lua`) —
    `x/y = (index-32)*-533.3333` — the same conversion
    `WorldMapOverlay.lua`'s `DrawTiles` already uses to place each tile.
  - **Per-locale names**: with no live uiMapID, there's no
    `C_Map.GetMapInfo(uiMapID).name` to resolve a client-locale name from
    either (unlike `Twm_BattlegroundMapID`) — names are baked in per
    client locale instead, self-downloaded (`Map.<locale>.csv`) the same
    way and for the same 11 locales as `gen_poi_flightmasters.js`'s
    `TaxiNodes.<locale>.csv`. Output shape mirrors `Twm_flightmasters`'s name
    tables too: `Twm_ArenaNames = {{key=..., name={enUS=..., deDE=...}}, ...}`,
    resolved into the actual `TWM_ARENAS` dropdown table (`{name: {key}}`,
    same shape as `TWM_BATTLEGROUNDS`) at load time in `TerrainWorldMap.lua`
    via `TWM_ResolveLocaleName` (`TaxiRoutes.lua`, a generic `{locale: name}`
    resolver already used for flight masters; falls back to enUS same as
    those).

**Example (TBC):**
```bash
node parse_wdt.js --work-dir C:\wow-data --flavor wow_anniversary --client-dir "C:\Program Files\World of Warcraft" --out Data_TBC/mapdata_tiles_arenas.lua --candidates arenas
node gen_arenas.js --work-dir C:\wow-data --flavor wow_anniversary --tiles-file Data_TBC/mapdata_tiles_arenas.lua --out Data_TBC/mapdata_arenas.lua
```
One call each now, and this script no longer derives its own candidate list
at all — `findArenas` (the structural Map.csv filter + `skipMaps`) only
ever runs inside `gen_candidates.js`; `gen_arenas.js`'s own `main()` reads
`candidates/arenas.json` back (by `Map.csv` `ID`, for its locale-independent
Directory/enUS-name fields). `gen_candidates.js` is a hard prerequisite for
this script now, same as `gen_battlegrounds.js` above — see
`.claude-docs/gotchas.md` for the two bugs this replaced (a silent 2-pass
requirement, and `skipMaps` never actually being checked here).

**Arenas found per flavor** (as of this writing):
- **Vanilla**: none (arenas didn't exist yet)
- **TBC**: Nagrand Arena, Blade's Edge Arena, Ruins of Lordaeron
- **Mists**: the above + Dalaran Sewers, The Ring of Valor, Tol'Viron Arena, The Tiger's Peak
- **Forever**: `2995` (Hyjal Crater) — none of the above exist in this build yet

## Step 10 — `gen_wmo_tiles.js`: WMO minimap-tile overlay (`Twm_WMOTiles`)

```bash
node gen_wmo_tiles.js --work-dir <dir> --flavor <product> (--client-dir <path> | --online) --out <out-file.lua> (--candidates <dungeons|raids|arenas> | --maps <Name1,Name2,...>) [--force] [--proxy <url>]
```

`--candidates` only ever makes sense as `dungeons`/`raids`/`arenas` here —
continents/battlegrounds never have any baked WMO tiles at all (confirmed:
neither ever appears as a key in a real `mapdata_wmo_tiles_*.lua`), so
`continents`/`battlegrounds` aren't valid values. One call per category,
writing its own `mapdata_wmo_tiles_<kind>.lua` (`Twm_WMOTiles` itself is
declared once, centrally, in `mapdata_zones.lua`, same reasoning as
`Twm_WDTValidTiles` in step 3).

**Example (TBC, one call per category):**
```bash
node gen_wmo_tiles.js --work-dir C:\wow-data --flavor wow_anniversary --client-dir "C:\Program Files\World of Warcraft" --out Data_TBC/mapdata_wmo_tiles_dungeons.lua --candidates dungeons
node gen_wmo_tiles.js --work-dir C:\wow-data --flavor wow_anniversary --client-dir "C:\Program Files\World of Warcraft" --out Data_TBC/mapdata_wmo_tiles_raids.lua --candidates raids
node gen_wmo_tiles.js --work-dir C:\wow-data --flavor wow_anniversary --client-dir "C:\Program Files\World of Warcraft" --out Data_TBC/mapdata_wmo_tiles_arenas.lua --candidates arenas
```

Self-extracts in two passes: each map's own obj0 ADTs/WDT first (to find
`MODF` placements at all), then — once those placements are resolved
against the community listfile (`<work-dir>/CASCConsole/listfile.csv`,
prepared by `init_workdir.ps1`) — exactly the WMO group model files (by
path) and minimap BLPs (by FileDataID, straight from `WMOMinimapTexture`, so a
tile with no listfile name yet is still extracted) those placements actually need. This closes a real gap: unlike
every other step above, extracting these files was never automated before
this refactor — they had to be pulled by hand with your own CASCConsole
invocation.

Naming here is deliberately map-generic, not arena-specific — the same
WMO-minimap-tile system applies equally to arenas, dungeons, and raids.
Finds placements from a map's own per-ADT `MODF`s first; if a map has none
at all (most classic 5-man dungeons/raids — a single global WMO, no real
ADT terrain), falls back to the WDT-level `MODF` instead (guarded by
`MPHD.flags & 0x1` — see `.claude-docs/gotchas.md`'s "Detecting a pure WMO
dungeon" entry), same detection `preview_wmo_tiles.js` already had. This
fallback was missing for a while after yaw support landed (this file's own
header used to say so) — confirmed the gap the hard way: Ragefire Chasm and
Onyxia's Lair both silently produced 0 tiles despite having real baked
minimap art, because only the per-ADT scan existed here at the time.

Some maps have a WMO placement with its own baked group-minimap tiles
(`world/minimaps/wmo/.../<name>_<group>_<blockX>_<blockY>.blp`, same system
as WMO dungeon interiors, `.claude-docs/gotchas.md`) worth showing as an
overlay — most usefully on Dalaran Sewers Arena (whose outdoor terrain has
ZERO baked `world/minimaps/<map>/*.blp` tiles at all), but this is
generated independently of whether the map's own outdoor terrain also has
real minimap art (confirmed: Orgrimmar Arena has both — its outdoor tiles
extract fine and already show the complete arena, but its WMO tiles are
still generated too, since the height-cutoff slider (see below) needs them
to isolate one real building level; a flattened outdoor tile can't do
that). This script finds WMO placements via `MODF`, then resolves each
placement's real tile list from the **`WMOMinimapTexture` DB2 table**
(`ID, GroupNum, BlockX, BlockY, FileDataID, WMOID`) — **not** by pattern-
matching tile filenames in the community listfile, an earlier approach
replaced 2026-09-30 after it shipped 20 "ghost" tiles for Razorfen Downs
(a WMO group whose baked tiles the aggregate community listfile still
listed, but this build's own CASC archive and its own `WMOMinimapTexture`
both agree don't exist — confirmed by two separate extraction attempts,
including a full wildcard sweep of the WMO's own minimap directory, finding
zero matching files). The DB2 table is generated fresh per build, so it
can't carry that kind of cross-build staleness; switching to it also
silently fixed the exact same class of stale-tile bug on 8 OTHER TBC
dungeons/raids that had never been individually diagnosed (see
`.claude-docs/gotchas.md` for the full account). `WMOMinimapTexture.WMOID`
is **not** a FileDataID — it's a separate internal identifier stored in the
WMO root file's own `MOHD` chunk (a `uint32` at offset 32, right after
`ambColor` and right before the bounding box), so this script still has to
extract each placement's root `.wmo` file and read that field to know which
`WMOMinimapTexture` rows are its own:

- Scans each map's `world/maps/<map>/*_obj0.adt` files for `MODF`
  chunks (64-byte entries: `nameId`(0)/`uniqueId`(4)/`position`
  float32[3](8, order X/height/Y)/`rotation` float32[3](20, same order)/
  bounds(32,44)/`flags`(56)/`doodadSet`(58)/`nameSet`(60)/`scale`(62)),
  deduped by `uniqueId` (one placement repeats in every ADT tile it
  straddles; deduping by `nameId` dropped distinct placements of the same WMO).
- One streaming pass over the community listfile resolves each placement's
  `nameId` to its WMO root path; those root files are then self-extracted
  and each one's `MOHD.WMOID` (offset 32) read directly, which is looked up
  in `WMOMinimapTexture.csv` (self-downloaded like any other DB2 CSV) for
  that WMO's real `{GroupNum, BlockX, BlockY, FileDataID}` tile list. A
  second, narrower listfile pass then resolves only those specific
  FileDataIDs to their own paths, for extraction and BLP-dimension reading.
- **Rotation scope**: yaw (the Y rotation) is applied; a placement with a real
  pitch/roll (non-zero rotation on the other two axes, e.g. Tanaris' abandoned
  orc tower, Caverns of Time's ogre mound) is skipped with a console warning,
  not supported.
- **Tiles without a file are dropped**: a tile whose FileDataID is in
  `WMOMinimapTexture` but whose BLP is not in the client (CASC returns nothing)
  is skipped with a `not in client -- skipped` warning instead of being drawn at
  a guessed size. A tile's real width/height comes from its BLP header
  (cropped tiles exist, 16x16 up to 128x128 units).
- **Per-flavor filters** (`skip_lists.js`): `skipWmoTiles` (whole map),
  `skipWmoGroups` (single `"<WMOID>-<GroupNum>"`), `skipTileFileDataId`
  (one texture), `checkedWmoAreasByMap` (allowlist box per map).
- Each WMO group's own local bounding box (`MOGP` chunk, offset 12 within
  its data: `flags`(4) then `bboxMin`/`bboxMax` `C3Vector`(12 each), plain
  `(X,Y,Z=height)` order — NOT the same reordering `MODF` uses) sets that
  group's tile-grid origin: `local.X = bbox.minX + blockX*128` (128
  model-units per 256px tile, fixed `PPU=2`, same constant as WMO dungeon
  interiors) — `blockX` reads directly against `box[0]`, no swap with
  `box[1]`.
- `local.Y` is the model's own Y, mirrored about local 0 (no flip around the
  tiled groups' bbox): `y = bbox.minY + blockY*128` (+ real tile height for
  the far edge) is passed as the first argument of the placement transform.
  The earlier "flip about the tiled groups' bbox centre" was only right for
  single-group maps; see gotchas.md ("WMO-tile world position", step 2) and
  `audit_wmo_extents.js` for the verification against `MODF.extents`.
- Local coordinates then get a fixed 90°-clockwise rotation —
  `(local.X, local.Y) -> (-local.Y, local.X)` — correcting for a real
  property of Blizzard's own WMO-minimap-tile baking convention (also true
  for WMO dungeon interiors; confirmed against the real in-game Minimap).
- Model→Big: `Big = (MAP_ORIGIN - MODF.position[x,z]) + rotateOnly(y, x)`
  (`MAP_ORIGIN = 32*(1600/3)`, `rotateOnly` = the placement's yaw applied to
  the rotated local vector `(y, x)`, `yawRad = -rot[1]`). The anchor is the
  raw `MODF.position`, with no pivot taken from the tiled groups' bbox — no
  cross-swap (this addon's usual "Big-X = world-Y" convention is calibrated
  for other sources, not a value already in `MODF`'s own axis order).
  `TerrainWorldMap.lua`'s `TWM_WMOOverlay_Update` has no rotation/flip logic
  of its own — it reads these Big coordinates the same direct way the base
  map tiles do. The one thing that DOES still live in Lua is the matching
  texture-CONTENT rotation (`TWM_WMOOverlay_EnsureTexture`'s
  `SetTexCoord(0,1, 1,1, 0,0, 1,0)`, the 8-param form) — a separate concern
  (what each tile's own pixels show, not where its box goes).
  See `.claude-docs/gotchas.md`'s "WMO-tile world position" entry for the
  reference implementation used, the full derivation of all of the above,
  and several reusable lessons from getting each step wrong at least once
  before landing here.
- **A `--maps` value must match the map key's exact DB2 `Directory`
  casing** (`gen_arenas.js`'s output key, e.g. `DalaranArena`,
  `OrgrimmarArena`), not whatever case the on-disk extracted folder happens
  to use (Windows filesystem paths are case-insensitive, so
  `world/maps/dalaranarena/` resolves fine even when passed `DalaranArena`
  — the arg only needs to match on disk, but it also becomes the output
  Lua table's key verbatim, which DOES need to match `frame.opt.Map`
  exactly). Passing the on-disk lowercase folder name as the arg (as this
  script's own name suggests) silently produces a working file with the
  wrong keys — no error, `Twm_WMOTiles[frame.opt.Map]` just always
  misses.
- Output: `Twm_WMOTiles["<map>"] = { {group_id = "<WMOID>-<GroupNum>",
  group_name = "<MOGN name or Group N>", tiles = { {fileID, cx, cy, width,
  height, yawDeg, z, c1x,c1y, c2x,c2y, c3x,c3y, c4x,c4y}, ... }}, ... }`, groups
  sorted by (WMOID, GroupNum). `cx/cy` = tile centre (Big coordinates),
  `width/height` = the tile's real footprint from its BLP header, `yawDeg` = the
  placement's yaw, `z` = `MODF.position[1]` + the group's LOWEST bbox Z (the same
  key wow.export sorts by), c1..c4 = the real corners.
  Rendered in `TerrainWorldMap.lua` (`TWM_WMOOverlay_Update`): the enabled groups
  are ranked by `z` (ties keep data order) and each group's tiles go into their
  own child frame of ViewFrame whose frame level is that rank, so the stacking
  depth is unlimited (see `.claude-docs/gotchas.md`, "WMO overlay stacking").
  Shown only for a map that has an entry in this table; the "Show WMO Layers"
  checkbox (`TWMFrameShowWMOOverlayButton`) appears when the map also has ADT
  terrain, a horizontal height-cutoff slider when the tiles span more than one
  height, and the "WMO Tile Management" option adds one checkbox per group
  (`.claude-docs/architecture.md`).

**Generated so far** (counts change with every regen; re-check the data files,
or run `audit_wmo_extraction.js`, before trusting an old "produces 0" claim --
several turned out to be un-extracted files or a missing WDT-level `MODF`
check). Maps with at least one tile: Vanilla 28 dungeons / 10 raids; TBC 31 /
14 / 1 arena; Mists 75 / 29 / 4 arenas; Forever 33 / 12 / 1 arena. A map with 0
tiles has no baked minimap art for its WMO in that build (confirmed against
`WMOMinimapTexture`, not an extraction gap) -- e.g. Forever's Blackrock Depths,
whose rebuilt WMO (`autogen-names/unknown/21773.wmo`, WMOID 21773) has no rows
in the table.

## Other scripts

- **`skip_lists.js`** — not a runnable script, a shared hand-maintained data
  module (`skipMaps`/`skipAdtTiles`/`skipWmoTiles`, keyed by product code ->
  array of `Map.csv` `ID` values). Grown incrementally as test viewing turns
  up a map whose generated tiles are simply wrong (a WMO placement or ADT
  tile-validity result that doesn't belong there, not a bug in the
  extraction/placement math itself — that class of bug gets fixed at the
  source instead). `skipMaps` excludes a map from `gen_instance_maps.js`'s
  own candidate list entirely; `skipAdtTiles`/`skipWmoTiles` keep the map but
  force `parse_wdt.js`/`gen_wmo_tiles.js` to skip just that one tile layer for
  it (read by `TerrainWorldMap.lua`'s `TWM_MapHasTerrain`/the Show
  Terrain/Show WMO Layers checkbox logic exactly like a map that genuinely
  never had that layer). `skipWmoGroups` is not keyed by map: it lists single
  WMO groups to drop (all of their tiles) as `"<WMOID>-<GroupNum>"` strings,
  the same `group_id` that `Twm_WMOTiles` and the WMO tile management list
  show (e.g. `'1356-10'`); read by `gen_wmo_tiles.js`. See the file's own
  header for the full rationale. Not currently wired into `gen_arenas.js`/`gen_battlegrounds.js` — only the
  three consumers above needed it so far.

- **`audit_wmo_extraction.js`** — standalone diagnostic tool, not part of the
  pipeline above. For one or more maps, lists every real `MODF` placement
  that has ANY baked WMO minimap tile at all (checked against the community
  listfile, independent of local extraction state) and reports exactly
  which local files (root/group `.wmo`, minimap `.blp`) are still missing:
  ```bash
  node audit_wmo_extraction.js --work-dir <dir> --flavor <product> <MapDirectoryName> [<MapDirectoryName> ...]
  ```
  Read-only — reports what is/isn't extracted yet under `<work-dir>/<flavor>/`,
  never extracts anything itself (that's the opposite of its own point).
  Written after `gen_wmo_tiles.js` silently produced 0 tiles for a couple of
  arenas that turned out to have real, un-extracted WMO structure (Ruins of
  Lordaeron on both TBC and Mists) — `gen_wmo_tiles.js` itself only warns
  about a missing GROUP file once it already knows a WMO has baked tiles,
  it says nothing when the WMO's root/all groups are missing outright (the
  `if (!tiles...) continue` and un-extracted-root cases are silent by
  design, to avoid spamming a warning for every ordinary undecorated
  placement) — this script exists specifically to catch that gap without
  reading `gen_wmo_tiles.js`'s own source by hand each time.

- **`gen_area_centroids.js`** — standalone diagnostic tool, not part of the
  pipeline above. Dumps every AreaID's centroid for a continent
  (`Twm_area_centroids["<Continent>"][areaID] = {x, y}`) and, given
  `--mapareas-file`, self-checks each zone's rolled-up centroid against
  its `Twm_mapareas` bounding box. Useful for validating the ADT
  chunk-position formula (`gen_poi_areas.js` duplicates the same
  computation internally) or just inspecting where a given AreaID
  actually sits. Takes `--candidates <kind>` / `--maps <Name1,Name2,...>`
  same as `parse_wdt.js` (step 3) — usually `--candidates continents`.

- **`preview_wmo_tiles.js`** — standalone diagnostic tool, not part of the
  pipeline above and not run against every map. Composites one map's WMO
  minimap tiles (step 10's `Twm_WMOTiles` source data, before it's written
  to Lua) into a single PNG, colored and numbered per WMO group, so a new
  candidate map or a change to the shared placement math can be sanity-
  checked by eye before touching the addon's shipped Lua data:
  ```bash
  node preview_wmo_tiles.js --work-dir <dir> --flavor <product> (--client-dir <path> | --online) (--out <out.png> | --dump-tiles-dir <dir>) [--with-adt-tiles] <MapDirectoryName>
  ```
  `--dump-tiles-dir <dir>` additionally (or instead of `--out`) writes every
  individual baked WMO minimap tile out as its own PNG at its real
  (possibly-cropped) native size, named `<FileDataID>.png` — useful to
  eyeball one raw tile texture on its own (e.g. to find the exact
  FileDataID of a bad/misplaced tile worth adding to `skip_lists.js`'s
  `skipTileFileDataId`), not just the composited overlay. FileDataID is
  resolved from the same community listfile pass already done to turn a
  `MODF`'s `nameId` into a WMO path, just matched the other direction (local
  relative path → ID).
  Self-extracts the same way `gen_wmo_tiles.js` does (map's own obj0 ADTs/WDT,
  then the resolved WMO group/minimap files), just using the WMO's own
  minimap directory presence as a coarser "probably already extracted"
  signal instead of an exact per-file list (this is a one-off sanity-check
  tool, not the pipeline feeding shipped Lua data).
  Needs `npm install` in this folder first (adds `@wowserhq/format` for BLP
  decoding and `pngjs` for PNG writing, on top of `gen_wmo_tiles.js`'s own
  `csv-parse`). Uses `gen_wmo_tiles.js`'s current placement math (model Y
  mirrored about local 0, 90-degree local rotation, yaw, anchor at the raw
  `MODF.position`, Big-coordinate conversion; checked numerically against the
  generator's formula), plus one placement source `gen_wmo_tiles.js` doesn't have yet: a WDT-level
  MODF ("pure WMO dungeon", `MPHD.flags & 0x1` — see `.claude-docs/
  gotchas.md`'s "Detecting a pure WMO dungeon" entry), tried automatically
  whenever a map has no per-ADT MODF entries at all (e.g. Stockade). A
  rendering-only detail this script needs that `gen_wmo_tiles.js` doesn't
  (that one never touches pixel data, only writes `{fileID, box}` for
  `TerrainWorldMap.lua`'s own `tex:SetTexture`/`SetWidth`/`SetHeight` to
  stretch at render time): a WMO-group minimap BLP is cropped by Blizzard to
  its real content size, not always 256x256 (confirmed: Stockade's 26 groups
  range from 64x64 to 256x256) — placed left+bottom-anchored inside the
  nominal 256x256 block cell (`wow.export`'s `src/js/wmo-minimap.js`,
  `composite_tile`) before this script's own 90-degree content rotation.
  Applies the placement's yaw like `gen_wmo_tiles.js` (pitch/roll are not
  supported by either script).

  `--with-adt-tiles` additionally composites the map's own real, baked
  OUTDOOR minimap tiles (`world/minimaps/<map>/map<col>_<row>.blp`, box per
  tile via the same col/row -> Big-coordinate mapping as
  `TWM_Mini2Big_Coord`) underneath the WMO layer — ground truth for a map
  that has both (confirmed on Orgrimmar Arena: the WMO tile lands exactly on
  the real arena floor, no visible gap). The same offline technique this
  addon's own WMO-overlay feature was originally debugged with (see
  `.claude-docs/gotchas.md`'s "WMO-tile world position" entry) — use it
  before relying on an in-game screenshot for a map that has real terrain to
  check against (e.g. Shadowfang Keep).

## Step 11 — `gen_instance_maps.js`: dungeon/raid/scenario maps (`Twm_DungeonNames`/`Twm_RaidNames`/`Twm_ScenarioNames`, `Twm_mapareas`)

```bash
node gen_instance_maps.js --kind dungeon|raid|scenario --work-dir <dir> --flavor <product> (--client-dir <path> | --online) --tiles-file <mapdata_tiles_<kind>.lua from parse_wdt.js --candidates dungeons|raids|scenarios, already regenerated including these Directory names> [--wmo-tiles-file <mapdata_wmo_tiles.lua, already regenerated including these Directory names>] --out <out-file.lua> [--force] [--proxy <url>]
```

One shared script for all three categories (`--kind`), not three separate
files the way `gen_battlegrounds.js`/`gen_arenas.js` are — unlike those two
(genuinely different `UiMapAssignment` handling), dungeons/raids/scenarios
differ from each other only in which `Map.csv` `InstanceType` value selects
them (`1`/`2`/`5`) and which Lua globals the output populates. Otherwise
modeled closely on `gen_arenas.js`: per-locale baked names (self-downloaded,
same 11 locales) and a box derived from `--tiles-file` instead of a
`UiMapAssignment` Region box, for the same reason arenas need one —
`UiMapAssignment` presence for these is flavor-**inconsistent** (confirmed:
Ragefire Chasm has 0 rows on Vanilla/Forever but 6 on TBC/Mists, same
MapID), so there's no single reliable rule to build a box or a live-resolved
name from it either way, unlike battlegrounds.

Each candidate also carries `expansion` (`Map.csv`'s own `ExpansionID`, a
string like every other ID in this codebase) into the generated file. For
Dungeons/Raids specifically, `TerrainWorldMap.lua` uses it to insert an
expansion-selection dropdown level (Classic/The Burning Crusade/...,
`TWM_GetSortedExpansionIDs`/`TWM_GetExpansionName`) between the category and
the actual map list — release order falls straight out of sorting
`ExpansionID` numerically. The per-expansion names (`Locale/*.lua`'s
`TWM_EXPANSION_<N>`) were sourced from this client's own `Achievement_Category`
DB2 data (`wago.tools/db2/Achievement_Category/csv?product=<flavor>&locale=<locale>`),
not guessed — most locales (ruRU, deDE) keep the English title untranslated,
which is Blizzard's own convention, not a translation gap in this addon.
Scenarios also get an `expansion` field (uniform output shape, cheap to
include) but no dropdown level — Mists is the only flavor with any, and
they're all MoP (`ExpansionID=4`), so splitting by expansion there would be a
single always-open submenu with nothing to filter.

**Structural filter is deliberately NOT `MapType=1`**, unlike every other
generator's own top-level-map filter (`gen_mapareas.js`/`gen_arenas.js`/
`gen_battlegrounds.js` all use it) — `Map.csv`'s `MapType` column is
unrelated to `InstanceType` and is not a reliable "is this a real top-level
map" signal for dungeons specifically (confirmed: Ragefire Chasm's own
`MapType` is `2`, Shadowfang Keep's is `1`, despite both being ordinary
`InstanceType=1` dungeons — filtering on it silently drops ~30% of real
dungeons/raids). `ParentMapID=-1` + `InstanceType` is precise enough alone.
Non-functional test/scrapped content mixed into these `InstanceType`s is
filtered by a plain `/unused/i` test on `MapName_lang` (matches "(UNUSED)
Scenario: ...", "The Depths [UNUSED]", etc., confirmed no false positives
on real content across a full Mists scan).

**Box derivation has three paths**, tried in order:
1. Same as `gen_arenas.js`: valid-tile extent from `--tiles-file` (real ADT
   tile grid — some dungeons/scenarios have one, e.g. Shadowfang Keep,
   Greenstone Village).
2. **Preferred for pure-WMO maps (most dungeons/raids — no ADT tile grid at
   all)**: the union of every real tile corner already sitting in
   `--wmo-tiles-file`'s own `Twm_WMOTiles["<map>"]` entry (already-generated
   `mapdata_wmo_tiles_<kind>.lua`, `gen_wmo_tiles.js`'s output) — guaranteed to
   match what `TWM_WMOOverlay_Update` actually renders, since it's the exact
   same corner data, not a second, independently-reasoned placement formula.
   `--wmo-tiles-file` is optional — omit it (or pass a file that doesn't
   have an entry for a given map yet) and path 3 below is used instead.
3. **Fallback, only when neither of the above has anything for a map** (no
   `Twm_WDTValidTiles` entry AND no `Twm_WMOTiles` entry — e.g. it genuinely
   has no baked WMO minimap tiles at all, or `--wmo-tiles-file` wasn't
   passed/regenerated yet): derives a coarser box straight from the placed
   WMO's own **`MOHD` chunk bounding box** (root `.wmo` file, fixed 64-byte
   struct, bbox at offset 36/48 — already the union of every group, no need
   to touch group files at all — see `boxFromWdtGlobalPlacement`), found via
   the WDT-level `MODF` (`.claude-docs/gotchas.md`'s "Detecting a pure WMO
   dungeon" entry, guarded by `MPHD.flags & 0x1`).
   **This path was originally documented as deliberately skipping
   `gen_wmo_tiles.js`'s own 90-degree local-space rotation** (the "minimap-
   tile-baking-specific content quirk", on the theory it's a texture-only
   detail, irrelevant to a plain geometric bounding box). **That theory was
   wrong** — a live test showed the resulting box visibly not covering the
   real WMO tile cluster ("центрирует, но не всё скопление ВМО тайлов");
   comparing this path's own output against path 2's (real, rendered tile
   corners) for the same maps showed genuinely different box shapes, not
   just a rounding difference (confirmed across 23 of TBC's 36 dungeons and
   6 of its 17 raids). Path 3 itself was NOT changed to add the rotation
   back in (unverified whether it's actually the *right* fix for a raw MOHD
   bbox specifically, as opposed to the block-tiled minimap coordinates
   `gen_wmo_tiles.js` derives it for) — instead, path 2 was added so path 3
   is only ever a last resort for maps with no real tile data to check
   against at all. **Does not depend on baked minimap art existing** —
   needed for any map whose WMO has no `WMOMinimapTexture` rows in that
   build (e.g. Forever's rebuilt Blackrock Depths), only the WMO model file
   itself (the community listfile resolves the WDT's
   `MODF.nameId` to that file's path, same as `gen_wmo_tiles.js`). This
   map's own WDT and that resolved WMO root file are self-extracted the same
   two-pass way `gen_wmo_tiles.js` extracts its own dynamically-discovered
   files — but only for maps that actually fall through to this path; a map
   resolved by path 2 needs no extraction here at all.

**Example (full TBC run — `--wmo-tiles-file` pointed at the already-shipped
per-category file so most pure-WMO candidates resolve via path 2 with zero
extraction; `--tiles-file`/`--wmo-tiles-file` are `parse_wdt.js`/
`gen_wmo_tiles.js`'s own `--candidates dungeons` output, steps 3/10 above):**
```bash
node gen_instance_maps.js --kind dungeon --work-dir C:\wow-data --flavor wow_anniversary --client-dir "C:\Program Files\World of Warcraft" --tiles-file Data_TBC/mapdata_tiles_dungeons.lua --wmo-tiles-file Data_TBC/mapdata_wmo_tiles_dungeons.lua --out Data_TBC/mapdata_dungeons.lua
```
This script itself doesn't take `--candidates`/`--maps` at all — `--kind`
already selects exactly one category, so there's no second axis to choose.
It reads `candidates/<dungeons|raids|scenarios>.json` (by `Map.csv` `ID`,
for its locale-independent Directory/enUS-name/`ExpansionID` fields)
instead of re-deriving the same candidate list from `Map.csv` a second
time — `findCandidates` (the structural filter + `skipMaps`) only ever runs
inside `gen_candidates.js` now, same as `findArenas`/`findBattlegrounds`
above. `gen_candidates.js` is a hard prerequisite for this script too.
Runs exactly once per `--kind` now — it used to need its own stdout as a
"discovery" pass before `--tiles-file` had dungeon/raid tile data at all;
`gen_candidates.js`/`parse_wdt.js --candidates dungeons` already having
that data from the start removes that requirement (same fix as
`gen_arenas.js` above).

**Status**: run for all four flavors (dungeons and raids everywhere,
scenarios on Mists only). Every entry carries `mapID` (`Map.csv` `ID`, a
string) next to `key`/`expansion`, which the hand-maintained visibility lists
match against (`Twm_SeasonOnlyMaps`, `Twm_DevelopmentMaps`, see
"`Data_<Flavor>/mapdata_poi.lua`" above). After every `gen_wmo_tiles.js`
regen of a flavor, re-run this script for the same flavor and kind (pure-WMO
boxes come from the regenerated tile corners, see `.claude-docs/gotchas.md`).

## When to re-run

Re-run for a flavor when: its `.build.info` version changes, `mapdata_*.lua`
data turns out stale/wrong for some zone, or the flavor's data hasn't been
generated yet.
