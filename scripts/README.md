# TerrainWorldMap map-data generation scripts

Regenerates `Data_<Flavor>/mapdata_continents.lua` and
`Data_<Flavor>/mapdata_tiles.lua` from real client data. Not loaded by the
addon (`.js`/`.ps1` files are ignored by the WoW addon loader).

Pipeline: `init_workdir.ps1` (fetch client data) → `gen_mapareas.js` (zone
boxes) → `parse_wdt.js` (tile validity + AreaIDs) → `gen_poi_areas.js`
(sub-area/POI labels) → `gen_poi_graveyards.js` (graveyards) →
`gen_poi_instances.js` (dungeon/raid entrances) → `gen_poi_flightmasters.js`
(flight masters + routes) → `gen_battlegrounds.js` (battleground maps, run
independently of the rest — see its own step below).

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
| Forever | `wow_classic_beta` | `Data_Forever` |

Forever (WoW: Forever, Classic+) is still in beta as of this writing --
`wow_classic_beta` is the product code for now, but expect Blizzard to swap
it for a permanent one at launch (re-check `.build.info` if it stops
matching). Its continent list is `Azeroth`/`Kalimdor`/`2991` -- `2991` is
Zephras Isle, a new beta zone with no proper flavor-specific directory name
assigned yet (just its own numeric `Map.ID`, used as-is as the continent
key). No Outland/Northrend -- this flavor's world is Classic-era Kalimdor
and Eastern Kingdoms plus this one new island so far.

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
per product: 7 DB2 CSVs (`AreaTable`/`Map`/`UiMap`/`UiMapAssignment`/
`AreaTrigger`/`TaxiPath`/`TaxiPathNode`), `TaxiNodes` fetched once per client
locale into `<productDir>/locales/TaxiNodes.<locale>.csv` (`enUS`/`deDE`/
`esES`/`esMX`/`frFR`/`itIT`/`koKR`/`ptBR`/`ruRU`/`zhCN`/`zhTW` — flight
masters bake in every locale's name rather than resolving one live, see step
7), and the WDT/root-ADT/noLiquid-minimap files for every open-world
continent.

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
node gen_mapareas.js C:\wow-data\wow_classic_era Data_Vanilla/mapdata_continents.lua
```

stdout, line 1: the exact case-sensitive continent names to pass to
`parse_wdt.js` in step 3, e.g.:
```
Azeroth Kalimdor
```

## Step 3 — `parse_wdt.js`: tile validity + AreaIDs

```bash
node parse_wdt.js --flavor-dir <dir> --out <out-file.lua> [--noliquid] [--areatable-dir <dir>] [--listfile <community-listfile.csv>] <ContinentName> [<ContinentName> ...]
```

- **`--flavor-dir`** (required) — `<WorkDir>/<Product>` from step 1
- **`--out`** (required) — output path, e.g. `Data_<Flavor>/mapdata_tiles.lua`
- **`--noliquid`** (optional) — also detect underwater tiles (noLiquid minimaps) — only meaningful for flavors with submerged zones (Mists onward: Vashj'ir, Pandaria coastline)
- **`--areatable-dir`** (optional, defaults to `--flavor-dir`) — folder containing `AreaTable.*.csv`
- **`--listfile`** (optional) — path to a community listfile (`id;path` per line, e.g. `init_workdir.ps1`'s `WorkDir/CASCConsole/listfile.csv`). Bakes each tile's minimap BLP `FileDataID` into `Twm_TileFileID[continent][filename]`. **Only needed for a flavor where `Texture:SetTexture("World\Minimaps\...")` doesn't resolve by path string at all** — confirmed on WoW: Forever/Camelot (see `.claude-docs/gotchas.md`); every other flavor still loads fine by path and doesn't need this flag. A tile with no listfile entry gets a loud `WARNING` on stderr and falls back to the (broken, on that flavor) path string — not silently dropped.
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

Output is one `Twm_poi_areas["<Name>"] = {...}` assignment per zone name
passed, not a single `Twm_poi_areas = {...}` literal — safe to run this
script more than once against different `--mapareas-file`s/`--out` files
(e.g. once for continents, once for battlegrounds) without one run
clobbering another's entries. `Twm_poi_areas = {}` itself is pre-declared
in root `mapdata_zones.lua`, loaded before any of these files.

**Example:**
```bash
node gen_poi_areas.js --flavor-dir C:\wow-data\wow_anniversary --mapareas-file Data_TBC/mapdata_continents.lua --out Data_TBC/mapdata_poi_areas.lua Azeroth Kalimdor Expansion01
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
node gen_poi_areas.js --flavor-dir C:\wow-data\wow_anniversary --mapareas-file Data_TBC/mapdata_battlegrounds.lua --out Data_TBC/mapdata_poi_battlegrounds_areas.lua PVPZone01 PVPZone03 PVPZone04 NetherstormBG
```

## Step 5 — `gen_poi_graveyards.js`: graveyard/spirit-healer locations (`Twm_poi_graveyards`)

```bash
node gen_poi_graveyards.js --wowhead-html <saved Spirit Healer NPC page.html> --mapareas-file <target flavor mapdata_continents.lua> --out <out-file.lua> [--flavor-dir <dir with UiMapAssignment/UiMap/AreaTable.*.csv>]
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
- **`--flavor-dir`** (optional) — `<WorkDir>/<Product>` from step 1. Without
  it, an AreaID from the page with no matching box in `--mapareas-file`
  (e.g. a zone from a later expansion this flavor doesn't have, **or** a
  small starting-experience camp `gen_mapareas.js` excluded from the zone
  dropdown for not being a top-level `AreaTable` entry — Camp Narache,
  Gilneas City, ...) is silently skipped. With it, such an AreaID is still
  resolved: its own box comes straight from this dir's `UiMapAssignment.csv`
  (not its parent zone's box, which would place the point wrong, not just
  approximately — the percentages are relative to that AreaID's own map),
  and which output section it goes under comes from walking `AreaTable`'s
  `ParentAreaID` chain up to whichever ancestor **is** in `--mapareas-file`.
  Confirmed for Mists: Gilneas2 alone has two disjoint sets of real
  graveyards on Wowhead, one keyed to Gilneas City, one to Gilneas itself —
  losing either silently is why this flag exists.

Dedup (see below) runs per output continent across every AreaID that landed
there, not per AreaID — a zone and a sub-area of it (Gilneas/Gilneas City)
can each contribute points close enough together to be the same physical
graveyard, and only whole-continent dedup catches that. Skip count (fully
unresolvable AreaIDs) is printed to stderr; Mists still skips ~36 even with
`--flavor-dir` (non-open-world/instance-only zones not part of this addon's
continent list at all).

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
node gen_poi_flightmasters.js --flavor-dir <dir with TaxiPath.*.csv, TaxiPathNode.*.csv and Map.*.csv> --locales-dir <dir with TaxiNodes.<locale>.csv per locale> --mapareas-file <target flavor mapdata_continents.lua> --out <out-file.lua>
```

- **`--flavor-dir`** (required) — `<WorkDir>/<Product>` from step 1
- **`--locales-dir`** (required) — `<WorkDir>/<Product>/locales` from step 1 (one `TaxiNodes.<locale>.csv` per supported locale: `enUS`/`deDE`/`esES`/`esMX`/`frFR`/`itIT`/`koKR`/`ptBR`/`ruRU`/`zhCN`/`zhTW`). `enUS` is required — it's also the structural source of truth for every non-name field (`Flags`/`CharacterBitNumber`/`Pos`/`ContinentID` are identical across every locale's export of the same row, only `Name_lang` differs); the rest are optional per-locale name overlays, skipped with a warning (not a hard failure) if missing.
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
node gen_poi_flightmasters.js --flavor-dir C:\wow-data\wow_classic_era --locales-dir C:\wow-data\wow_classic_era\locales --mapareas-file Data_Vanilla/mapdata_continents.lua --out Data_Vanilla/mapdata_poi_flightmasters.lua
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
node gen_battlegrounds.js --flavor-dir <dir with Map/UiMap/UiMapAssignment CSVs> --out <out-file.lua>
```

- **`--flavor-dir`** (required) — `<WorkDir>/<Product>` from step 1
- **`--out`** (required) — output path, e.g. `Data_<Flavor>/mapdata_battlegrounds.lua`

Not part of the main pipeline chain — run it standalone whenever a flavor's
battleground list changes. Same top-level-map shape as `gen_mapareas.js`'s
continents (`Map.csv` row with `ParentMapID=-1`, `MapType=1`), just
`InstanceType=3` instead of `0`. Unlike continents, a battleground has no
separate "whole map" `UiMapAssignment` root row (`Type=2`/`System=0`/`AreaID=0`)
— it's just one Zone row directly (unioned if a battleground ever has more
than one), which doubles as both the `[0]` box **and** the position-tracking
`UiMapID`. That Zone row's own `UiMap.Type` value is `3` on Vanilla/TBC/Mists
(same as any regular outdoor zone) but `6` on WoW: Forever/Camelot (its own
distinct PvP-zone type there) — the script matches either.

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
`parse_wdt.js` handles them exactly like a small continent (pass the
battleground's own `Directory` as one of its `<ContinentName>` args, output to
the flavor's own `mapdata_tiles.lua` alongside its continents — do **not**
give battlegrounds a separate tiles file, since `parse_wdt.js` always emits a
fresh `Twm_WDTValidTiles = {}` reset at the top of its output, which would
wipe out whatever an earlier, separately-run continents pass had already
written to that global table if loaded afterward).

