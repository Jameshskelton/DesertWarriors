# Adding Character Portraits And Artwork

This project currently uses placeholder `ColorRect` blocks and `draw_rect()` calls for portraits, map units, battle units, and terrain. Use the steps below to replace those placeholders with real pixel art.

## 1. Add The Asset Folders

Create these folders:

- `assets/portraits/`
- `assets/map_units/`
- `assets/battle_units/`
- `assets/terrain/`
- `assets/ui/`

Recommended file layout:

```text
assets/
  portraits/
    woody.png
    bram.png
    rowan.png
    ember.png
    hale.png
    briar.png
  map_units/
    woody.png
    bram.png
    rowan.png
    ember.png
    brother_hale.png
    brigand_grunt.png
    hunter_grunt.png
    pursuer_armor.png
    captain_briar.png
  battle_units/
    woody.png
    bram.png
    rowan.png
    ember.png
    brother_hale.png
    brigand_grunt.png
    hunter_grunt.png
    pursuer_armor.png
    captain_briar.png
  terrain/
    plains.png
    forest.png
    road.png
    village.png
    shrine.png
```

Use the same IDs that already exist in the data files under `data/units` and `data/terrains`.

## Character Art Reference

Use these descriptions to keep the portraits, map sprites, and battle art aligned with the current game data.

### Player Characters

- `Woody`: Lord, uses a `Bronze Sword`. He is the exiled prince and should read as young, determined, and heroic. Use royal blue, light gold trim, and a travel-worn cloak rather than full court regalia.
- `Bram`: Knight, uses an `Iron Lance`. He is the tanky protector of the group. His art should emphasize heavy armor, a broad silhouette, and a dependable bodyguard presence.
- `Rowan`: Cavalier, uses an `Iron Lance`. He is the fast mounted ally. Give him lighter armor than Bram, a quick rider silhouette, and warm road-dust colors that sell speed and mobility.
- `Ember`: Mage, uses a `Fire Tome`. She is the glass cannon caster. Use bright red or ember-orange accents, lighter clothing, and a confident or sharp expression that suggests explosive magic.
- `Brother Hale`: Priest, uses a `Heal Staff`. He is the white mage healer. His art should feel calm and steady, with pale robes, staff iconography, and a composed, protective expression.

### Enemy Characters

- `Captain Briar`: Captain, uses `Captain's Axe`. He is the Chapter 1 boss and should feel harsher and more threatening than the regular brigands. Use a stronger silhouette, darker armor or leathers, and details that imply command.
- `Brigand`: Brigand, uses an `Iron Axe`. He is a rough melee raider. Use rugged clothes, simple gear, and an aggressive stance.
- `Hunter`: Hunter, uses a `Hunter Bow`. He is a light ranged enemy. Use leaner proportions, practical forest gear, and colors that blend into woodland terrain.
- `Pursuer`: Knight, uses an `Iron Lance`. He represents the royal forces hunting Woody. Make him read as disciplined and militarized, with armor that looks stricter and more formal than Bram's.

### Visual Class Notes

- `Lord`: clean heroic outline, cape or shoulder mantle, readable sword stance
- `Knight`: square silhouette, large shield or pauldrons, limited visible skin
- `Cavalier`: upright rider posture, lighter armor, mobile silhouette
- `Mage`: robe or coat with strong spellcasting hand pose
- `Priest`: soft robe silhouette, staff-forward stance, less combat aggression
- `Brigand/Captain`: heavy swing posture, rougher shapes, axe-forward framing
- `Hunter`: bow-first silhouette, lighter frame, practical travel clothing

## 2. Use These Art Sizes

Recommended sizes for this project:

- Portraits: `96x96` or `128x128`
- Map unit sprites: `24x24` or `32x32`
- Battle sprites: `64x64` or `96x96`
- Terrain tiles: `16x16` or `32x32`

Because the map currently draws tiles at `32x32`, the fastest path is to import terrain as `32x32` PNGs.

## 3. Godot Import Settings

For every pixel art texture:

