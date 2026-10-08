# TerrainWorldMap

Overlays the real minimap terrain tiles onto WoW's own World Map, and provides
an movable/resizable minimap-style map window.

Single addon for any version - Vanilla (classic_era), TBC (anniversary), MoP Classic (classic), WoW: Forever (classic_beta)

Lightweight by design — it reuses the terrain images already present in
your game client instead of shipping its own map art, so it adds almost
nothing to your addon folder's size or your loading screens.

## Features

- **Terrain overlay on the World Map** — real minimap tiles instead of
  Blizzard's painted map art, toggleable per zone/world view/city map; on
  capital city maps the city's buildings can be drawn over the terrain too
  (Off / On / On + Buildings); the standalone window shows them on
  continent maps too, when zoomed in.
- **Standalone map window** — movable, resizable, zoomable; the map fills
  the window under a semi-transparent header (map selectors, Goto Player,
  options) and footer (zoom, terrain/WMO toggles). Jump to any zone or to
  your own position, or turn on follow mode (Shift+Click Goto Player,
  continents only). Transparency and icon size are both adjustable.
- **Instance maps in the standalone window** — battlegrounds, dungeons,
  raids, scenarios and arenas, with their real layouts (WMO tiles). Show
  Terrain / Show WMO Layers toggles, a height cutoff slider and a WMO Tile
  Management menu control what is drawn.
- **Dungeon and raid portals** — in the standalone window, click an
  entrance marker to open that dungeon's map. Inside, exit markers lead
  back outdoors and links to other instances (e.g. Blackrock Depths to
  Molten Core) are marked too.
- **Map markers**, each independently toggleable (gear menu) — shown by
  default: Landmarks (named points of interest), Graveyards, Capitals,
  Dungeons & Raids (one toggle for both), and Flight Masters (color-coded
  by faction). All show up correctly in whatever language the game itself
  is running.
- **Inaccessible maps** (optional) — shows maps that exist in the client
  data but players can't reach (unfinished, cut or replaced ones).
- **Flight path lines** between flight masters — hover over one to see
  its own routes, or show every known route on the continent at once;
  hold Shift to see the real curved flight path instead of a straight
  line (showing every route at once can be laggy on continents with a lot
  of routes, especially with Shift held). An adjustable smoothing slider
  can further curve a hovered flight master's own routes.
- **Player/party/raid tracking** on the map, with class-colored names and
  class icons in the tooltips.
- **Minimap button** and a **World Map button**, both with a right-click menu.
- **Native settings panel** (Esc → Options → AddOns → TerrainWorldMap).
- Covers whichever continents the running client's flavor data has been
  generated for.
- Localized: enUS, deDE, zhCN, ruRU, frFR, esES, esMX.

## Usage

- Minimap button — left-click to toggle the window, right-click for a menu.
- World Map button — left-click to toggle the terrain overlay, right-click
  for a menu.
- `/twm` — toggle the map window; `/twm show`, `/twm hide` — show or hide it.
- `/twm center` — show the window and center it on your character.
- `/twm follow on|off` — turn following your character on or off.
- `/twm reset` — reset the window position and size; `/twm reset all` — also all settings.
- `/twm options` — open the settings.
- `/twm overlay on|off` — terrain overlay on the World Map; `/twm debug` — tile debug labels.

## Contributing

See `scripts/README.md` for the developer tools that regenerate map data
from this client's own DBC/WDT files.

## Credits

TerrainWorldMap was greatly inspired by, and started life as, **Yatlas** —
Yatlas was the original starting point for this addon's development.
