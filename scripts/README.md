# TerrainWorldMap map-data generation scripts

Regenerates `Data_<Flavor>/mapdata_continents.lua` and
`Data_<Flavor>/mapdata_tiles.lua` from real client data. Not loaded by the
addon (`.js`/`.ps1` files are ignored by the WoW addon loader).

Pipeline: `init_workdir.ps1` (fetch client data) → `gen_mapareas.js` (zone
boxes) → `parse_wdt.js` (tile validity + AreaIDs) → `gen_poi_areas.js`
(sub-area/POI labels) → `gen_poi_graveyards.js` (graveyards) →
`gen_poi_instances.js` (dungeon/raid entrances) → `gen_poi_flightmasters.js`
(flight masters + routes).

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
per product: 8 DB2 CSVs (`AreaTable`/`Map`/`UiMap`/`UiMapAssignment`/
`AreaTrigger`/`TaxiNodes`/`TaxiPath`/`TaxiPathNode`) and the WDT/root-ADT/
noLiquid-minimap files for every open-world continent.

**Examples:**
```powershell
./init_workdir.ps1 -Product wow_classic_era -Storage "C:\Program Files\World of Warcraft" -WorkDir C:\wow-data

./init_workdir.ps1 -Product wow_anniversary -Online -WorkDir C:\wow-data -Proxy socks5h://user:pass@127.0.0.1:8883
```

Output lands in `<WorkDir>/<Product>/` — pass this path as `<csv-dir>` /
`--flavor-dir` to the next two scripts.

## Step 2 — `gen_mapareas.js`: zone bounding boxes + capital city maps

```bash
node gen_mapareas.js <csv-dir> [<out-file.lua>]
```

- `<csv-dir>` — folder containing `Map.*.csv`, `UiMap.*.csv`,
  `UiMapAssignment.*.csv` (matched by prefix). This is `<WorkDir>/<Product>`
  from step 1.
- `<out-file.lua>` — optional. Point it at `Data_<Flavor>/mapdata_continents.lua`
  to overwrite in place. Omit to just print the continent name list.

Also emits `Twm_CityMapIDs` (capital-city `uiMapID`s, used by
`WorldMapOverlay.lua` to gate the terrain overlay on city sub-maps) by
reading `mapdata_zones.lua`'s own `Twm_CapitalAreaIDs` (hand-maintained
`AreaID` list, stable across the whole game's history) directly and
joining it against `UiMapAssignment`'s `AreaID`↔`UiMapID` mapping — no
per-flavor hand-collection needed.

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

**Example:**
```bash
node gen_poi_areas.js --flavor-dir C:\wow-data\wow_anniversary --mapareas-file Data_TBC/mapdata_continents.lua --out Data_TBC/mapdata_poi_areas.lua Azeroth Kalimdor Expansion01
```

## Step 5 — `gen_poi_graveyards.js`: graveyard/spirit-healer locations (`Twm_poi_graveyards`)

```bash
node gen_poi_graveyards.js --wowhead-html <saved Spirit Healer NPC page.html> --mapareas-file <target flavor mapdata_continents.lua> --out <out-file.lua>
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

Save each page's HTML (e.g. `curl -A "Mozilla/5.0" <url> -o spirit_<flavor>.html`
— no login/JS needed) and pass it as `--wowhead-html`.

- **`--wowhead-html`** (required) — path to the saved NPC page HTML for the
  target flavor's own domain (table above).
- **`--mapareas-file`** (required) — the target flavor's own
  `mapdata_continents.lua`. Every continent block in it is scanned (not just
  one), and each `g_mapperData` AreaID is looked up directly against
  whichever continent actually declares that AreaID — supplies the zone's
  own box, in this flavor's own Big-coordinate space, via `Twm_mapareas`.
- **`--out`** (required) — output path, e.g. `Data_<Flavor>/mapdata_poi_graveyards.lua`

An AreaID from the page with no matching box in `--mapareas-file` (e.g. a
zone from a later expansion this flavor doesn't have) is silently skipped;
skip count is printed to stderr. Confirmed 0 skipped for Vanilla/TBC (full
match); Mists skips ~36 (non-open-world/instance-only zones not part of
this addon's continent list).

**Example:**
```bash
curl -A "Mozilla/5.0" https://www.wowhead.com/classic/npc=6491/spirit-healer -o spirit_vanilla.html
node gen_poi_graveyards.js --wowhead-html spirit_vanilla.html --mapareas-file Data_Vanilla/mapdata_continents.lua --out Data_Vanilla/mapdata_poi_graveyards.lua
```

## Step 6 — `gen_poi_instances.js`: dungeon/raid entrance markers (`Twm_instances`)

```bash
node gen_poi_instances.js --flavor-dir <dir with AreaTrigger.*.csv and Map.*.csv> --teleport-csv <id-to-target-map reference CSV> --mapareas-file <target flavor mapdata_continents.lua> --out <out-file.lua>
```

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
node gen_poi_instances.js --flavor-dir C:\wow-data\wow_classic_era --teleport-csv C:\wow-data\wow_classic_era\areatrigger_teleport.csv --mapareas-file Data_Vanilla/mapdata_continents.lua --out Data_Vanilla/mapdata_poi_instances.lua
```

## Step 7 — `gen_poi_flightmasters.js`: flight master markers + routes (`Twm_flightmasters`, `Twm_taxipaths`, `Twm_taxipathnodes`)

```bash
node gen_poi_flightmasters.js --flavor-dir <dir with TaxiNodes.*.csv, TaxiPath.*.csv, TaxiPathNode.*.csv and Map.*.csv> --mapareas-file <target flavor mapdata_continents.lua> --out <out-file.lua>
```

- **`--flavor-dir`** (required) — `<WorkDir>/<Product>` from step 1
- **`--mapareas-file`** (required) — the flavor's own `Data_<Flavor>/mapdata_continents.lua` (step 2's output)
- **`--out`** (required) — output path, e.g. `Data_<Flavor>/mapdata_poi_flightmasters.lua`

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
(`"Programmer Isle"`), and generic scripted targets (`"Generic, ..."`) —
filtered out by a name-prefix heuristic (`JUNK_NAME_RE` in the script).
Confirmed against every row in Vanilla's ~87-row table with no known false
positives, but it's a heuristic, not something DB2 structure backs up —
sanity-check the "N junk rows skipped" count if this ever runs against a
very different client build.

`Twm_flightmasters[continent]` entries are `{TaxiNodeID, "Faction", Name, x, y}`
— the TaxiNode ID is kept (AreaID-first convention, same as `Twm_poi_areas`)
so `TaxiRoutes.lua` can join it against `Twm_taxipaths` at load time.
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
node gen_poi_flightmasters.js --flavor-dir C:\wow-data\wow_classic_era --mapareas-file Data_Vanilla/mapdata_continents.lua --out Data_Vanilla/mapdata_poi_flightmasters.lua
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
