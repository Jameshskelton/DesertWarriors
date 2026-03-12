# Desert Warriors

![Title Screen](https://github.com/Jameshskelton/DesertWarriors/blob/main/assets/ui/menu_start.png)

`Desert Warriors` is a Godot 4 tactical RPG prototype inspired by classic Fire Emblem structure. The current build includes a title screen, dialogue scenes with portraits, tactical map battles, recruitable allies, boss objectives, and battle cutaways with frame-based attack animations.

## Current Game

The playable campaign currently includes three linked chapters:

- `Chapter 1: Exile in the Greenwood`
- `Chapter 2: The Old Monastery`
- `Chapter 3: The Unbroken`

Current in-game features:

- Tile-based tactical combat with movement, attacks, healing, and turn phases
- Terrain effects and art for forests, castles, and villages
- Recruit events, reinforcements, and chapter-specific dialogue overlays
- Hover portraits on the tactical map
- Custom map sprites from `assets/map_units/`
- Portrait-driven battle scenes with extracted fight-animation frame sequences from `assets/fight_animations/`
- Looping background music and a custom UI font
- Save/load support through autoloaded game systems

## Chapter Highlights

- Chapter 1 introduces George's escape through the Greenwood and allows Ember to be recruited by visiting the village tile.
- Chapter 2 moves the party to the monastery and brings Balt in as a turn-2 ally reinforcement.
- Chapter 3 centers on the confrontation with Sir Aldric and the Unbroken.

## Project Layout

- `autoload/`: global systems such as game state, saves, data registry, and audio
- `data/`: classes, weapons, terrains, units, and chapter resources
- `scenes/`: title, dialogue, map, battle, results, and shared scenes
- `scripts/controllers/`: main flow and tactical map control
- `scripts/models/`: runtime state and resource-backed data types
- `systems/`: pathfinding, combat, AI, events, turn flow, and objectives
- `assets/portraits/`: dialogue and hover portraits
- `assets/map_units/`: tactical map character sprites
- `assets/fight_animations/`: source attack clips and extracted frame folders used in battle
- `assets/terrain/`: terrain art such as thicket, castle, and village tiles
- `docs/`: game notes, art guide, and supporting documentation
- `tests/`: lightweight validation scripts

## Running

1. Open the project in `Godot 4.6`.
2. Load this folder as a Godot project.
3. Run the main scene at `res://scenes/shared/main.tscn`.

The project is configured for a `1920x1080` base viewport with integer-scaled 2D rendering.

## Controls

- `Arrow keys`: move the cursor on the tactical map
- `Enter` or `Space`: confirm / advance dialogue
- `Esc`: cancel
- `T`: end the player phase
- `H` or `F1`: toggle the help panel on the map
- Mouse left click: move the map cursor and confirm a tile

## Notes

- Dialogue, recruit events, reinforcements, and victory scenes are data-driven from the files in `data/chapters/`.
- Character art currently flows through portraits, map sprites, and battle animation frame folders rather than full map-unit or battle-unit node scenes.
- If you are editing content, the most useful files to start with are in `data/chapters/`, `data/units/`, and `docs/adding_artwork.md`.
