extends Control

signal request_dialogue(lines: Array, next_tag: String)
signal chapter_cleared(summary: Dictionary)
signal chapter_failed(summary: Dictionary)
signal suspend_requested
signal restart_requested(chapter_id: String)

const BATTLE_SCENE := preload("res://scenes/battle/battle_scene.tscn")
const DIALOGUE_SCENE := preload("res://scenes/dialogue/dialogue_scene.tscn")
const CASTLE_TEXTURE := preload("res://assets/terrain/castle.png")
const MOUNTAIN_TEXTURE := preload("res://assets/terrain/mountain.png")
const TALL_MOUNTAIN_TEXTURE := preload("res://assets/terrain/tall_mountain.png")
const THICKET_TEXTURE := preload("res://assets/terrain/thicket.png")
const VILLAGE_TEXTURE := preload("res://assets/terrain/village.png")
const PORTRAIT_DIR := "res://assets/portraits"
const UI_FONT := preload("res://font/new_font.ttf")
const UI_SCALE := 1.5
const MAP_UNIT_TEXTURE_DIR := "res://assets/map_units"
const MAP_UNIT_SPRITE_SCALE := 1.5
const MOVEMENT_PATH_COLOR := Color(0.462745, 0.815686, 0.960784, 0.72)
const MOVEMENT_PATH_SHADOW := Color(0.0392157, 0.0745098, 0.121569, 0.28)
const DANGER_ZONE_BASE_COLOR := Color(0.839216, 0.215686, 0.176471, 0.16)
const DANGER_ZONE_INTENSE_COLOR := Color(0.960784, 0.333333, 0.27451, 0.28)
const PLAYER_ATTACK_RANGE_COLOR := Color(0.980392, 0.647059, 0.196078, 0.26)
const MAP_UNIT_CLASS_FALLBACKS := {
	"brigand": "brigand_grunt",
	"captain": "captain_grunt",
	"cavalier": "rowan",
	"hunter": "hunter_grunt",
	"knight": "knight_grunt",
	"lord": "george",
	"mage": "ember",
	"priest": "hale",
}

var _chapter_id: String = ""
var _chapter: ChapterData
var _terrain_grid: Array = []
var _units: Array[UnitState] = []
var _grid_size: Vector2i = Vector2i(20, 15)
var _cursor_tile: Vector2i = Vector2i(0, 0)
var _cell_size: float = 32.0 * UI_SCALE
var _board_origin: Vector2 = Vector2(56.0, 96.0) * UI_SCALE
var _selection: SelectionController = SelectionController.new()
var _grid: GridService = GridService.new()
var _pathfinding: PathfindingService = PathfindingService.new()
var _turn_controller: TurnController = TurnController.new()
var _objective_controller: ObjectiveController = ObjectiveController.new()
var _event_director: EventDirector = EventDirector.new()
var _combat_resolver: CombatResolver = CombatResolver.new()
var _danger_zone_service: DangerZoneService = DangerZoneService.new()
var _item_service: ItemService = ItemService.new()
var _ai_controller: AIController = AIController.new()
var _battle_transition: BattleTransitionController = BattleTransitionController.new()
var _active_battle: Control
var _active_dialogue: Control
var _map_unit_texture_cache: Dictionary = {}
var _spawned_reinforcements: PackedStringArray = PackedStringArray()
var _danger_zone_visible: bool = false
var _danger_zone_tiles: Dictionary = {}

@onready var _chapter_label: Label = $Header/HeaderMargin/HeaderRow/ChapterLabel
@onready var _turn_label: Label = $Header/HeaderMargin/HeaderRow/TurnLabel
@onready var _phase_label: Label = $Header/HeaderMargin/HeaderRow/PhaseLabel
@onready var _objective_label: Label = $Header/HeaderMargin/HeaderRow/ObjectiveLabel
@onready var _status_label: Label = $Footer/FooterMargin/FooterVBox/StatusLabel
@onready var _hint_label: Label = $Footer/FooterMargin/FooterVBox/HintLabel
@onready var _action_menu = $ActionMenu
@onready var _forecast_panel = $ForecastPanel
@onready var _portrait_panel: PanelContainer = $PortraitPanel
@onready var _portrait_name: Label = $PortraitPanel/PortraitMargin/PortraitVBox/PortraitName
@onready var _portrait_frame: ColorRect = $PortraitPanel/PortraitMargin/PortraitVBox/PortraitFrame
@onready var _portrait_texture: TextureRect = $PortraitPanel/PortraitMargin/PortraitVBox/PortraitFrame/PortraitTexture
@onready var _portrait_fallback: Label = $PortraitPanel/PortraitMargin/PortraitVBox/PortraitFrame/PortraitFallback
@onready var _portrait_details: Label = $PortraitPanel/PortraitMargin/PortraitVBox/PortraitDetails
@onready var _portrait_warning: Label = $PortraitPanel/PortraitMargin/PortraitVBox/PortraitWarning
@onready var _battle_layer: Control = $BattleLayer
@onready var _help_panel = $HelpPanel
@onready var _help_close_button: Button = $HelpPanel/HelpMargin/HelpVBox/CloseButton
@onready var _system_menu: PanelContainer = $SystemMenu
@onready var _system_suspend_button: Button = $SystemMenu/SystemMargin/SystemVBox/SuspendButton
@onready var _system_restart_button: Button = $SystemMenu/SystemMargin/SystemVBox/RestartButton
@onready var _system_close_button: Button = $SystemMenu/SystemMargin/SystemVBox/CloseButton


func setup(chapter_id: String) -> void:
	_chapter_id = chapter_id