1. Select the texture in Godot.
2. In Import:
3. Set `Filter` to `Off`.
4. Set `Mipmaps` to `Off`.
5. Set `Compression` to `Lossless` or `Uncompressed`.
6. Reimport.

If you use sprite sheets:

- Keep frame sizes uniform.
- Use `AnimatedSprite2D` or region-based `AtlasTexture`.

## 4. Dialogue Portraits

Current placeholder location:

- Scene: [dialogue_scene.tscn](/Users/jamesskelton/Downloads/DesertWarriors/scenes/dialogue/dialogue_scene.tscn)
- Script: [dialogue_scene.gd](/Users/jamesskelton/Downloads/DesertWarriors/scripts/ui/dialogue_scene.gd)

Right now the dialogue scene uses:

- `PortraitFrame` as a solid color block
- `PortraitLabel` as text

### Replace It

In the scene:

1. Keep `PortraitFrame`.
2. Add a `TextureRect` inside it named `PortraitTexture`.
3. Anchor it full size.
4. Set `Expand Mode` to `Ignore Size` or `Fit Width/Height`.
5. Set `Stretch Mode` to `Keep Aspect Centered`.

Then in `dialogue_scene.gd`:

1. Add an `@onready` reference to `PortraitTexture`.
2. Load a texture using the speaker name or a new `portrait_id`.
3. Set the texture instead of changing only the frame color.

Recommended approach:

- Add `portrait_id` to each dialogue line in `data/chapters/chapter_1.tres`.
- Fall back to speaker-name mapping only if `portrait_id` is missing.

Example dialogue entry:

```gdscript
{
    "chapter": "Chapter 1: Exile in the Greenwood",
    "speaker": "Woody",
    "portrait_id": "woody",
    "text": "They have taken my crown, but not my name."
}
```

Recommended helper:

```gdscript
func _load_portrait(portrait_id: String) -> Texture2D:
    var path := "res://assets/portraits/%s.png" % portrait_id
    if ResourceLoader.exists(path):
        return load(path)
    return null
```

Then in `_render_line()`:

```gdscript
var portrait_id := str(line.get("portrait_id", "")).to_lower()
_portrait_texture.texture = _load_portrait(portrait_id)
_portrait_label.visible = _portrait_texture.texture == null
```

## 5. Map Unit Artwork

Current placeholder location:

- Script: [tactical_map.gd](/Users/jamesskelton/Downloads/DesertWarriors/scripts/controllers/tactical_map.gd)

Right now units are drawn here:

- `_draw_units()`
- `draw_rect(...)`
- `draw_string(...)`

### Replace It

Add a texture cache:

```gdscript
var _map_unit_textures: Dictionary = {}
```

Add a loader:

```gdscript
func _get_map_unit_texture(unit: UnitState) -> Texture2D:
    var candidates := [
        "res://assets/map_units/%s.png" % unit.unit_id,
        "res://assets/map_units/%s.png" % DataRegistry.get_unit_data(unit.unit_id).id
    ]
    for path in candidates:
        if ResourceLoader.exists(path):
            return load(path)
    return null
```

Inside `_draw_units()`:

1. Compute the unit rect as you already do.
2. Load the texture.
3. Use `draw_texture_rect(texture, rect, false)`.
4. Keep the moved-unit dark overlay and the cursor highlight.

Minimal replacement:

```gdscript
var texture := _get_map_unit_texture(unit)
if texture != null:
    draw_texture_rect(texture, rect, false)
else:
    draw_rect(rect, _unit_color(unit))
```

## 6. Terrain Artwork

Current placeholder location:

- Script: [tactical_map.gd](/Users/jamesskelton/Downloads/DesertWarriors/scripts/controllers/tactical_map.gd)
- Method: `_draw_board()`

Right now terrain is drawn using `terrain.map_color`.

### Replace It

Add terrain textures keyed by terrain ID:

```gdscript
func _get_terrain_texture(terrain_id: String) -> Texture2D:
    var path := "res://assets/terrain/%s.png" % terrain_id
    if ResourceLoader.exists(path):
        return load(path)
    return null
```

Then replace:

```gdscript
draw_rect(rect, terrain.map_color)
```