**Example (TBC):**
```bash
node gen_battlegrounds.js --flavor-dir C:\wow-data\wow_anniversary --out Data_TBC/mapdata_battlegrounds.lua
node parse_wdt.js --flavor-dir C:\wow-data\wow_anniversary --out Data_TBC/mapdata_tiles.lua Azeroth Kalimdor Expansion01 PVPZone01 PVPZone03 PVPZone04 NetherstormBG
```

**Battlegrounds found per flavor** (as of this writing — re-run
`gen_battlegrounds.js` to pick up any new ones):
- **Vanilla**: PVPZone01 (Alterac Valley), PVPZone03 (Warsong Gulch), PVPZone04 (Arathi Basin)
- **TBC**: the above + NetherstormBG (Eye of the Storm)
- **Mists**: the above + WintergraspEpic (Wintergrasp), `2755` (Battle for Tol Barad)
- **Forever**: PVPZone01/03/04 + `2997` (Darkspear Islands) — no Eye of the Storm/Wintergrasp/Tol Barad in this build yet

## Step 9 — `gen_arenas.js`: arena maps (`Twm_ArenaNames`, `Twm_mapareas`)

```bash
node gen_arenas.js --flavor-dir <dir with Map.*.csv> --locales-dir <dir with Map.<locale>.csv for each of enUS/deDE/esES/esMX/frFR/itIT/koKR/ptBR/ruRU/zhCN/zhTW> --tiles-file <mapdata_tiles.lua, already regenerated including the arena Directory names> --out <out-file.lua>
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
    DBC Region box. Run `parse_wdt.js` on the arena's own `Directory` name
    first (same "pass it alongside continents/battlegrounds in the same
    invocation, don't give it a separate tiles file" rule as
    `gen_battlegrounds.js`'s own note below), then point this at that
    output. The tile index range is converted to Big coordinates through
    `TWM_Mini2Big_Coord`'s own formula (`TerrainWorldMap.lua`) —
    `x/y = (index-32)*-533.3333` — the same conversion
    `WorldMapOverlay.lua`'s `DrawTiles` already uses to place each tile.
  - **`--locales-dir`**: with no live uiMapID, there's no
    `C_Map.GetMapInfo(uiMapID).name` to resolve a client-locale name from
    either (unlike `Twm_BattlegroundMapID`) — names are baked in per
    client locale instead, fetched the same way and for the same 11
    locales as `gen_poi_flightmasters.js`'s `TaxiNodes.<locale>.csv`, just
    for `Map.<locale>.csv`. Output shape mirrors `Twm_flightmasters`'s name
    tables too: `Twm_ArenaNames = {{key=..., name={enUS=..., deDE=...}}, ...}`,
    resolved into the actual `TWM_ARENAS` dropdown table (`{name: {key}}`,
    same shape as `TWM_BATTLEGROUNDS`) at load time in `TerrainWorldMap.lua`
    via `TWM_ResolveLocaleName` (`TaxiRoutes.lua`, a generic `{locale: name}`
    resolver already used for flight masters; falls back to enUS same as
    those).

**Example (TBC):**
```bash
node gen_arenas.js --flavor-dir C:\wow-data\wow_anniversary --locales-dir C:\wow-data\wow_anniversary\locales --tiles-file Data_TBC/mapdata_tiles.lua --out Data_TBC/mapdata_arenas.lua
node parse_wdt.js --flavor-dir C:\wow-data\wow_anniversary --out Data_TBC/mapdata_tiles.lua Azeroth Kalimdor Expansion01 PVPZone01 PVPZone03 PVPZone04 NetherstormBG PVPZone05 bladesedgearena PVPLordaeron
```
(run `parse_wdt.js` first — `gen_arenas.js` reads its output.)

**Arenas found per flavor** (as of this writing):
- **Vanilla**: none (arenas didn't exist yet)
- **TBC**: Nagrand Arena, Blade's Edge Arena, Ruins of Lordaeron
- **Mists**: the above + Dalaran Sewers, The Ring of Valor, Tol'Viron Arena, The Tiger's Peak
- **Forever**: `2995` (Hyjal Crater) — none of the above exist in this build yet

## Step 10 — `gen_wmo_tiles.js`: WMO minimap-tile overlay (`Twm_WMOTiles`)

```bash
node gen_wmo_tiles.js --flavor-dir <dir with world/maps/<map>/*_obj0.adt and extracted world/wmo/... WMOs> --listfile <community-listfile.csv> --out <out-file.lua> <MapDirectoryName> [<MapDirectoryName> ...]
```

Naming here is deliberately map-generic, not arena-specific — arenas are
the only maps that use this so far, but the same WMO-minimap-tile system
also applies to dungeons/raids, meant to be added later (their own
extraction specifics, e.g. a WDT-level `MODF` for pure-WMO instances —
see `.claude-docs/gotchas.md`'s "Detecting a pure WMO dungeon" entry — are
NOT implemented yet, only the generic naming/plumbing below is in place).

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
that). This script finds WMO placements and their tiles directly — no
`WMOMinimapTexture` DB2 row needed:

- Scans each map's `world/maps/<map>/*_obj0.adt` files for `MODF`
  chunks (64-byte entries: `nameId`(0)/`uniqueId`(4)/`position`
  float32[3](8, order X/height/Y)/`rotation` float32[3](20, same order)/
  bounds(32,44)/`flags`(56)/`doodadSet`(58)/`nameSet`(60)/`scale`(62)),
  deduped by `nameId`.
- One streaming pass over `--listfile` resolves each placement's `nameId`
  to its WMO path, and separately collects every `world/minimaps/wmo/`
  tile path grouped by stem (path minus its trailing
  `_<group>_<blockX>_<blockY>.blp`).
- **Rotation scope**: only placements with `|rotation| <= 0.05` degrees on
  all three axes are emitted. A placement with real rotation (confirmed to
  exist, e.g. Tol'Viron Arena, Ring of Valor — always yaw-only, never
  pitch/roll) is skipped with a console warning; the yaw transform isn't
  implemented.
- Each WMO group's own local bounding box (`MOGP` chunk, offset 12 within
  its data: `flags`(4) then `bboxMin`/`bboxMax` `C3Vector`(12 each), plain
  `(X,Y,Z=height)` order — NOT the same reordering `MODF` uses) sets that
  group's tile-grid origin: `local.X = bbox.minX + blockX*128` (128
  model-units per 256px tile, fixed `PPU=2`, same constant as WMO dungeon
  interiors) — `blockX` reads directly against `box[0]`, no swap with
  `box[1]`.
- `local.Y` gets a flip shared across the WHOLE placement (not per group —
  see gotchas.md for why that distinction matters): `local.Y_raw =
  bbox.minY + blockY*128` for every tile of every group in the placement,
  `trueGlobalMinY`/`trueGlobalMaxY` = the min/max of every involved GROUP's
  own real `box.min[1]`/`box.max[1]` (group-level, continuous geometry —
  NOT block-quantized, NOT per-tile), then `local.Y = (trueGlobalMinY +
  trueGlobalMaxY) - local.Y_raw - 128`.
  This exact form took two rounds to get right, both invisible to every
  relative/adjacency check and only found via Orgrimmar Arena's rare
  independent ground truth (it also has real ADT-baked outdoor minimap
  tiles for the SAME building its WMO overlay draws, so the two can be
  compared pixel-for-pixel — most arenas have no such check available).
  Round 1: the flip started as a faithful port of wow.export's real
  `compute_minimap_layout()`, but that function builds a presentation-only
  CANVAS coordinate (valid for arranging tiles relative to each other, not
  as a real local coordinate) — using it unmodified re-anchors the whole
  placement onto the canvas's own arbitrary zero (confirmed: ~160 units off
  against Orgrimmar's real tile). Round 2: even after re-anchoring onto the
  placement's own minimum, that minimum was still built from block-
  quantized `local.Y_raw` values, not the group's true bbox edge — a
  group's real geometry need not exactly fill a whole number of 128-unit
  blocks (Orgrimmar's own group spans 241.6 real units but reads as 2 full
  blocks = 256, a 14.4-unit slack; wow.export's own `build_world_meta`
  inherits the same slack from its own `max_y`, so wow.export never has to
  notice — but this addon has ground truth wow.export doesn't). Both
  rounds are one GLOBAL reference shared across the whole placement, so
  neither could disturb the already-verified relative arrangement between
  groups (confirmed: Dalaran's own ~21.575-unit group-to-group offset is
  exactly unchanged by either). Final residual after both fixes, measured
  against Orgrimmar's real tile (color-thresholded pixel scan, not
  eyeballed): ~3-5 units — down from ~160, and visually a full, gapless
  overlap.
- Local coordinates then get a fixed 90°-clockwise rotation —
  `(local.X, local.Y) -> (-local.Y, local.X)` — correcting for a real
  property of Blizzard's own WMO-minimap-tile baking convention (also true
  for WMO dungeon interiors; confirmed against the real in-game Minimap).
- Model→world: `World.X = MODF.position[0] + local.X`,
  `World.Y = MODF.position[2] + local.Y` (plain component-wise addition —
  the standard MODF-placement convention, no rotation matrix needed since
  rotation≈0 here). World → Big: `Big-X = MAP_ORIGIN - World.X`,
  `Big-Y = MAP_ORIGIN - World.Y` (`MAP_ORIGIN = 32*(1600/3)`) — no
  cross-swap (this addon's usual "Big-X = world-Y" convention is
  calibrated for other sources, not a value already in `MODF`'s own axis
  order).
  `TerrainWorldMap.lua`'s `TWM_WMOOverlay_Update` has no rotation/flip logic
  of its own — it reads these Big coordinates the same direct way the base
  map tiles do. The one thing that DOES still live in Lua is the matching
  texture-CONTENT rotation (`TWM_WMOOverlay_EnsureTextures`'
  `SetTexCoord(0,1, 1,1, 0,0, 1,0)`, the 8-param form) — a separate concern
  (what each tile's own pixels show, not where its box goes).
  See `.claude-docs/gotchas.md`'s "WMO-tile world position" entry for the
  reference implementation used, the full derivation of all of the above,
  and several reusable lessons from getting each step wrong at least once
  before landing here.
- **The positional args must match the map key's exact DB2 `Directory`
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
- Output: `Twm_WMOTiles["<map>"] = {{fileID, x1, x2, y1, y2, height}, ...}`,
  one entry per baked tile (`x1/y1` = max, `x2/y2` = min, same box
  convention as `Twm_mapareas`; `height` = that placement's own
  `MODF.position[1]` PLUS that specific tile's own WMO GROUP's height-axis
  center — tracked per group, not just per placement, since one
  placement's groups can be at meaningfully different real heights, e.g. a
  raised walkway over the main floor; confirmed on Dalaran Sewers' own two
  groups). Entries are sorted by this height ascending before output.
  Rendered in `TerrainWorldMap.lua` as a pooled set of plain textures
  (`TWM_WMOOverlay_Update`), shown only when a map has an entry in this
  table, toggled by the "Show WMO Layers" checkbox
  (`TWMFrameShowWMOOverlayButton`, default on) plus a vertical height-cutoff
  slider (shown only when a map's tiles actually span more than one
  height) — see `.claude-docs/architecture.md`'s Arenas section.

**Generated so far**: every arena in every flavor has been run through this
script at least once. Only Mists' `DalaranArena` (6 tiles) and
`OrgrimmarArena` (6 tiles) produce any output. Everything else produces 0:
TBC's Nagrand Arena/Blade's Edge Arena/Forever's Hyjal Crater have no
qualifying WMO placement at all (no console warning even); TBC's/Mists'
Ruins of Lordaeron and Mists' Tol'Viron Arena/Tiger's Peak have qualifying
WMOs but all with real rotation (skipped with a warning each).

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