func _ready() -> void:
	add_child(_battle_transition)
	_help_panel.visible = false
	_system_menu.visible = false
	if _help_close_button != null:
		_help_close_button.pressed.connect(func() -> void:
			_help_panel.visible = false
		)
	_system_suspend_button.pressed.connect(Callable(self, "_on_system_suspend_pressed"))
	_system_restart_button.pressed.connect(Callable(self, "_on_system_restart_pressed"))
	_system_close_button.pressed.connect(Callable(self, "_close_system_menu"))
	_battle_transition.battle_overlay_requested.connect(Callable(self, "_show_battle_overlay"))
	_action_menu.action_selected.connect(Callable(self, "_on_action_menu_selected"))
	_load_chapter()
	AudioDirector.play_track("forest_realm")


func _load_chapter() -> void:
	_chapter = DataRegistry.get_chapter_data(_chapter_id)
	if _chapter == null:
		push_error("Failed to load chapter data: " + _chapter_id)
		return
	_grid_size = Vector2i(_chapter.map_width, _chapter.map_height)
	_terrain_grid = _build_terrain_grid(_chapter)
	_selection.reset()
	_action_menu.hide_menu()
	_forecast_panel.hide_panel()
	_spawned_reinforcements.clear()
	_units.clear()
	_event_director.reset()
	if not _restore_suspend_state(GameState.suspend_state):
		for entry in _chapter.starting_units:
			_spawn_unit(entry)
		for entry in _chapter.enemy_units:
			_spawn_unit(entry)
		_turn_controller.begin_battle(_units)
		_cursor_tile = Vector2i(1, _grid_size.y - 2)
	_update_header()
	_refresh_danger_zone()
	_update_hint()
	_update_status(_build_resume_status())
	_update_hover_status()
	queue_redraw()


func _build_terrain_grid(chapter: ChapterData) -> Array:
	var terrain_grid: Array = []
	var fallback_terrain_id := _get_fallback_terrain_id(chapter)
	if chapter.terrain_rows.size() != chapter.map_height:
		push_warning("Chapter %s has %d terrain rows but expected %d. Normalizing map data." % [chapter.id, chapter.terrain_rows.size(), chapter.map_height])
	for y in range(chapter.map_height):
		var row := chapter.terrain_rows[y] if y < chapter.terrain_rows.size() else ""
		if row.length() != chapter.map_width:
			push_warning("Chapter %s row %d has width %d but expected %d. Normalizing map data." % [chapter.id, y, row.length(), chapter.map_width])
		var parsed_row: Array = []
		for x in range(chapter.map_width):
			var terrain_id := fallback_terrain_id
			if x < row.length():
				var character: String = row.substr(x, 1)
				terrain_id = chapter.terrain_legend.get(character, fallback_terrain_id)
			parsed_row.append(terrain_id)
		terrain_grid.append(parsed_row)
	return terrain_grid


func _get_fallback_terrain_id(chapter: ChapterData) -> String:
	if chapter.terrain_legend.has("F"):
		return str(chapter.terrain_legend["F"])
	if not chapter.terrain_legend.is_empty():
		return str(chapter.terrain_legend.values()[0])
	return "plains"


func _restore_suspend_state(snapshot: Dictionary) -> bool:
	if not GameState.has_suspend_state_for_chapter(_chapter_id) or snapshot.is_empty():
		return false
	var unit_states_value: Variant = snapshot.get("units", [])
	if not (unit_states_value is Array):
		return false
	var restored_units: Array[UnitState] = []
	for entry_value in unit_states_value:
		if typeof(entry_value) != TYPE_DICTIONARY:
			continue
		var restored_unit: UnitState = UnitState.from_battle_state(entry_value)
		if restored_unit != null:
			restored_units.append(restored_unit)
	if restored_units.is_empty():
		return false
	_units = restored_units
	_spawned_reinforcements = _variant_to_packed_string_array(snapshot.get("spawned_reinforcements", PackedStringArray()))
	_event_director.handled_events = _variant_to_packed_string_array(snapshot.get("handled_events", PackedStringArray()))
	_turn_controller.turn_number = maxi(1, int(snapshot.get("turn_number", 1)))
	_turn_controller.phase = str(snapshot.get("phase", "player"))
	if _turn_controller.phase != "player":
		_turn_controller.phase = "player"
	_cursor_tile = _vector2i_from_variant(snapshot.get("cursor_tile", Vector2i(1, _grid_size.y - 2)))
	_danger_zone_visible = bool(snapshot.get("danger_zone_visible", false))
	return true


func _build_resume_status() -> String:
	if GameState.has_suspend_state_for_chapter(_chapter_id):
		return "Suspended battle resumed. Choose a unit to continue."
	return "Player phase. Choose a unit to act."


func _build_suspend_snapshot() -> Dictionary:
	var units: Array[Dictionary] = []
	for unit in _units:
		units.append(unit.to_battle_state())
	return {
		"chapter_id": _chapter_id,
		"turn_number": _turn_controller.turn_number,
		"phase": _turn_controller.phase,
		"cursor_tile": {
			"x": _cursor_tile.x,
			"y": _cursor_tile.y,
		},
		"danger_zone_visible": _danger_zone_visible,
		"spawned_reinforcements": _packed_string_array_to_array(_spawned_reinforcements),
		"handled_events": _packed_string_array_to_array(_event_director.handled_events),
		"units": units,
	}


