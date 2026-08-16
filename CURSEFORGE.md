# TerrainWorldMap

TerrainWorldMap overlays the game's own minimap terrain tiles onto the World Map, so you see the actual landscape instead of Blizzard's stylized map illustration. It also adds a standalone, resizable map window for browsing the whole world outside the World Map UI.

Currently supports **Classic Era (Vanilla)**, **Classic Anniversary (TBC)**, and **Mists of Pandaria Classic** — all in one addon.

**Lightweight** — it draws the terrain from the minimap images already stored in your game client instead of bundling its own map art, so it adds almost nothing to your addon folder's size or your loading screens.

## Features

- **Real terrain overlay on the World Map**.
- **Standalone browser window** — a movable, resizable, zoomable minimap-style view, with adjustable transparency and icon size.
- **Underwater terrain toggle** (Mists of Pandaria) — shows the underwater terrain where possible, by default. Useful for Vashj'ir, but some zones at Pandaria's coastline also have this data (that seems to be erroneous).
- **Player, party and raid tracking** on the map.
- **Map markers**, each independently toggleable: Landmarks (points of interest), Graveyards, Capitals, Dungeons & Raids, and Flight Masters (color-coded by faction) — all shown with mouseover tooltips, and all displayed in whatever language you're playing in.
- **Flight path lines** between flight masters — hover over one to see its own routes, or show every known route on the continent at once; hold Shift to see the real curved flight path instead of a straight line (showing every route at once can be laggy on continents with a lot of routes, especially with Shift held).
- **Minimap button and World Map button**, each with a right-click menu for quick access to settings and toggles.
- **Localized**: English, German, Chinese (Simplified) and Russian currently.

## Usage

- Can be used with your favorite World Map addon, ones supporting zoom (like LeatrixMaps) are recommended.
- World Map button — left-click to toggle the terrain overlay, right-click for a menu.
- Minimap button — left-click to toggle the window, right-click for a menu.
- `/twm` — toggle the standalone map window.

## Supported clients

- **Classic Era** (Vanilla)
- **Anniversary** (TBC)
- **Mists of Pandaria Classic**

## Credits

TerrainWorldMap was greatly inspired by, and started life as, **Yatlas** —
Yatlas was the original starting point for this addon's development.
