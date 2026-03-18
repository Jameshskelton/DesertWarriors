# Desert Warriors

![Title Screen](https://github.com/Jameshskelton/DesertWarriors/blob/main/assets/ui/menu_start.png)

`Desert Warriors` is a Godot 4 tactical RPG campaign inspired by classic Fire Emblem structure. The current build includes five playable chapters, preparation screens, recruit events, shops, persistent gold and inventory state, frame-based battle animations, and data-driven dialogue and map content.

## Current Campaign

The playable story currently runs through five chapters:

- `Chapter 1: Exile in the Greenwood`
- `Chapter 2: The Old Monastery`
- `Chapter 3: The Unbroken`
- `Chapter 4: Hunters at the Cloister`
- `Chapter 5: The Hercule Desert`

Campaign highlights:

- George's exile is framed as the work of his jealous uncle, King Malrec.
- Allies such as Ember, Rowan, Balt, Ricodial, and Ysult join through chapter events and recruitment scenes.
- Bosses have confrontation dialogue, enhanced battle presentation, and distinct danger-zone emphasis.
- Chapter 4 is a survival map with an alternate boss-kill victory condition against `Lysandra Quill`.
- Chapter 5 pushes the company into the desert against brigands, hunters, and the lance-wielding boss `Bartram`.

## Current Features

![Battle Scene](https://github.com/Jameshskelton/DesertWarriors/blob/main/assets/readme_assets/battle_scene.gif)

- Grid-based tactical combat with movement, attacks, healing, items, shops, and turn phases
- Weapon durability and item inventories for each unit
- Shared party gold, enemy gold drops, and shop purchases
- Hero weapon-type restrictions and purchasable upgraded weapons
- Preparation screen with inventory reordering, trading, portrait display, and deployment slot swapping
- Hover portraits, unit inspection, enemy-specific threat previews, and on-map combat math previews
- Toggleable enemy danger zone plus player move+attack range overlay
- Villages and stores as explicit `Visit` actions
- Recruit events, reinforcements, and data-driven chapter scripting
- Suspend save / resume suspend and restart-chapter flow from the map system menu
- Optional permadeath chosen at the start of a new game
- Persistent campaign state across chapters for roster, XP, durability, items, recruits, and gold
- Chapter-end summaries showing EXP gained, gold earned, recruits, weapon breaks, and used items
- Level-up report screens with stat gain breakdowns
- Portrait-driven battle scenes with boss banners, floating combat feedback, and frame-based fight animations
- Map sprites with optional two-frame idle alternation support
- Crossfading music, including a dedicated battle track that resumes the map track afterward

## Tactical Map Presentation

The tactical map currently supports custom terrain art and gameplay rules for:

- `plains`
- `forest`
- `road`
- `castle`
- `village`
- `store`
- `cobblestone`
- `river`
- `mountain`
- `tall_mountain`
- `sand`

Map readability features include:

- right-side hover portrait panel
- highlighted movement path previews
- enemy movement previews during enemy phase
- boss-specific danger tinting
- unit inspection panel with terrain bonuses, range, and inventory

## Running

1. Open the project in `Godot 4.6.x`.
2. Load this folder as a Godot project.
3. Run the main scene at `res://scenes/shared/main.tscn`.

The project is configured for a `1920x1080` base viewport.

## Title Screen Flow

- Press `Space` on launch to open the main menu.
- `New Game` prompts for permadeath on or off.
- `Continue` resumes the saved campaign, or `Resume Suspend` if a suspend save exists.
- `Chapter Select` always works, even without a prior save, and seeds a chapter-appropriate default roster.

## Controls

- `Arrow keys` or `WASD`: move the map cursor
- `Enter` or `Space`: confirm / advance dialogue / continue prompts
- `Esc`: cancel / back
- `T`: open the end-turn confirmation
- `V`: toggle enemy danger zone
- `I`: inspect the unit under the cursor
- `P`: open the system menu on the map
- Mouse left click: move the cursor, select tiles, and use menus

## Data and Content Editing

Most campaign content is data-driven:

- `data/chapters/`: chapter layouts, dialogue, reinforcements, events, and objectives
- `data/units/`: character and enemy definitions
- `data/weapons/`: weapon stats and durability
- `data/items/`: consumable item definitions
- `data/terrains/`: terrain rules and map colors

Primary runtime scenes and systems:

- `scenes/title/`: title flow and chapter select
- `scenes/preparation/`: pre-battle inventory, trade, and deployment
- `scenes/map/`: tactical map UI and overlays
- `scenes/battle/`: battle cutaway scene
- `scenes/results/`: chapter-end summary
- `scenes/level_up/`: level-up report overlay
- `autoload/`: save, audio, registry, and campaign state systems
- `systems/`: combat, pathfinding, AI, danger zone, events, objectives, and items

Art and media paths:

- `assets/portraits/`: dialogue, prep, inspection, and battle portraits
- `assets/map_units/`: tactical map sprites
- `assets/fight_animations/`: battle animation frame folders and source clips
- `assets/terrain/`: terrain textures
- `assets/music/`: overworld and battle music

## Next Steps:

- Add 5 more levels of gameplay
- Add class evolution system
- add more diverse enemy unit types
- add unique weapons
- add more features to maps

## Notes

- Dialogue, recruit events, reinforcement waves, and boss confrontations are defined in chapter resource files.
- Character portraits are reused across dialogue, map hover, inspection, preparation, trade, battle, and level-up scenes.
- If you are adding or updating art, start with [docs/adding_artwork.md](/Users/jamesskelton/Downloads/DesertWarriors/docs/adding_artwork.md).