func _spawn_unit(entry: Dictionary, allow_missing_player_state: bool = false) -> void:
	var unit_id: String = str(entry.get("unit_id", ""))
	var unit_data: UnitData = DataRegistry.get_unit_data(unit_id)
	if unit_data == null:
		return
	var position = entry.get("position", Vector2i.ZERO)
	var faction_override: String = str(entry.get("faction", ""))
	var state: UnitState = UnitState.from_unit_data(unit_data, position, faction_override)
	var can_fall_back_to_default_state: bool = allow_missing_player_state or not unit_data.join_event_id.is_empty()
	if state.faction == "player" and not GameState.restore_player_unit_state(state, unit_id, can_fall_back_to_default_state):
		return
	if entry.has("instance_id") and state.faction != "player":
		state.unit_id = entry["instance_id"]
	_units.append(state)
	_refresh_danger_zone()


func _draw() -> void:
	_draw_board()
	_draw_movement_preview()
	_draw_units()


func _draw_board() -> void:
	var player_attack_preview_tiles: Dictionary = _build_player_attack_preview_tiles()
	for y in range(_grid_size.y):
		for x in range(_grid_size.x):
			var tile := Vector2i(x, y)
			var terrain_id: String = _terrain_grid[y][x]
			var terrain: TerrainData = DataRegistry.get_terrain_data(terrain_id)
			var rect := Rect2(_board_origin + Vector2(x, y) * _cell_size, Vector2.ONE * _cell_size)
			draw_rect(rect, terrain.map_color)
			if terrain_id == "castle" and CASTLE_TEXTURE != null:
				draw_texture_rect(CASTLE_TEXTURE, rect, false)
			if terrain_id == "tall_mountain" and TALL_MOUNTAIN_TEXTURE != null:
				draw_texture_rect(TALL_MOUNTAIN_TEXTURE, rect, false)
			if terrain_id == "mountain" and MOUNTAIN_TEXTURE != null:
				draw_texture_rect(MOUNTAIN_TEXTURE, rect, false)
			if terrain_id == "forest" and THICKET_TEXTURE != null:
				draw_texture_rect(THICKET_TEXTURE, rect, false)
			if terrain_id == "village" and VILLAGE_TEXTURE != null:
				draw_texture_rect(VILLAGE_TEXTURE, rect, false)
			if _danger_zone_visible and _danger_zone_tiles.has(tile):
				var threat_count: int = int(_danger_zone_tiles.get(tile, 0))
				var threat_alpha: float = clampf(0.12 + float(mini(threat_count, 4)) * 0.04, 0.12, 0.28)
				var threat_color: Color = DANGER_ZONE_BASE_COLOR
				if threat_count >= 3:
					threat_color = DANGER_ZONE_INTENSE_COLOR
				threat_color.a = threat_alpha
				draw_rect(rect.grow(-2.0), threat_color)
			if player_attack_preview_tiles.has(tile):
				draw_rect(rect.grow(-4.0), PLAYER_ATTACK_RANGE_COLOR)
			draw_rect(rect, Color(0, 0, 0, 0.2), false, 1.5)
			if _selection.highlighted_tiles.has(tile):
				draw_rect(rect.grow(-3.0), Color(0.309804, 0.686275, 0.929412, 0.35))
			if _selection.target_tiles.has(tile):
				draw_rect(rect.grow(-6.0), Color(0.929412, 0.4, 0.360784, 0.45))
	var cursor_rect := Rect2(_board_origin + Vector2(_cursor_tile.x, _cursor_tile.y) * _cell_size, Vector2.ONE * _cell_size)
	draw_rect(cursor_rect.grow(-1.5), Color(0.980392, 0.941176, 0.745098, 1), false, 4.5)


func _draw_movement_preview() -> void:
	if _selection.preview_path.size() < 2:
		return
	var points := PackedVector2Array()
	for tile in _selection.preview_path:
		points.append(_tile_center(tile))
	draw_polyline(points, MOVEMENT_PATH_SHADOW, 13.5 * UI_SCALE, true)
	draw_polyline(points, MOVEMENT_PATH_COLOR, 8.0 * UI_SCALE, true)
	for point in points:
		draw_circle(point, 4.0 * UI_SCALE, MOVEMENT_PATH_COLOR)
	_draw_movement_arrowhead(points[points.size() - 2], points[points.size() - 1])


func _draw_movement_arrowhead(from_point: Vector2, to_point: Vector2) -> void:
	var direction := (to_point - from_point).normalized()
	if direction == Vector2.ZERO:
		return
	var tip := to_point
	var shadow_base := tip - direction * (18.0 * UI_SCALE)
	var shadow_side := direction.orthogonal() * (10.0 * UI_SCALE)
	draw_colored_polygon(
		PackedVector2Array([tip, shadow_base + shadow_side, shadow_base - shadow_side]),
		MOVEMENT_PATH_SHADOW
	)
	var base := tip - direction * (15.0 * UI_SCALE)
	var side := direction.orthogonal() * (8.0 * UI_SCALE)
	draw_colored_polygon(PackedVector2Array([tip, base + side, base - side]), MOVEMENT_PATH_COLOR)


func _tile_center(tile: Vector2i) -> Vector2:
	return _board_origin + (Vector2(tile) + Vector2.ONE * 0.5) * _cell_size


func _draw_units() -> void:
	var font := UI_FONT
	var unit_padding := 5.0 * UI_SCALE
	for unit in _units:
		if not unit.is_alive() or not unit.has_joined:
			continue
		var rect := Rect2(
			_board_origin + Vector2(unit.position.x, unit.position.y) * _cell_size + Vector2.ONE * unit_padding,
			Vector2.ONE * (_cell_size - unit_padding * 2.0)
		)
		var texture: Texture2D = _load_map_unit_texture_for_unit(unit)
		var visual_rect: Rect2 = rect
		if texture != null:
			var sprite_size: Vector2 = rect.size * MAP_UNIT_SPRITE_SCALE
			visual_rect = Rect2(
				Vector2(rect.get_center().x - sprite_size.x / 2.0, rect.end.y - sprite_size.y),
				sprite_size
			)
			draw_texture_rect(texture, visual_rect, false)
		else:
			draw_rect(rect, _unit_color(unit))
			draw_string(font, rect.position + Vector2(6.0, 18.0) * UI_SCALE, unit.display_name.left(1), HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color.WHITE)
		if unit.moved and unit.faction == "player":
			draw_rect(visual_rect.grow(-4.5), Color(0, 0, 0, 0.4), false, 3.0)


