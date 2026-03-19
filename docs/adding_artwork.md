# Artwork Guide

This document reflects the current `Desert Warriors` project state.

The game currently uses character art in three places:

- Dialogue portraits in `scripts/ui/dialogue_scene.gd`
- Hover portraits on the tactical map in `scripts/controllers/tactical_map.gd`
- Battle cutaway portraits and attack animations in `scripts/ui/battle_scene.gd`

The project does not currently use `assets/map_units/` or `assets/battle_units/` at runtime. Unit markers on the map are still drawn in code, and battle scenes now use portraits plus fight-animation frame sequences instead of separate battle sprites.

## Current Character Roster

| Unit ID | Display Name | Class | Weapon | Portrait Used In Game | Fight Animation Used In Game |
| --- | --- | --- | --- | --- | --- |
| `george` | George | `vanguard` | `bronze_sword` | `assets/portraits/george.png` | `assets/fight_animations/george/` |
| `bram` | Bram | `knight` | `iron_lance` | `assets/portraits/bram.png` | `assets/fight_animations/bram/` |
| `rowan` | Rowan | `outrider` | `iron_lance` | `assets/portraits/rowan.png` | `assets/fight_animations/rowan/` |
| `ember` | Ember | `mage` | `fire_tome` | `assets/portraits/ember.png` | `assets/fight_animations/ember/` |
| `brother_hale` | Brother Hale | `priest` | `heal_staff` | `assets/portraits/hale.png` | none yet |
| `balt` | Balt | `hunter` | `hunter_bow` | `assets/portraits/Balt.png` | `assets/fight_animations/balt/` |
| `brigand_grunt` | Marauder | `marauder` | `iron_axe` | `assets/portraits/brigand_grunt.png` | `assets/fight_animations/brigand_grunt/` |
| `hunter_grunt` | Hunter | `hunter` | `hunter_bow` | `assets/portraits/hunter_grunt.png` | `assets/fight_animations/hunter_grunt/` |
| `knight` | Knight | `knight` | `iron_lance` | `assets/portraits/knight_grunt.png` | `assets/fight_animations/knight_grunt/` |
| `pursuer_armor` | Pursuer | `knight` | `iron_lance` | `assets/portraits/pursuer_armor.png` | `assets/fight_animations/pursuer_armor/` |
| `captain_briar` | Captain Briar | `captain` | `captain_axe` | `assets/portraits/captain_briar.png` | `assets/fight_animations/captain_briar/` |
| `abbot_vermis` | Abbot Vermis | `captain` | `captain_axe` | `assets/portraits/abbot_vermis.png` | `assets/fight_animations/abbot_vermis/` |
| `captain` | Captain | `captain` | `captain_axe` | none yet | falls back to `captain_briar` animation |
| `mage` | Mage | `mage` | `fire_tome` | none yet | falls back to `ember` animation |
| `sir_aldric` | Sir Aldric | `outrider` | `iron_lance` | none yet | falls back to `rowan` animation |

## Portrait Assets Currently Present

These portrait files already exist:

- `assets/portraits/Balt.png`
- `assets/portraits/abbot_vermis.png`
- `assets/portraits/bram.png`
- `assets/portraits/brigand_grunt.png`
- `assets/portraits/captain_briar.png`
- `assets/portraits/ember.png`
- `assets/portraits/george.png`
- `assets/portraits/hale.png`
- `assets/portraits/hunter_grunt.png`
- `assets/portraits/knight_grunt.png`
- `assets/portraits/pursuer_armor.png`
- `assets/portraits/rowan.png`

Portraits still missing as standalone files:

- `captain`
- `mage`
- `sir_aldric`

## Fight Animations Currently Present

Attack animations are currently stored in two forms:

- Source clips: `assets/fight_animations/<id>_fight.mp4`
- Runtime frame folders: `assets/fight_animations/<id>/frame_001.jpg`, `frame_002.jpg`, and so on

The game currently has animation frame folders for:

- `abbot_vermis`
- `balt`
- `bram`
- `brigand_grunt`
- `captain_briar`
- `ember`
- `george`
- `hunter_grunt`
- `knight_grunt`
- `pursuer_armor`
- `rowan`

Fight animations still missing as dedicated assets:

- `brother_hale`
- `captain`
- `mage`
- `sir_aldric`

## How Portrait Lookup Works