with:

```gdscript
var texture := _get_terrain_texture(terrain_id)
if texture != null:
    draw_texture_rect(texture, rect, false)
else:
    draw_rect(rect, terrain.map_color)
```

Keep these overlays:

- grid border
- movement highlight
- attack target highlight
- cursor border

They still work well over art.

## 7. Battle Artwork

Current placeholder location:

- Scene: [battle_scene.tscn](/Users/jamesskelton/Downloads/DesertWarriors/scenes/battle/battle_scene.tscn)
- Script: [battle_scene.gd](/Users/jamesskelton/Downloads/DesertWarriors/scripts/ui/battle_scene.gd)

Right now the battle scene uses:

- `LeftSprite` as a `ColorRect`
- `RightSprite` as a `ColorRect`

### Replace It

In the scene:

1. Replace `LeftSprite` with a `TextureRect` named `LeftPortrait` or `LeftBattleSprite`.
2. Replace `RightSprite` with a `TextureRect` named `RightPortrait` or `RightBattleSprite`.
3. Keep the HP bars and labels.

In the script:

1. Change the onready variables to `TextureRect`.
2. Load textures from `assets/battle_units/`.
3. Assign textures during `_apply_initial_state()`.

Recommended helper:

```gdscript
func _get_battle_texture(unit: UnitState) -> Texture2D:
    var path := "res://assets/battle_units/%s.png" % unit.unit_id
    if ResourceLoader.exists(path):
        return load(path)
    return null
```

If you want animation:

- Use `AnimatedSprite2D` instead of `TextureRect`.
- Add `idle`, `attack`, `hit`, and `crit` animations.
- Trigger them inside `_play_sequence()`.

## 8. Use `portrait_id` Properly

The data model already has `portrait_id` on [unit_data.gd](/Users/jamesskelton/Downloads/DesertWarriors/scripts/models/unit_data.gd).

Use it consistently:

- `woody` -> `assets/portraits/woody.png`
- `briar` -> `assets/portraits/briar.png`
- `hale` -> `assets/portraits/hale.png`

For best consistency, also add optional fields later if needed:

- `map_sprite_id`
- `battle_sprite_id`

That lets one unit reuse portrait art while using a different battle or map sheet.

## 9. Recommended Naming Rules

Use lowercase snake case only:

- `woody.png`
- `brother_hale.png`
- `captain_briar.png`

Avoid spaces and mixed naming. It keeps resource loading simple.

## 10. Suggested Art Production Order

Do this in order:

1. Portraits for Woody, Bram, Rowan, Ember, Brother Hale, and Briar
2. Terrain tiles for plains, forest, road, village, shrine
3. Map unit sprites for player classes and enemy classes
4. Battle sprites for player units and boss
5. UI frame art for title, dialogue, forecast, and result panels

That order gives the biggest visual improvement fastest.

## 11. Fastest Minimal Upgrade

If you want the quickest visible improvement without refactoring much:

1. Add terrain PNGs.
2. Add portrait PNGs.
3. Add battle PNGs.
4. Leave map units as colored squares for one more pass.

That gives you:

- a real-looking battlefield
- real dialogue portraits
- real combat cutaways

without changing the tactical logic much.

## 12. Best Long-Term Upgrade

If you want a cleaner art pipeline later:

1. Replace custom map drawing with `TileMapLayer` for terrain.
2. Spawn unit nodes instead of drawing them manually in `_draw_units()`.
3. Add a small `ArtRegistry` singleton that maps IDs to textures.
4. Move all portrait/map/battle lookups into that registry.

That will scale much better once you add more chapters and classes.

## 13. Final Checklist

- Portrait files exist for all speaking characters.
- Terrain files exist for all terrain IDs in `chapter_1.tres`.
- Map unit files exist for all deployed units.
- Battle unit files exist for all combatants.
- Godot import filter is off for all pixel art.
- Dialogue scene loads portrait textures.
- Tactical map loads terrain textures.
- Tactical map loads unit textures or falls back cleanly.
- Battle scene loads battle textures.
- Missing art falls back to placeholder colors instead of crashing.