func _unhandled_input(event: InputEvent) -> void:
	if _active_dialogue != null:
		return
	if event.is_action_pressed("open_system_menu"):
		_toggle_system_menu()
		return
	if event is InputEventKey and event.pressed and (event.keycode == KEY_H or event.keycode == KEY_F1):
		if _system_menu.visible:
			return
		_help_panel.visible = not _help_panel.visible
		return
	if _help_panel.visible:
		if event.is_action_pressed("ui_cancel"):
			_help_panel.visible = false
		return
	if _system_menu.visible:
		if event.is_action_pressed("ui_cancel"):
			_close_system_menu()
		return
	if _active_battle != null or _turn_controller.phase != "player":
		return
	if event is InputEventMouseMotion:
		var hovered_tile := _screen_to_tile(event.position)
		if _grid.in_bounds(hovered_tile, _grid_size) and hovered_tile != _cursor_tile:
			_cursor_tile = hovered_tile
			_update_movement_preview()
			_update_hover_status()
			queue_redraw()
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var clicked_tile := _screen_to_tile(event.position)
		if _grid.in_bounds(clicked_tile, _grid_size):
			_cursor_tile = clicked_tile
			_confirm_cursor()
			_update_movement_preview()
			_update_hover_status()
			queue_redraw()
			return
	if event.is_action_pressed("ui_up"):
		_cursor_tile.y = maxi(0, _cursor_tile.y - 1)
	elif event.is_action_pressed("ui_down"):
		_cursor_tile.y = mini(_grid_size.y - 1, _cursor_tile.y + 1)
	elif event.is_action_pressed("ui_left"):
		_cursor_tile.x = maxi(0, _cursor_tile.x - 1)
	elif event.is_action_pressed("ui_right"):
		_cursor_tile.x = mini(_grid_size.x - 1, _cursor_tile.x + 1)
	elif event.is_action_pressed("ui_accept"):
		_confirm_cursor()
	elif event.is_action_pressed("ui_cancel"):
		_cancel_selection()
	elif event.is_action_pressed("toggle_danger_zone"):
		_toggle_danger_zone()
	elif event.is_action_pressed("end_turn") and _selection.mode == SelectionController.Mode.IDLE:
		_begin_enemy_phase()
	_update_movement_preview()
	queue_redraw()
	_update_hover_status()


func _confirm_cursor() -> void:
	match _selection.mode:
		SelectionController.Mode.IDLE:
			_select_unit_at_cursor()
		SelectionController.Mode.UNIT_SELECTED:
			_try_move_selected_unit()
		SelectionController.Mode.TARGETING:
			_try_target_action()


func _cancel_selection() -> void:
	if _selection.mode == SelectionController.Mode.ACTION_MENU or _selection.mode == SelectionController.Mode.TARGETING:
		if _selection.selected_unit != null:
			_selection.selected_unit.position = _selection.origin_tile
			_selection.selected_unit.moved = false
	_action_menu.hide_menu()
	_forecast_panel.hide_panel()
	_selection.reset()
	_refresh_danger_zone()
	_update_status("Selection cancelled.")
	queue_redraw()


func _toggle_system_menu() -> void:
	if _system_menu.visible:
		_close_system_menu()
		return
	if _active_battle != null or _active_dialogue != null:
		return
	if _turn_controller.phase != "player":
		_update_status("Suspend and restart are only available during your phase.")
		return
	if _selection.mode != SelectionController.Mode.IDLE:
		_update_status("Finish or cancel the current action before opening the system menu.")
		return
	_help_panel.visible = false
	_system_menu.visible = true
	_system_suspend_button.grab_focus()


func _close_system_menu() -> void:
	_system_menu.visible = false


func _on_system_suspend_pressed() -> void:
	var snapshot: Dictionary = _build_suspend_snapshot()
	GameState.set_suspend_state(snapshot)
	if not SaveSystem.save_game(GameState.build_save_payload()):
		_update_status("Suspend save failed.")
		return
	_close_system_menu()
	suspend_requested.emit()


func _on_system_restart_pressed() -> void:
	GameState.clear_suspend_state()
	SaveSystem.save_game(GameState.build_save_payload())
	_close_system_menu()
	restart_requested.emit(_chapter_id)


func _select_unit_at_cursor() -> void:
	var unit := _get_unit_at(_cursor_tile)
	if unit == null or unit.faction != "player" or unit.moved or not unit.is_alive():
		return
	var class_data: ClassData = DataRegistry.get_class_data(unit.class_id)
	var reachability := _pathfinding.compute_reachable(unit.position, class_data.move_range, _terrain_grid, class_data.move_type, _build_occupied_lookup(unit), unit.faction)
	_selection.mode = SelectionController.Mode.UNIT_SELECTED
	_selection.selected_unit = unit
	_selection.origin_tile = unit.position
	_selection.reachability = reachability
	_selection.highlighted_tiles = reachability.get("costs", {})
	_update_movement_preview()
	_update_status("%s selected. Choose a destination." % unit.display_name)


