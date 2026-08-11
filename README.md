# TerrainWorldMap

Overlays the real minimap terrain tiles onto WoW's own World Map, and provides
a movable/resizable minimap-style map window — for WoW Classic (Vanilla, TBC,
Mists of Pandaria; ships one `.toc` per flavor, see `Data_<Flavor>/`).

## Features

- **Terrain overlay on the World Map** — real minimap tiles instead of
  Blizzard's painted map art, toggleable per zone/world view/city map.
- **Standalone map window** — movable, resizable, zoomable; jump to any
  zone or to your own position.
- **Player/party/raid tracking** on the map.
- **Minimap button** and a **World Map button**, both with a right-click menu.
- **Native settings panel** (Esc → Options → AddOns → TerrainWorldMap).
- Covers whichever continents the running client's flavor data has been
  generated for (TBC: Kalimdor, Eastern Kingdoms, Outland; Vanilla/Mists:
  see the `TODO`s in `Data_Vanilla/`/`Data_Mists/`).
- Localized: enUS, deDE, zhCN, ruRU.

## Usage

- `/twm` — toggle the map window.
- Minimap button — left-click to toggle the window, right-click for a menu.
- World Map button — left-click to toggle the terrain overlay, right-click
  for a menu.

## Contributing

See `scripts/README.md` for the developer tools that regenerate map data
from this client's own DBC/WDT files.