Dialogue portrait loading in `scripts/ui/dialogue_scene.gd` works like this:

1. Find a unit whose `display_name` matches the dialogue `speaker`
2. Try that unit's `portrait_id`
3. If that fails, try that unit's `unit_id`
4. If that fails, try the speaker name converted to lowercase snake case

Hover portraits and battle portraits work like this:

1. Try `portrait_id`
2. If that fails, try `unit_id`

This is why some units still work even when `portrait_id` and the actual filename do not match perfectly.

Examples:

- `captain_briar` has `portrait_id = "briar"`, but still loads because it falls back to `unit_id` and finds `captain_briar.png`
- `balt` uses `portrait_id = "Balt"`, so the current portrait file must stay `Balt.png` unless the unit data is normalized
- `knight` uses `portrait_id = "knight_grunt"`, so it intentionally reuses `knight_grunt.png`

## How Fight Animation Lookup Works

Battle attack animation loading in `scripts/ui/battle_scene.gd` works like this:

1. Try `unit_id`
2. Try `portrait_id`
3. Try `display_name` converted to lowercase snake case
4. Try a class fallback

Current class fallbacks:

- `marauder` -> `brigand_grunt`
- `captain` -> `captain_briar`
- `outrider` -> `rowan`
- `hunter` -> `hunter_grunt`
- `knight` -> `knight_grunt`
- `vanguard` -> `george`
- `mage` -> `ember`

There is no priest fallback right now, so `Brother Hale` falls back to his portrait instead of an attack animation.

## Adding A New Portrait

When adding a portrait for an existing or new unit:

1. Decide whether the portrait should load by `portrait_id` or `unit_id`
2. Put the PNG in `assets/portraits/`
3. Update the corresponding file in `data/units/` if needed
4. Keep the filename exactly aligned with the lookup path the game expects

Recommended pattern for new units:

- Set `portrait_id` to lowercase snake case
- Use a matching filename such as `assets/portraits/new_unit.png`

Current example from a unit resource:

```text
portrait_id = "george"
```

Matching portrait file:

```text
assets/portraits/george.png
```

## Adding A New Fight Animation

The game does not currently play `.mp4` files directly during battle. Instead, battle animations are loaded from extracted image frames.

To add a new fight animation:

1. Place the source video at `assets/fight_animations/<id>_fight.mp4`
2. Extract frames into `assets/fight_animations/<id>/`
3. Name the output frames consistently, such as `frame_001.jpg`, `frame_002.jpg`, and so on
4. Make sure `<id>` matches one of the battle lookup candidates

Example:

```text
assets/fight_animations/sir_aldric_fight.mp4
assets/fight_animations/sir_aldric/frame_001.jpg
assets/fight_animations/sir_aldric/frame_002.jpg
```

Example extraction command:

```bash
ffmpeg -i assets/fight_animations/sir_aldric_fight.mp4 \
  -vf "fps=18,scale=480:-1:flags=lanczos" \
  -q:v 3 \
  assets/fight_animations/sir_aldric/frame_%03d.jpg
```

If the frame folder exists and matches the expected id, the battle scene will use it automatically.

## Current Terrain Art

These terrain textures are already wired into the tactical map:

- `assets/terrain/thicket.png` for `forest`
- `assets/terrain/castle.png` for `castle`

Other terrain types still fall back to `TerrainData.map_color`.

## Pixel Art Import Settings

For portraits, terrain, and animation frames:

1. Open the texture in Godot
2. Turn `Filter` off
3. Turn `Mipmaps` off
4. Use `Lossless` or `Uncompressed` compression
5. Reimport

## What Is Still Missing

If the goal is full roster coverage, the highest-value missing character art is:

1. Portraits for `captain`, `mage`, and `sir_aldric`
2. A priest fight animation for `brother_hale`
3. Dedicated fight animations for `captain`, `mage`, and `sir_aldric` so they stop borrowing class fallback clips

## Notes For Future Cleanup

The current asset pipeline works, but there are a few legacy inconsistencies:

- `Balt.png` uses a capital `B`
- `captain_briar` still has `portrait_id = "briar"` even though the actual file is `captain_briar.png`
- Some units rely on class fallbacks rather than dedicated fight animation ids

If you want a cleaner setup later, normalize all portrait ids and animation ids to lowercase snake case and make the filenames match exactly.