func _try_move_selected_unit() -> void:
	var selected: UnitState = _selection.selected_unit
	if selected == null:
		return
	if not _selection.highlighted_tiles.has(_cursor_tile):
		return
	_selection.preview_path = _pathfinding.build_path(_selection.origin_tile, _cursor_tile, _selection.reachability)
	selected.position = _cursor_tile
	selected.moved = true
	_refresh_danger_zone()
	_selection.mode = SelectionController.Mode.ACTION_MENU
	_show_action_menu(selected)


func _show_action_menu(unit: UnitState) -> void:
	var action_states := {
		"attack": _has_attack_targets(unit),
		"staff": _has_heal_targets(unit),
		"item": _has_usable_items(unit),
		"wait": true,
		"cancel": true,
	}
	if _can_visit_village(unit):
		action_states["visit"] = true
	_action_menu.show_actions(action_states)
	_update_status("Choose an action for %s." % unit.display_name)


func _on_action_menu_selected(action_name: String) -> void:
	var unit: UnitState = _selection.selected_unit
	if unit == null:
		return
	match action_name:
		"attack":
			_selection.mode = SelectionController.Mode.TARGETING
			_selection.pending_action = "attack"
			_selection.target_tiles = _valid_attack_tiles(unit)
			_action_menu.hide_menu()
			_update_status("Select an enemy target.")
		"staff":
			_selection.mode = SelectionController.Mode.TARGETING
			_selection.pending_action = "staff"
			_selection.target_tiles = _valid_heal_tiles(unit)
			_action_menu.hide_menu()
			_update_status("Select an ally to heal.")
		"item":
			_execute_item(unit)
		"visit":
			_execute_visit(unit)
		"wait":
			unit.consume_turn()
			_finish_unit_action()
		"cancel":
			_cancel_selection()
	queue_redraw()


func _try_target_action() -> void:
	if not _selection.target_tiles.has(_cursor_tile):
		return
	var source: UnitState = _selection.selected_unit
	var target := _get_unit_at(_cursor_tile)
	if source == null or target == null:
		return
	match _selection.pending_action:
		"attack":
			await _execute_attack(source, target)
		"staff":
			_execute_staff(source, target)


func _execute_attack(source: UnitState, target: UnitState) -> void:
	await _play_pre_battle_dialogue_if_needed(source, target)
	source.consume_turn()
	var attacker_terrain := _get_terrain_at(source.position)
	var defender_terrain := _get_terrain_at(target.position)
	var payload := {
		"attacker": source,
		"defender": target,
		"attacker_start_hp": source.get_current_hp(),
		"defender_start_hp": target.get_current_hp(),
		"result": _combat_resolver.resolve_battle(source, target, attacker_terrain, defender_terrain),
	}
	_selection.mode = SelectionController.Mode.BATTLE
	_forecast_panel.hide_panel()
	_selection.target_tiles.clear()
	_battle_transition.begin_battle(payload)
	await _battle_completed()
	_finish_unit_action()


func _execute_staff(source: UnitState, target: UnitState) -> void:
	var outcome := _combat_resolver.resolve_staff(source, target)
	source.consume_turn()
	_update_status("%s heals %s for %d HP." % [outcome.get("user_name", source.display_name), outcome.get("target_name", target.display_name), outcome.get("heal_amount", 0)])
	_finish_unit_action()


func _execute_item(source: UnitState) -> void:
	var outcome: Dictionary = _item_service.use_first_item(source)
	if outcome.is_empty():
		_update_status("%s has no usable items right now." % source.display_name)
		return
	source.consume_turn()
	_update_status("%s uses %s and recovers %d HP." % [
		outcome.get("user_name", source.display_name),
		outcome.get("item_name", "an item"),
		outcome.get("heal_amount", 0),
	])
	_finish_unit_action()


func _play_pre_battle_dialogue_if_needed(attacker: UnitState, defender: UnitState) -> void:
	var event: Dictionary = _event_director.consume_boss_confront_event(attacker, defender, _chapter)
	if event.is_empty():
		return
	if event.has("message"):
		_update_status(str(event.get("message", "")))
	var lines: Array = event.get("dialogue_lines", [])
	if lines.is_empty():
		return
	_show_dialogue_overlay(lines)
	while _active_dialogue != null:
		await get_tree().process_frame


func _execute_visit(source: UnitState) -> void:
	var visit_events: Array[Dictionary] = _event_director.peek_tile_events(source.unit_id, source.position, _chapter)
	source.consume_turn()
	if visit_events.is_empty():
		_update_status("%s visits the village, but it has no further aid to offer." % source.display_name)
	_finish_unit_action(true)


func _show_battle_overlay(payload: Dictionary) -> void:
	var battle_scene: Control = BATTLE_SCENE.instantiate()
	battle_scene.setup(payload)
	battle_scene.battle_finished.connect(Callable(self, "_on_battle_finished"))
	_active_battle = battle_scene
	_battle_layer.add_child(battle_scene)


func _battle_completed() -> void:
	while _active_battle != null:
		await get_tree().process_frame


func _on_battle_finished() -> void:
	if _active_battle != null:
		_active_battle.queue_free()
		_active_battle = null
	_refresh_danger_zone()
	queue_redraw()


func _finish_unit_action(allow_village_tile_events: bool = false) -> void:
	_action_menu.hide_menu()
	_forecast_panel.hide_panel()
	_handle_tile_events(_selection.selected_unit, allow_village_tile_events)
	_selection.reset()
	_update_hover_status()
	queue_redraw()
	if _check_end_conditions():
		return
	if _active_dialogue != null:
		return
	if _all_player_units_acted():
		_begin_enemy_phase()


