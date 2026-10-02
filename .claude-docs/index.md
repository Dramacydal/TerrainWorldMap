---
tags: [memory/repo]
---

# Documentation index

| Need to... | Read |
|---|---|
| Avoid a known footgun before touching DB2/ADT/AreaTrigger/resize/tooltip code | [gotchas.md](gotchas.md) |
| Understand the point-set rendering system, coordinate systems, or live name resolution | [architecture.md](architecture.md) |
| Regenerate map data (zones, POIs, graveyards, dungeon/raid entrances) | [../scripts/README.md](../scripts/README.md) |
| Add a new marker category (like capitals/dungeons) | [architecture.md](architecture.md)'s "Adding a new marker category" |
| Edit a hand-maintained (not generated) data file: `Data_<Flavor>/mapdata_poi.lua`, `Data_Vanilla`/`Data_Forever` `mapdata_seasons.lua`, `mapdata_development.lua`, `scripts/skip_lists.js` | [../scripts/README.md](../scripts/README.md) ("`Data_<Flavor>/mapdata_poi.lua`" section, "Other scripts" → `skip_lists.js`) |
| Change how WMO tiles are stacked/ordered on the map, or add a new frame on top of the map view | [architecture.md](architecture.md) (WMO minimap-tile overlay) and [gotchas.md](gotchas.md) ("WMO overlay stacking") |
