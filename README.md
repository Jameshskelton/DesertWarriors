# Desert Warriors

[image](assets/menu_start.png)

`Desert Warriors` is a Godot 4 tactical RPG prototype inspired by classic Fire Emblem structure: tile-based battles, full-screen combat cutaways, portrait dialogue, and a first chapter built around Woody's exile through the Greenwood.

## Current Slice

- Title screen, intro dialogue, tactical map, battle cutaway, victory dialogue, and results flow
- Data-driven classes, weapons, units, terrain, and chapter setup under `res://data`
- Chapter 1 forest realm with forest tile avoid/defense bonuses, a boss objective, one ally reinforcement, and one recruit event
- Casual-mode defeat handling and placeholder retro-styled UI

## Project Structure

- `autoload/`: singleton state, save, registry, and audio managers
- `systems/`: grid, pathfinding, AI, combat, event, and turn systems
- `scripts/controllers/`: main scene flow and tactical map controller
- `scripts/models/`: resource types and runtime state classes
- `scenes/`: title, dialogue, map, battle, results, and shared scenes
- `ui/`: reusable menu and forecast panels plus theme
- `data/`: chapter, terrain, weapon, class, and unit resources
- `docs/`: chapter brief and art/style notes
- `tests/`: lightweight validation scripts and smoke checks

## Running

1. Install `Godot 4.3+`.
2. Open this folder as a Godot project.
3. Run `res://scenes/shared/main.tscn`.

## Controls

- `Arrow keys` or `WASD`: move cursor
- `Enter` or `Space`: confirm
- `Esc` / `X`: cancel
- `T`: end player phase
- Mouse left click: move cursor and confirm tile
- `Enter` or `Space` during battle: skip battle animation playback

## Tests

The repo includes lightweight validation scripts under `res://tests` that load without external plugins. They are intended as smoke-check helpers until a full in-project test runner or GdUnit setup is added.