func _begin_enemy_phase() -> void:
	_turn_controller.enter_enemy_phase()
	_selection.mode = SelectionController.Mode.ENEMY_PHASE
	_update_header()
	_update_status("Enemy phase...")
	await _run_enemy_phase()
	if _check_end_conditions():
		return
	_turn_controller.enter_player_phase(_units)
	_process_turn_events()
	_selection.reset()
	_update_header()
	_refresh_danger_zone()
	_update_status("Player phase. Press T to end turn if needed.")
	queue_redraw()


func _run_enemy_phase() -> void:
	for unit in _units:
		if unit.faction != "enemy" or not unit.is_alive():
			continue
		var action := _ai_controller.choose_action(unit, _units, _terrain_grid)
		match action.get("type", "wait"):
			"move_wait":
				unit.position = action.get("destination", unit.position)
				await get_tree().create_timer(0.15).timeout
			"move_attack":
				unit.position = action.get("destination", unit.position)
				var target := action.get("target") as UnitState
				if target != null and target.is_alive():
					await _play_pre_battle_dialogue_if_needed(unit, target)
					var payload := {
						"attacker": unit,
						"defender": target,
						"attacker_start_hp": unit.get_current_hp(),
						"defender_start_hp": target.get_current_hp(),
						"result": _combat_resolver.resolve_battle(unit, target, _get_terrain_at(unit.position), _get_terrain_at(target.position)),
					}
					_battle_transition.begin_battle(payload)
					await _battle_completed()
		_refresh_danger_zone()
		queue_redraw()
		if _check_end_conditions():
			return


func _process_turn_events() -> void:
	for reinforcement in _chapter.reinforcements:
		var reinforcement_id: String = str(reinforcement.get("instance_id", reinforcement.get("unit_id", "")))
		if int(reinforcement.get("turn", -1)) == _turn_controller.turn_number and not _spawned_reinforcements.has(reinforcement_id):
			_spawned_reinforcements.append(reinforcement_id)
			_spawn_unit(reinforcement, true)
			if reinforcement.has("message"):
				_update_status(str(reinforcement.get("message", "")))
			if reinforcement.has("dialogue_lines"):
				_show_dialogue_overlay(reinforcement.get("dialogue_lines", []))
	var turn_events := _event_director.consume_turn_events(_turn_controller.turn_number, _chapter)
	for event in turn_events:
		_execute_event(event)
	_refresh_danger_zone()
	queue_redraw()


func _show_dialogue_overlay(lines: Array) -> void:
	if lines.is_empty() or _active_dialogue != null:
		return
	_action_menu.hide_menu()
	_forecast_panel.hide_panel()
	_help_panel.visible = false
	var dialogue_scene: Control = DIALOGUE_SCENE.instantiate()
	dialogue_scene.setup(lines, "map_resume")
	dialogue_scene.dialogue_finished.connect(Callable(self, "_on_dialogue_overlay_finished"))
	_active_dialogue = dialogue_scene
	add_child(dialogue_scene)


func _on_dialogue_overlay_finished(_next_tag: String) -> void:
	if _active_dialogue != null:
		_active_dialogue.queue_free()
		_active_dialogue = null
	queue_redraw()
	_update_hover_status()
	if _check_end_conditions():
		return
	if _turn_controller.phase == "player" and _selection.mode == SelectionController.Mode.IDLE and _all_player_units_acted():
		_begin_enemy_phase()


func _handle_tile_events(unit: UnitState, allow_village_tile_events: bool = false) -> void:
	if unit == null:
		return
	if _get_terrain_id_at(unit.position) == "village" and not allow_village_tile_events:
		return
	var events := _event_director.consume_tile_events(unit.unit_id, unit.position, _chapter)
	for event in events:
		_execute_event(event)


func _execute_event(event: Dictionary) -> void:
	match event.get("action", ""):
		"spawn_join":
			_spawn_unit(event.get("spawn", {}), true)
			_update_status(str(event.get("message", "A new ally joins the cause.")))
			if event.has("dialogue_lines"):
				_show_dialogue_overlay(event.get("dialogue_lines", []))
		"message":
			_update_status(str(event.get("message", "")))


func _has_attack_targets(unit: UnitState) -> bool:
	return not _valid_attack_tiles(unit).is_empty()


func _has_heal_targets(unit: UnitState) -> bool:
	return not _valid_heal_tiles(unit).is_empty()


func _has_usable_items(unit: UnitState) -> bool:
	return _item_service.can_use_any_item(unit)


func _can_visit_village(unit: UnitState) -> bool:
	return unit != null and unit.faction == "player" and _get_terrain_id_at(unit.position) == "village"


func _valid_attack_tiles(unit: UnitState) -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	for target in _units:
		if _combat_resolver.can_unit_attack_from_tile(unit, target, unit.position):
			tiles.append(target.position)
	return tiles


func _valid_heal_tiles(unit: UnitState) -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	for target in _units:
		if _combat_resolver.can_unit_heal_from_tile(unit, target, unit.position):
			tiles.append(target.position)
	return tiles


func _check_end_conditions() -> bool:
	if _objective_controller.check_defeat(_units):
		chapter_failed.emit(_build_summary(false))
		return true
	if _objective_controller.check_victory(_units, _chapter):
		for unit in _units:
			if unit.faction == "player" and unit.downed:
				unit.downed = false
				unit.set_current_hp(maxi(1, int(unit.get_max_hp() / 2)))
		chapter_cleared.emit(_build_summary(true))
		return true
	return false


