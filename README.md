# TerrainWorldMap

Overlays the real minimap terrain tiles onto WoW's own World Map, and provides
an movable/resizable minimap-style map window.

Single addon for any version - Vanilla (classic_era), TBC (anniversary), MoP Classic (classic)

Lightweight by design — it reuses the terrain images already present in
your game client instead of shipping its own map art, so it adds almost
nothing to your addon folder's size or your loading screens.

## Features

- **Terrain overlay on the World Map** — real minimap tiles instead of
  Blizzard's painted map art, toggleable per zone/world view/city map.
- **Standalone map window** — movable, resizable, zoomable; jump to any
  zone or to your own position. Transparency and icon size are both
  adjustable.
- **Map markers**, each independently toggleable — shown by default:
  Landmarks (named points of interest), Graveyards, Capitals, and
  Dungeons & Raids (one toggle for both). All show up correctly in
  whatever language the game itself is running.
- **Player/party/raid tracking** on the map.
- **Minimap button** and a **World Map button**, both with a right-click menu.
- **Native settings panel** (Esc → Options → AddOns → TerrainWorldMap).
- Covers whichever continents the running client's flavor data has been
  generated for.
- Localized: enUS, deDE, zhCN, ruRU.

## Usage

- Minimap button — left-click to toggle the window, right-click for a menu.
- World Map button — left-click to toggle the terrain overlay, right-click
  for a menu.
- `/twm` — toggle the map window.

## Contributing

See `scripts/README.md` for the developer tools that regenerate map data
from this client's own DBC/WDT files.

## Credits

TerrainWorldMap was greatly inspired by, and started life as, **Yatlas** —
Yatlas was the original starting point for this addon's development.