func _build_summary(success: bool) -> Dictionary:
	var survivors: PackedStringArray = PackedStringArray()
	var player_states: Dictionary = {}
	for unit in _units:
		if unit.faction != "player":
			continue
		player_states[unit.unit_id] = unit.to_persistent_state()
		if unit.is_alive():
			survivors.append(unit.display_name)
	return {
		"success": success,
		"chapter_id": _chapter.id,
		"chapter_name": _chapter.display_name,
		"turns": _turn_controller.turn_number,
		"objective": "Defeat Boss",
		"survivors": survivors,
		"player_states": player_states,
		"next_chapter_id": _chapter.next_chapter_id if _chapter else "",
	}


func _all_player_units_acted() -> bool:
	for unit in _units:
		if unit.faction == "player" and unit.is_alive() and not unit.acted:
			return false
	return true


func _build_occupied_lookup(excluded: UnitState = null) -> Dictionary:
	var occupied: Dictionary = {}
	for unit in _units:
		if unit == excluded or not unit.is_alive():
			continue
		occupied[unit.position] = unit
	return occupied


func _get_unit_at(tile: Vector2i) -> UnitState:
	for unit in _units:
		if unit.position == tile and unit.is_alive() and unit.has_joined:
			return unit
	return null


func _get_terrain_at(tile: Vector2i) -> TerrainData:
	return DataRegistry.get_terrain_data(_get_terrain_id_at(tile))


func _get_terrain_id_at(tile: Vector2i) -> String:
	if _terrain_grid.is_empty():
		return "plains"
	var row_index := clampi(tile.y, 0, _terrain_grid.size() - 1)
	var row: Array = _terrain_grid[row_index]
	if row.is_empty():
		return "plains"
	var column_index := clampi(tile.x, 0, row.size() - 1)
	return str(row[column_index])


func _screen_to_tile(screen_position: Vector2) -> Vector2i:
	var local := screen_position - _board_origin
	return Vector2i(floori(local.x / _cell_size), floori(local.y / _cell_size))


func _update_movement_preview() -> void:
	if _selection.mode != SelectionController.Mode.UNIT_SELECTED:
		return
	if _selection.selected_unit == null or _selection.reachability.is_empty():
		_selection.preview_path.clear()
		return
	if not _selection.highlighted_tiles.has(_cursor_tile) or _cursor_tile == _selection.origin_tile:
		_selection.preview_path.clear()
		return
	_selection.preview_path = _pathfinding.build_path(_selection.origin_tile, _cursor_tile, _selection.reachability)


func _update_header() -> void:
	_chapter_label.text = _chapter.display_name
	_turn_label.text = "Turn %d" % _turn_controller.turn_number
	_phase_label.text = "Player Phase" if _turn_controller.phase == "player" else "Enemy Phase"
	_objective_label.text = "Defeat Boss"


func _update_hint() -> void:
	var danger_zone_state: String = "off"
	if _danger_zone_visible:
		danger_zone_state = "on"
	_hint_label.text = "Enter/Space confirm, Esc cancel, V danger zone %s, P system menu, select a unit for attack range, T end turn." % [danger_zone_state]


func _toggle_danger_zone() -> void:
	_danger_zone_visible = not _danger_zone_visible
	_refresh_danger_zone()
	_update_hint()
	queue_redraw()


func _refresh_danger_zone() -> void:
	if not _danger_zone_visible:
		_danger_zone_tiles.clear()
		return
	_danger_zone_tiles = _danger_zone_service.build_enemy_threat_tiles(_units, _terrain_grid)


func _build_player_attack_preview_tiles() -> Dictionary:
	var preview_tiles: Dictionary = {}
	if _selection.mode != SelectionController.Mode.UNIT_SELECTED:
		return preview_tiles
	if _selection.selected_unit == null or _selection.reachability.is_empty():
		return preview_tiles
	var weapon: WeaponData = DataRegistry.get_weapon_data(_selection.selected_unit.get_equipped_weapon_id())
	if weapon == null or weapon.weapon_type == "staff" or _selection.selected_unit.get_equipped_weapon_uses() <= 0:
		return preview_tiles
	return _danger_zone_service.build_attack_tiles_from_reachability(
		_selection.reachability,
		weapon,
		_grid_size,
		_selection.highlighted_tiles
	)


func _update_status(message: String) -> void:
	_status_label.text = message


func _update_hover_status() -> void:
	var unit := _get_unit_at(_cursor_tile)
	if unit != null:
		_show_hover_portrait(unit)
	elif _selection.selected_unit != null:
		_show_hover_portrait(_selection.selected_unit)
	else:
		_hide_hover_portrait()
	if _selection.mode == SelectionController.Mode.TARGETING and _selection.selected_unit != null and unit != null:
		if _selection.pending_action == "attack" and unit.faction != _selection.selected_unit.faction:
			var forecast := _combat_resolver.build_forecast(_selection.selected_unit, unit, _get_terrain_at(_selection.selected_unit.position), _get_terrain_at(unit.position))
			_forecast_panel.show_battle_forecast(_selection.selected_unit, unit, forecast, _get_terrain_at(unit.position))
			return
		if _selection.pending_action == "staff" and unit.faction == _selection.selected_unit.faction:
			var weapon: WeaponData = DataRegistry.get_weapon_data(_selection.selected_unit.get_equipped_weapon_id())
			if weapon == null:
				_forecast_panel.hide_panel()
				return
			var amount: int = int(weapon.heal_power) + int(_selection.selected_unit.stats.get("mag", 0))
			_forecast_panel.show_heal_preview(_selection.selected_unit, unit, amount)
			return
	_forecast_panel.hide_panel()
	if unit != null:
		_status_label.text = "%s Lv.%d HP %d/%d" % [unit.display_name, unit.level, unit.get_current_hp(), unit.get_max_hp()]


func _unit_color(unit: UnitState) -> Color:
	if unit.faction == "player":
		return Color(0.286275, 0.486275, 0.768627, 1)
	return Color(0.733333, 0.286275, 0.239216, 1)


func _show_hover_portrait(unit: UnitState) -> void:
	_portrait_panel.visible = true
	_portrait_name.text = unit.display_name
	_portrait_details.text = "%s  Lv.%d  HP %d/%d\n%s\n%s" % [
		DataRegistry.get_class_data(unit.class_id).display_name if DataRegistry.get_class_data(unit.class_id) != null else unit.class_id.capitalize(),
		unit.level,
		unit.get_current_hp(),
		unit.get_max_hp(),
		_format_unit_weapon_status(unit),
		_format_unit_potion_status(unit),
	]
	var warning_text: String = _build_unit_break_warning(unit)
	_portrait_warning.text = warning_text
	_portrait_warning.visible = not warning_text.is_empty()
	var portrait := _load_portrait_for_unit(unit)
	_portrait_texture.texture = portrait
	_portrait_texture.visible = portrait != null
	_portrait_fallback.visible = portrait == null
	_portrait_fallback.text = unit.display_name.to_upper()
	_portrait_frame.color = Color(0.121569, 0.14902, 0.184314, 1) if portrait != null else _unit_color(unit)


func _hide_hover_portrait() -> void:
	_portrait_panel.visible = false
	_portrait_texture.texture = null
	_portrait_warning.visible = false


func _format_unit_weapon_status(unit: UnitState) -> String:
	var weapon: WeaponData = DataRegistry.get_weapon_data(unit.get_equipped_weapon_id())
	if weapon == null:
		return "Weapon: Broken"
	return "Weapon: %s  %d/%d" % [weapon.name, unit.get_equipped_weapon_uses(), int(weapon.uses)]


func _format_unit_potion_status(unit: UnitState) -> String:
	var potion_index: int = unit.find_item_index("health_potion")
	if potion_index == -1 or unit.get_item_uses_at(potion_index) <= 0:
		return "Potion: Used"
	return "Potion: Ready"


func _build_unit_break_warning(unit: UnitState) -> String:
	var weapon: WeaponData = DataRegistry.get_weapon_data(unit.get_equipped_weapon_id())
	if weapon == null or unit.get_equipped_weapon_uses() != 1:
		return ""
	return "%s breaks on next use." % weapon.name


func _load_portrait_for_unit(unit: UnitState) -> Texture2D:
	if unit == null:
		return null
	if not unit.portrait_id.is_empty():
		var portrait := _load_portrait_by_id(unit.portrait_id)
		if portrait != null:
			return portrait
	return _load_portrait_by_id(unit.unit_id)


func _load_portrait_by_id(portrait_id: String) -> Texture2D:
	if portrait_id.is_empty():
		return null
	var path := _resolve_portrait_path(portrait_id)
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


func _resolve_portrait_path(portrait_id: String) -> String:
	var exact_path: String = "%s/%s.png" % [PORTRAIT_DIR, portrait_id]
	if ResourceLoader.exists(exact_path):
		return exact_path
	var portrait_key: String = portrait_id.to_lower()
	for file_name in DirAccess.get_files_at(PORTRAIT_DIR):
		if file_name.get_extension().to_lower() != "png":
			continue
		if file_name.get_basename().to_lower() == portrait_key:
			return "%s/%s" % [PORTRAIT_DIR, file_name]
	return exact_path


func _load_map_unit_texture_for_unit(unit: UnitState) -> Texture2D:
	if unit == null:
		return null
	var candidates: PackedStringArray = PackedStringArray()
	for candidate in [
		unit.portrait_id,
		unit.portrait_id.to_lower(),
		unit.unit_id,
		unit.display_name.to_lower().replace(" ", "_"),
		str(MAP_UNIT_CLASS_FALLBACKS.get(unit.class_id, "")),
	]:
		if not candidate.is_empty() and not candidates.has(candidate):
			candidates.append(candidate)
	for candidate in candidates:
		var texture: Texture2D = _load_map_unit_texture_by_id(candidate)
		if texture != null:
			return texture
	return null


func _load_map_unit_texture_by_id(texture_id: String) -> Texture2D:
	if texture_id.is_empty():
		return null
	if _map_unit_texture_cache.has(texture_id):
		var cached_texture: Texture2D = _map_unit_texture_cache[texture_id] as Texture2D
		return cached_texture
	var texture: Texture2D = null
	for path in [
		"%s/%s_map_sprite.png" % [MAP_UNIT_TEXTURE_DIR, texture_id],
		"%s/%s_sprite.png" % [MAP_UNIT_TEXTURE_DIR, texture_id],
	]:
		if ResourceLoader.exists(path):
			texture = load(path) as Texture2D
			break
	_map_unit_texture_cache[texture_id] = texture
	return texture


func _vector2i_from_variant(value: Variant) -> Vector2i:
	if value is Vector2i:
		return value
	if typeof(value) == TYPE_DICTIONARY:
		var dictionary: Dictionary = value
		return Vector2i(int(dictionary.get("x", 0)), int(dictionary.get("y", 0)))
	return Vector2i.ZERO


func _variant_to_packed_string_array(value: Variant) -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	if value is PackedStringArray:
		for entry in value:
			result.append(str(entry))
	elif value is Array:
		for entry in value:
			result.append(str(entry))
	return result


func _packed_string_array_to_array(values: PackedStringArray) -> Array[String]:
	var result: Array[String] = []
	for entry in values:
		result.append(str(entry))
	return result
