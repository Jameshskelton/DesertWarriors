extends Control

signal request_dialogue(lines: Array, next_tag: String)
signal chapter_cleared(summary: Dictionary)
signal chapter_failed(summary: Dictionary)
signal suspend_requested
signal restart_requested(chapter_id: String)

const BATTLE_SCENE := preload("res://scenes/battle/battle_scene.tscn")
const DIALOGUE_SCENE := preload("res://scenes/dialogue/dialogue_scene.tscn")
const LEVEL_UP_SCENE := preload("res://scenes/level_up/level_up_scene.tscn")
const CASTLE_TEXTURE := preload("res://assets/terrain/castle.png")
const COBBLESTONE_TEXTURE := preload("res://assets/terrain/cobblestone.png")
const GRASSLAND_TEXTURE := preload("res://assets/terrain/grassland.png")
const MOUNTAIN_TEXTURE := preload("res://assets/terrain/mountain.png")
const RIVER_TEXTURE := preload("res://assets/terrain/river.png")
const ROAD_TEXTURE := preload("res://assets/terrain/road.png")
const STORE_TEXTURE := preload("res://assets/terrain/store.png")
const TALL_MOUNTAIN_TEXTURE := preload("res://assets/terrain/tall_mountain.png")
const THICKET_TEXTURE := preload("res://assets/terrain/thicket.png")
const VILLAGE_TEXTURE := preload("res://assets/terrain/village.png")
const PORTRAIT_DIR := "res://assets/portraits"
const UI_FONT := preload("res://font/new_font.ttf")
const UI_SCALE := 1.5
const MAP_UNIT_TEXTURE_DIR := "res://assets/map_units"
const MAP_UNIT_SPRITE_SCALE := 1.5
const MAP_UNIT_ANIMATION_INTERVAL := 0.5
const ENEMY_PATH_PREVIEW_PAUSE := 0.4
const ENEMY_PATH_STEP_PAUSE := 0.12
const MOVEMENT_PATH_COLOR := Color(0.462745, 0.815686, 0.960784, 0.72)
const MOVEMENT_PATH_SHADOW := Color(0.0392157, 0.0745098, 0.121569, 0.28)
const ENEMY_MOVEMENT_PATH_COLOR := Color(0.980392, 0.682353, 0.368627, 0.76)
const ENEMY_MOVEMENT_PATH_SHADOW := Color(0.160784, 0.0745098, 0.0470588, 0.34)
const DANGER_ZONE_BASE_COLOR := Color(0.839216, 0.215686, 0.176471, 0.16)
const DANGER_ZONE_INTENSE_COLOR := Color(0.960784, 0.333333, 0.27451, 0.28)
const BOSS_DANGER_FILL_COLOR := Color(0.890196, 0.227451, 0.176471, 0.22)
const BOSS_DANGER_OUTLINE_COLOR := Color(1.0, 0.843137, 0.470588, 0.94)
const PLAYER_ATTACK_RANGE_COLOR := Color(0.980392, 0.647059, 0.196078, 0.26)
const HOVER_ENEMY_THREAT_COLOR := Color(1.0, 0.509804, 0.258824, 0.34)
const BOSS_HOVER_THREAT_COLOR := Color(1.0, 0.415686, 0.211765, 0.4)
const HOVER_ENEMY_TARGET_FILL := Color(1.0, 0.866667, 0.364706, 0.24)
const HOVER_ENEMY_TARGET_OUTLINE := Color(1.0, 0.937255, 0.729412, 0.96)
const MAP_HEAL_POPUP_COLOR := Color(0.552941, 0.941176, 0.682353, 1.0)
const MAP_BREAK_POPUP_COLOR := Color(1.0, 0.764706, 0.423529, 1.0)
const SHOP_POTION_ITEM_ID := "health_potion"
const SHOP_POTION_PRICE := 10
const SHOP_UPGRADE_PRICE := 40
const SHOP_UPGRADE_WEAPONS := {
	"sword": "steel_sword",
	"lance": "steel_lance",
	"bow": "steel_bow",
	"tome": "flare_tome",
	"staff": "mend_staff",
}
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
var _pending_battle_result: BattleResult
var _map_unit_texture_cache: Dictionary = {}
var _map_unit_animation_elapsed: float = 0.0
var _map_unit_animation_frame: int = 0
var _enemy_preview_path: Array[Vector2i] = []
var _spawned_reinforcements: PackedStringArray = PackedStringArray()
var _danger_zone_visible: bool = false
var _danger_zone_tiles: Dictionary = {}
var _boss_danger_tiles: Dictionary = {}
var _hover_enemy_threat_tiles: Dictionary = {}
var _hover_enemy_target_tiles: Dictionary = {}
var _hover_enemy_target_names: PackedStringArray = PackedStringArray()
var _hover_enemy_is_boss: bool = false
var _hover_combat_preview: Dictionary = {}
var _chapter_xp_gains: Dictionary = {}
var _chapter_gold_earned: int = 0
var _chapter_gold_sources: PackedStringArray = PackedStringArray()
var _chapter_recruits: PackedStringArray = PackedStringArray()
var _chapter_weapon_breaks: PackedStringArray = PackedStringArray()
var _chapter_used_items: PackedStringArray = PackedStringArray()
var _pending_level_up_reports: Array[Dictionary] = []
var _active_level_up: Control
var _shop_customer: UnitState
var _shop_preview_item: String = "upgrade"
var _inspected_unit: UnitState

@onready var _chapter_label: Label = $Header/HeaderMargin/HeaderRow/ChapterLabel
@onready var _turn_label: Label = $Header/HeaderMargin/HeaderRow/TurnLabel
@onready var _phase_label: Label = $Header/HeaderMargin/HeaderRow/PhaseLabel
@onready var _objective_label: Label = $Header/HeaderMargin/HeaderRow/ObjectiveLabel
@onready var _gold_label: Label = $Header/HeaderMargin/HeaderRow/GoldLabel
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
@onready var _unit_inspect_panel: PanelContainer = $UnitInspectPanel
@onready var _inspect_name: Label = $UnitInspectPanel/InspectMargin/InspectVBox/Name
@onready var _inspect_portrait_frame: ColorRect = $UnitInspectPanel/InspectMargin/InspectVBox/ContentRow/LeftColumn/PortraitFrame
@onready var _inspect_portrait_texture: TextureRect = $UnitInspectPanel/InspectMargin/InspectVBox/ContentRow/LeftColumn/PortraitFrame/PortraitTexture
@onready var _inspect_portrait_fallback: Label = $UnitInspectPanel/InspectMargin/InspectVBox/ContentRow/LeftColumn/PortraitFrame/PortraitFallback
@onready var _inspect_summary: Label = $UnitInspectPanel/InspectMargin/InspectVBox/ContentRow/LeftColumn/Summary
@onready var _inspect_stats: Label = $UnitInspectPanel/InspectMargin/InspectVBox/ContentRow/RightColumn/Stats
@onready var _inspect_terrain: Label = $UnitInspectPanel/InspectMargin/InspectVBox/ContentRow/RightColumn/Terrain
@onready var _inspect_inventory: Label = $UnitInspectPanel/InspectMargin/InspectVBox/ContentRow/RightColumn/Inventory
@onready var _inspect_close_button: Button = $UnitInspectPanel/InspectMargin/InspectVBox/CloseButton
@onready var _battle_layer: Control = $BattleLayer
@onready var _help_panel = $HelpPanel
@onready var _help_close_button: Button = $HelpPanel/HelpMargin/HelpVBox/CloseButton
@onready var _system_menu: PanelContainer = $SystemMenu
@onready var _system_suspend_button: Button = $SystemMenu/SystemMargin/SystemVBox/SuspendButton
@onready var _system_restart_button: Button = $SystemMenu/SystemMargin/SystemVBox/RestartButton
@onready var _system_close_button: Button = $SystemMenu/SystemMargin/SystemVBox/CloseButton
@onready var _shop_menu: PanelContainer = $ShopMenu
@onready var _shop_title: Label = $ShopMenu/ShopMargin/ShopVBox/Title
@onready var _shop_description: Label = $ShopMenu/ShopMargin/ShopVBox/Description
@onready var _shop_gold_label: Label = $ShopMenu/ShopMargin/ShopVBox/GoldLabel
@onready var _shop_compare_title: Label = $ShopMenu/ShopMargin/ShopVBox/CompareTitle
@onready var _shop_current_label: Label = $ShopMenu/ShopMargin/ShopVBox/CurrentLabel
@onready var _shop_offer_label: Label = $ShopMenu/ShopMargin/ShopVBox/OfferLabel
@onready var _shop_compare_notes: Label = $ShopMenu/ShopMargin/ShopVBox/CompareNotes
@onready var _shop_potion_button: Button = $ShopMenu/ShopMargin/ShopVBox/PotionButton
@onready var _shop_upgrade_button: Button = $ShopMenu/ShopMargin/ShopVBox/UpgradeButton
@onready var _shop_leave_button: Button = $ShopMenu/ShopMargin/ShopVBox/LeaveButton
@onready var _end_turn_confirm: PanelContainer = $EndTurnConfirm
@onready var _end_turn_yes_button: Button = $EndTurnConfirm/ConfirmMargin/ConfirmVBox/ButtonRow/YesButton
@onready var _end_turn_no_button: Button = $EndTurnConfirm/ConfirmMargin/ConfirmVBox/ButtonRow/NoButton


func setup(chapter_id: String) -> void:
	_chapter_id = chapter_id


func _ready() -> void:
	add_child(_battle_transition)
	set_process(true)
	_help_panel.visible = false
	_system_menu.visible = false
	_shop_menu.visible = false
	_end_turn_confirm.visible = false
	_unit_inspect_panel.visible = false
	if _help_close_button != null:
		_help_close_button.pressed.connect(func() -> void:
			_help_panel.visible = false
		)
	_system_suspend_button.pressed.connect(Callable(self, "_on_system_suspend_pressed"))
	_system_restart_button.pressed.connect(Callable(self, "_on_system_restart_pressed"))
	_system_close_button.pressed.connect(Callable(self, "_close_system_menu"))
	_shop_potion_button.pressed.connect(Callable(self, "_on_shop_buy_potion_pressed"))
	_shop_upgrade_button.pressed.connect(Callable(self, "_on_shop_buy_upgrade_pressed"))
	_shop_leave_button.pressed.connect(Callable(self, "_on_shop_leave_pressed"))
	_shop_potion_button.focus_entered.connect(func() -> void:
		_set_shop_preview_item("potion")
	)
	_shop_upgrade_button.focus_entered.connect(func() -> void:
		_set_shop_preview_item("upgrade")
	)
	_end_turn_yes_button.pressed.connect(Callable(self, "_on_end_turn_yes_pressed"))
	_end_turn_no_button.pressed.connect(Callable(self, "_on_end_turn_no_pressed"))
	_inspect_close_button.pressed.connect(Callable(self, "_close_unit_inspection"))
	_battle_transition.battle_overlay_requested.connect(Callable(self, "_show_battle_overlay"))
	_action_menu.action_selected.connect(Callable(self, "_on_action_menu_selected"))
	_load_chapter()
	AudioDirector.play_track("forest_realm")


func _process(delta: float) -> void:
	_map_unit_animation_elapsed += delta
	if _map_unit_animation_elapsed < MAP_UNIT_ANIMATION_INTERVAL:
		return
	_map_unit_animation_elapsed = 0.0
	_map_unit_animation_frame = 1 - _map_unit_animation_frame
	queue_redraw()


func _load_chapter() -> void:
	_chapter = DataRegistry.get_chapter_data(_chapter_id)
	if _chapter == null:
		push_error("Failed to load chapter data: " + _chapter_id)
		return
	_grid_size = Vector2i(_chapter.map_width, _chapter.map_height)
	_terrain_grid = _build_terrain_grid(_chapter)
	_selection.reset()
	_map_unit_animation_elapsed = 0.0
	_map_unit_animation_frame = 0
	_enemy_preview_path.clear()
	_inspected_unit = null
	_unit_inspect_panel.visible = false
	_action_menu.hide_menu()
	_forecast_panel.hide_panel()
	_spawned_reinforcements.clear()
	_units.clear()
	_boss_danger_tiles.clear()
	_hover_enemy_threat_tiles.clear()
	_hover_enemy_target_tiles.clear()
	_hover_enemy_target_names.clear()
	_hover_enemy_is_boss = false
	_hover_combat_preview.clear()
	_pending_level_up_reports.clear()
	_active_level_up = null
	_reset_chapter_summary_tracking()
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
	_restore_chapter_summary_tracking(snapshot)
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
		"chapter_xp_gains": _chapter_xp_gains.duplicate(true),
		"chapter_gold_earned": _chapter_gold_earned,
		"chapter_gold_sources": _packed_string_array_to_array(_chapter_gold_sources),
		"chapter_recruits": _packed_string_array_to_array(_chapter_recruits),
		"chapter_weapon_breaks": _packed_string_array_to_array(_chapter_weapon_breaks),
		"chapter_used_items": _packed_string_array_to_array(_chapter_used_items),
		"units": units,
	}


func _spawn_unit(entry: Dictionary, allow_missing_player_state: bool = false) -> UnitState:
	var unit_id: String = str(entry.get("unit_id", ""))
	var unit_data: UnitData = DataRegistry.get_unit_data(unit_id)
	if unit_data == null:
		return null
	var position = entry.get("position", Vector2i.ZERO)
	var faction_override: String = str(entry.get("faction", ""))
	var state: UnitState = UnitState.from_unit_data(unit_data, position, faction_override)
	var can_fall_back_to_default_state: bool = allow_missing_player_state or not unit_data.join_event_id.is_empty()
	if state.faction == "player" and not GameState.restore_player_unit_state(state, unit_id, can_fall_back_to_default_state):
		return null
	if state.faction == "player":
		state.position = GameState.resolve_preparation_position(_chapter_id, unit_id, state.position)
	if entry.has("instance_id") and state.faction != "player":
		state.unit_id = entry["instance_id"]
	_units.append(state)
	_refresh_danger_zone()
	return state


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
			if terrain_id == "plains" and GRASSLAND_TEXTURE != null:
				draw_texture_rect(GRASSLAND_TEXTURE, rect, false)
			if terrain_id == "castle" and CASTLE_TEXTURE != null:
				draw_texture_rect(CASTLE_TEXTURE, rect, false)
			if terrain_id == "cobblestone" and COBBLESTONE_TEXTURE != null:
				draw_texture_rect(COBBLESTONE_TEXTURE, rect, false)
			if terrain_id == "river" and RIVER_TEXTURE != null:
				draw_texture_rect(RIVER_TEXTURE, rect, false)
			if terrain_id == "road" and ROAD_TEXTURE != null:
				draw_texture_rect(ROAD_TEXTURE, rect, false)
			if terrain_id == "store" and STORE_TEXTURE != null:
				draw_texture_rect(STORE_TEXTURE, rect, false)
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
			if _danger_zone_visible and _boss_danger_tiles.has(tile):
				var boss_threat_count: int = int(_boss_danger_tiles.get(tile, 0))
				var boss_threat_color: Color = BOSS_DANGER_FILL_COLOR
				boss_threat_color.a = clampf(0.18 + float(mini(boss_threat_count, 3)) * 0.06, 0.18, 0.36)
				draw_rect(rect.grow(-7.0), boss_threat_color)
				draw_rect(rect.grow(-4.0), BOSS_DANGER_OUTLINE_COLOR, false, 2.5)
			if _hover_enemy_threat_tiles.has(tile):
				var hover_threat_color: Color = HOVER_ENEMY_THREAT_COLOR
				if _hover_enemy_is_boss:
					hover_threat_color = BOSS_HOVER_THREAT_COLOR
				draw_rect(rect.grow(-7.0), hover_threat_color)
			if _hover_enemy_target_tiles.has(tile):
				var target_outline_color: Color = HOVER_ENEMY_TARGET_OUTLINE
				if _hover_enemy_is_boss:
					target_outline_color = BOSS_DANGER_OUTLINE_COLOR
				draw_rect(rect.grow(-10.0), HOVER_ENEMY_TARGET_FILL)
				draw_rect(rect.grow(-5.0), target_outline_color, false, 4.0)
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
	_draw_preview_path(_enemy_preview_path, ENEMY_MOVEMENT_PATH_SHADOW, ENEMY_MOVEMENT_PATH_COLOR)
	_draw_preview_path(_selection.preview_path, MOVEMENT_PATH_SHADOW, MOVEMENT_PATH_COLOR)


func _draw_preview_path(path: Array[Vector2i], shadow_color: Color, path_color: Color) -> void:
	if path.size() < 2:
		return
	var points := PackedVector2Array()
	for tile in path:
		points.append(_tile_center(tile))
	draw_polyline(points, shadow_color, 13.5 * UI_SCALE, true)
	draw_polyline(points, path_color, 8.0 * UI_SCALE, true)
	for point in points:
		draw_circle(point, 4.0 * UI_SCALE, path_color)
	_draw_movement_arrowhead(points[points.size() - 2], points[points.size() - 1], shadow_color, path_color)


func _draw_movement_arrowhead(from_point: Vector2, to_point: Vector2, shadow_color: Color, path_color: Color) -> void:
	var direction := (to_point - from_point).normalized()
	if direction == Vector2.ZERO:
		return
	var tip := to_point
	var shadow_base := tip - direction * (18.0 * UI_SCALE)
	var shadow_side := direction.orthogonal() * (10.0 * UI_SCALE)
	draw_colored_polygon(
		PackedVector2Array([tip, shadow_base + shadow_side, shadow_base - shadow_side]),
		shadow_color
	)
	var base := tip - direction * (15.0 * UI_SCALE)
	var side := direction.orthogonal() * (8.0 * UI_SCALE)
	draw_colored_polygon(PackedVector2Array([tip, base + side, base - side]), path_color)


func _tile_center(tile: Vector2i) -> Vector2:
	return _board_origin + (Vector2(tile) + Vector2.ONE * 0.5) * _cell_size


func _show_map_popup(tile: Vector2i, text: String, color: Color, vertical_offset: float = 0.0) -> void:
	if text.is_empty():
		return
	var popup := Label.new()
	popup.text = text
	popup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	popup.z_index = 40
	popup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	popup.add_theme_font_size_override("font_size", int(30 * UI_SCALE))
	popup.add_theme_color_override("font_color", color)
	popup.size = Vector2(220.0 * UI_SCALE, 56.0 * UI_SCALE)
	popup.position = _tile_center(tile) - popup.size / 2.0 + Vector2(0.0, -70.0 * UI_SCALE + vertical_offset)
	add_child(popup)
	var start_position: Vector2 = popup.position
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(popup, "position", start_position - Vector2(0.0, 34.0 * UI_SCALE), 0.55)
	tween.tween_property(popup, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.55)
	tween.chain().tween_callback(Callable(popup, "queue_free"))


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
		if unit.faction == "player" and _hover_enemy_target_tiles.has(unit.position):
			var target_outline_color: Color = HOVER_ENEMY_TARGET_OUTLINE
			if _hover_enemy_is_boss:
				target_outline_color = BOSS_DANGER_OUTLINE_COLOR
			draw_rect(visual_rect.grow(-2.0), target_outline_color, false, 4.0)


func _unhandled_input(event: InputEvent) -> void:
	if _active_dialogue != null:
		return
	if event.is_action_pressed("open_system_menu"):
		_toggle_system_menu()
		return
	if event is InputEventKey and event.pressed and (event.keycode == KEY_H or event.keycode == KEY_F1):
		if _system_menu.visible:
			return
		if not _help_panel.visible:
			_close_unit_inspection(false)
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
	if _shop_menu.visible:
		if event.is_action_pressed("ui_cancel"):
			_on_shop_leave_pressed()
		return
	if _end_turn_confirm.visible:
		if event.is_action_pressed("ui_cancel"):
			_close_end_turn_confirm()
		return
	if _unit_inspect_panel.visible:
		if event.is_action_pressed("ui_cancel") or event.is_action_pressed("inspect_unit"):
			_close_unit_inspection()
			return
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var inspect_tile := _screen_to_tile(event.position)
			if _grid.in_bounds(inspect_tile, _grid_size):
				_cursor_tile = inspect_tile
				var inspect_unit := _get_unit_at(inspect_tile)
				if inspect_unit != null:
					_open_unit_inspection(inspect_unit)
				else:
					_close_unit_inspection()
				_update_hover_status()
				queue_redraw()
			return
		return
	if _active_level_up != null:
		return
	if _active_battle != null or _turn_controller.phase != "player":
		return
	if event.is_action_pressed("end_turn"):
		_open_end_turn_confirm()
		return
	if event.is_action_pressed("inspect_unit"):
		_try_open_unit_inspection_under_cursor()
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
			var clicked_unit := _get_unit_at(clicked_tile)
			if _should_open_inspection_on_click(clicked_unit):
				_open_unit_inspection(clicked_unit)
				_update_hover_status()
				queue_redraw()
				return
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
	_close_unit_inspection(false)
	_help_panel.visible = false
	_system_menu.visible = true
	_system_suspend_button.grab_focus()


func _close_system_menu() -> void:
	_system_menu.visible = false


func _open_end_turn_confirm() -> void:
	_close_unit_inspection(false)
	_help_panel.visible = false
	_system_menu.visible = false
	_end_turn_confirm.visible = true
	_end_turn_yes_button.grab_focus()
	_update_status("End your turn and begin the enemy phase?")


func _close_end_turn_confirm() -> void:
	_end_turn_confirm.visible = false
	_update_status("Continue your turn.")


func _can_open_unit_inspection() -> bool:
	return _selection.mode == SelectionController.Mode.IDLE or _selection.mode == SelectionController.Mode.UNIT_SELECTED


func _should_open_inspection_on_click(unit: UnitState) -> bool:
	if unit == null or not _can_open_unit_inspection():
		return false
	if _selection.mode == SelectionController.Mode.IDLE:
		return unit.faction != "player" or unit.moved
	return unit != _selection.selected_unit or unit.position != _selection.origin_tile


func _try_open_unit_inspection_under_cursor() -> void:
	if not _can_open_unit_inspection():
		return
	var unit := _get_unit_at(_cursor_tile)
	if unit == null:
		_update_status("Move the cursor over a unit to inspect them.")
		return
	_open_unit_inspection(unit)


func _open_unit_inspection(unit: UnitState) -> void:
	if unit == null:
		return
	_inspected_unit = unit
	_unit_inspect_panel.visible = true
	_refresh_unit_inspection()
	_inspect_close_button.grab_focus()
	_update_status("Inspecting %s." % unit.display_name)


func _close_unit_inspection(refresh_hover: bool = true) -> void:
	_inspected_unit = null
	_unit_inspect_panel.visible = false
	_inspect_portrait_texture.texture = null
	if refresh_hover:
		_update_hover_status()
		var hovered_unit := _get_unit_at(_cursor_tile)
		if hovered_unit == null:
			if _selection.mode == SelectionController.Mode.UNIT_SELECTED and _selection.selected_unit != null:
				_update_status("%s selected. Choose a destination." % _selection.selected_unit.display_name)
			else:
				_update_status(_build_resume_status())


func _on_end_turn_yes_pressed() -> void:
	_end_turn_confirm.visible = false
	if _selection.mode != SelectionController.Mode.IDLE:
		_cancel_selection()
	_begin_enemy_phase()


func _on_end_turn_no_pressed() -> void:
	_close_end_turn_confirm()


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
	if _can_visit_location(unit):
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
			await _execute_staff(source, target)


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
	_pending_battle_result = payload["result"] as BattleResult
	_selection.mode = SelectionController.Mode.BATTLE
	_forecast_panel.hide_panel()
	_selection.target_tiles.clear()
	_battle_transition.begin_battle(payload)
	await _battle_completed()
	_finish_unit_action()


func _execute_staff(source: UnitState, target: UnitState) -> void:
	var outcome := _combat_resolver.resolve_staff(source, target)
	if outcome.is_empty():
		_update_status("%s cannot use a staff right now." % source.display_name)
		return
	source.consume_turn()
	var heal_amount: int = int(outcome.get("heal_amount", 0))
	_show_map_popup(target.position, "+%d" % heal_amount, MAP_HEAL_POPUP_COLOR)
	_record_chapter_xp(source, int(outcome.get("xp_awarded", 0)))
	_update_status("%s heals %s for %d HP." % [outcome.get("user_name", source.display_name), outcome.get("target_name", target.display_name), heal_amount])
	if bool(outcome.get("weapon_broke", false)):
		_record_weapon_break(str(outcome.get("user_name", source.display_name)), str(outcome.get("weapon_name", "The staff")))
		_show_map_popup(source.position, "BREAK", MAP_BREAK_POPUP_COLOR, -32.0 * UI_SCALE)
		_update_status("%s heals %s for %d HP. %s broke!" % [
			outcome.get("user_name", source.display_name),
			outcome.get("target_name", target.display_name),
			heal_amount,
			outcome.get("weapon_name", "The staff"),
		])
	_queue_level_up_report(_dictionary_or_empty(outcome.get("level_up", {})))
	await _present_queued_level_up_reports()
	_finish_unit_action()


func _execute_item(source: UnitState) -> void:
	var outcome: Dictionary = _item_service.use_first_item(source)
	if outcome.is_empty():
		_update_status("%s has no usable items right now." % source.display_name)
		return
	source.consume_turn()
	var heal_amount: int = int(outcome.get("heal_amount", 0))
	_record_used_item(str(outcome.get("user_name", source.display_name)), str(outcome.get("item_name", "an item")))
	_show_map_popup(source.position, "+%d" % heal_amount, MAP_HEAL_POPUP_COLOR)
	_update_status("%s uses %s and recovers %d HP." % [
		outcome.get("user_name", source.display_name),
		outcome.get("item_name", "an item"),
		heal_amount,
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
	var terrain_id: String = _get_terrain_id_at(source.position)
	source.consume_turn()
	if terrain_id == "store":
		_open_shop_menu(source)
		return
	var visit_events: Array[Dictionary] = _event_director.peek_tile_events(source.unit_id, source.position, _chapter)
	if visit_events.is_empty():
		_update_status("%s visits the village, but it has no further aid to offer." % source.display_name)
	_finish_unit_action(true)


func _open_shop_menu(source: UnitState) -> void:
	_close_unit_inspection(false)
	_action_menu.hide_menu()
	_forecast_panel.hide_panel()
	_help_panel.visible = false
	_system_menu.visible = false
	_end_turn_confirm.visible = false
	_shop_customer = source
	_shop_preview_item = "upgrade"
	if DataRegistry.get_weapon_data(_get_shop_upgrade_weapon_id(source)) == null:
		_shop_preview_item = "potion"
	_shop_menu.visible = true
	_refresh_shop_menu()
	if not _shop_upgrade_button.disabled:
		_shop_upgrade_button.grab_focus()
	else:
		_shop_potion_button.grab_focus()
	_update_status("%s visits the shop." % source.display_name)


func _refresh_shop_menu() -> void:
	var potion_count: int = 0
	var current_weapon_name: String = "--"
	var upgrade_weapon_id: String = _get_shop_upgrade_weapon_id(_shop_customer)
	var upgrade_weapon: WeaponData = DataRegistry.get_weapon_data(upgrade_weapon_id)
	var has_upgrade: bool = _shop_customer != null and not upgrade_weapon_id.is_empty() and _shop_customer.has_item(upgrade_weapon_id)
	if _shop_customer != null:
		potion_count = _shop_customer.get_available_item_count(SHOP_POTION_ITEM_ID)
		var current_weapon: WeaponData = DataRegistry.get_weapon_data(_shop_customer.get_equipped_weapon_id())
		if current_weapon != null:
			current_weapon_name = current_weapon.name
		_shop_title.text = "%s at the Shop" % _shop_customer.display_name
	else:
		_shop_title.text = "Shop"
	_shop_description.text = "Current weapon: %s\nPotion restores 10 HP.\nPotions carried: %d" % [current_weapon_name, potion_count]
	_shop_gold_label.text = "Gold: %d" % GameState.gold
	_shop_potion_button.text = "Potion - %dG" % SHOP_POTION_PRICE
	_shop_potion_button.disabled = _shop_customer == null or GameState.gold < SHOP_POTION_PRICE
	if upgrade_weapon == null:
		_shop_upgrade_button.text = "No Weapon Upgrade"
		_shop_upgrade_button.disabled = true
	else:
		_shop_upgrade_button.text = "%s - %dG" % [upgrade_weapon.name, SHOP_UPGRADE_PRICE]
		if has_upgrade:
			_shop_upgrade_button.text = "%s - Owned" % upgrade_weapon.name
		_shop_upgrade_button.disabled = _shop_customer == null or has_upgrade or GameState.gold < SHOP_UPGRADE_PRICE
	_refresh_shop_compare()


func _close_shop_menu() -> void:
	_shop_menu.visible = false
	_shop_customer = null


func _set_shop_preview_item(item_key: String) -> void:
	if _shop_preview_item == item_key:
		return
	_shop_preview_item = item_key
	if _shop_menu.visible:
		_refresh_shop_compare()


func _refresh_shop_compare() -> void:
	if _shop_customer == null:
		_shop_compare_title.text = "Shop Compare"
		_shop_current_label.text = "Current"
		_shop_offer_label.text = "Offer"
		_shop_compare_notes.text = "Select a customer to compare shop items."
		return
	if _shop_preview_item == "potion":
		_refresh_potion_compare()
		return
	_refresh_upgrade_compare()


func _refresh_potion_compare() -> void:
	var potion_data: ItemData = DataRegistry.get_item_data(SHOP_POTION_ITEM_ID)
	var current_count: int = _shop_customer.get_available_item_count(SHOP_POTION_ITEM_ID)
	var heal_amount: int = 10
	var can_use_now: String = "No"
	if potion_data != null:
		heal_amount = int(potion_data.heal_amount)
	if _shop_customer.get_current_hp() < _shop_customer.get_max_hp():
		can_use_now = "Yes"
	_shop_compare_title.text = "Shop Compare: Potion"
	_shop_current_label.text = "Current Stock\nPotions: %d\nHP: %d/%d" % [
		current_count,
		_shop_customer.get_current_hp(),
		_shop_customer.get_max_hp(),
	]
	_shop_offer_label.text = "For Sale\nPotion\nPrice: %dG\nHeal: %d HP" % [
		SHOP_POTION_PRICE,
		heal_amount,
	]
	_shop_compare_notes.text = "After purchase: %d potions\nCan use now: %s" % [
		current_count + 1,
		can_use_now,
	]


func _refresh_upgrade_compare() -> void:
	var current_weapon: WeaponData = DataRegistry.get_weapon_data(_shop_customer.get_equipped_weapon_id())
	var upgrade_weapon_id: String = _get_shop_upgrade_weapon_id(_shop_customer)
	var upgrade_weapon: WeaponData = DataRegistry.get_weapon_data(upgrade_weapon_id)
	var offer_uses: int = 0
	var can_equip_text: String = "No"
	_shop_compare_title.text = "Shop Compare: Weapon"
	_shop_current_label.text = _format_shop_weapon_block("Current", current_weapon, _shop_customer.get_equipped_weapon_uses())
	if upgrade_weapon != null:
		offer_uses = int(upgrade_weapon.uses)
		if _shop_customer.can_use_weapon(upgrade_weapon):
			can_equip_text = "Yes"
	_shop_offer_label.text = _format_shop_weapon_block("For Sale", upgrade_weapon, offer_uses)
	if upgrade_weapon == null:
		_shop_compare_notes.text = "No matching weapon upgrade is sold for %s." % _shop_customer.display_name
		return
	var ownership_note: String = "Not owned"
	if _shop_customer.has_item(upgrade_weapon_id):
		ownership_note = "Already owned"
	_shop_compare_notes.text = "Delta  %s\nCan Equip: %s\nPrice: %dG\nStatus: %s" % [
		_format_shop_weapon_delta(current_weapon, upgrade_weapon, _shop_customer.get_equipped_weapon_uses()),
		can_equip_text,
		SHOP_UPGRADE_PRICE,
		ownership_note,
	]


func _format_shop_weapon_block(title: String, weapon: WeaponData, current_uses: int) -> String:
	if weapon == null:
		return "%s\nBroken / None" % title
	return "%s\n%s\nMt %d  Hit %d  Crit %d\nRange %s  Uses %d/%d" % [
		title,
		weapon.name,
		weapon.might,
		weapon.hit,
		weapon.crit,
		_format_weapon_range(weapon),
		current_uses,
		int(weapon.uses),
	]


func _format_shop_weapon_delta(current_weapon: WeaponData, upgrade_weapon: WeaponData, current_uses: int) -> String:
	if upgrade_weapon == null:
		return "No upgrade"
	var current_might: int = 0
	var current_hit: int = 0
	var current_crit: int = 0
	var current_range: String = "--"
	if current_weapon != null:
		current_might = current_weapon.might
		current_hit = current_weapon.hit
		current_crit = current_weapon.crit
		current_range = _format_weapon_range(current_weapon)
	return "Mt %s  Hit %s  Crit %s\nRange %s -> %s\nDurability %s current uses" % [
		_format_signed_value(upgrade_weapon.might - current_might),
		_format_signed_value(upgrade_weapon.hit - current_hit),
		_format_signed_value(upgrade_weapon.crit - current_crit),
		current_range,
		_format_weapon_range(upgrade_weapon),
		_format_signed_value(int(upgrade_weapon.uses) - current_uses),
	]


func _on_shop_buy_potion_pressed() -> void:
	if _shop_customer == null:
		return
	if not GameState.spend_gold(SHOP_POTION_PRICE):
		_update_status("Not enough gold to buy a Potion.")
		_refresh_shop_menu()
		return
	_shop_customer.add_item(SHOP_POTION_ITEM_ID)
	_update_header()
	_refresh_shop_menu()
	_update_hover_status()
	_update_status("%s buys a Potion." % _shop_customer.display_name)


func _on_shop_buy_upgrade_pressed() -> void:
	if _shop_customer == null:
		return
	var upgrade_weapon_id: String = _get_shop_upgrade_weapon_id(_shop_customer)
	var upgrade_weapon: WeaponData = DataRegistry.get_weapon_data(upgrade_weapon_id)
	if upgrade_weapon == null:
		_update_status("No weapon upgrade is available for %s here." % _shop_customer.display_name)
		_refresh_shop_menu()
		return
	if _shop_customer.has_item(upgrade_weapon_id):
		_update_status("%s already carries %s." % [_shop_customer.display_name, upgrade_weapon.name])
		_refresh_shop_menu()
		return
	if not GameState.spend_gold(SHOP_UPGRADE_PRICE):
		_update_status("Not enough gold to buy %s." % upgrade_weapon.name)
		_refresh_shop_menu()
		return
	_shop_customer.add_equipped_weapon(upgrade_weapon_id)
	_update_header()
	_refresh_shop_menu()
	_update_hover_status()
	_update_status("%s buys %s." % [_shop_customer.display_name, upgrade_weapon.name])


func _on_shop_leave_pressed() -> void:
	_close_shop_menu()
	_finish_unit_action()


func _show_battle_overlay(payload: Dictionary) -> void:
	var battle_scene: Control = BATTLE_SCENE.instantiate()
	battle_scene.setup(payload)
	battle_scene.battle_finished.connect(Callable(self, "_on_battle_finished"))
	_active_battle = battle_scene
	_battle_layer.add_child(battle_scene)


func _battle_completed() -> void:
	while true:
		if _active_battle == null:
			await _present_queued_level_up_reports()
			return
		if not is_instance_valid(_active_battle):
			_active_battle = null
			_apply_battle_rewards()
			_refresh_danger_zone()
			queue_redraw()
			await _present_queued_level_up_reports()
			return
		if _battle_scene_ready_to_close():
			_on_battle_finished()
			await _present_queued_level_up_reports()
			return
		if _active_battle.is_queued_for_deletion() or not _active_battle.is_inside_tree() or _active_battle.get_parent() == null:
			_on_battle_finished()
			await _present_queued_level_up_reports()
			return
		await get_tree().process_frame


func _on_battle_finished() -> void:
	var battle: Control = _active_battle
	_active_battle = null
	if battle != null and is_instance_valid(battle):
		battle.queue_free()
	AudioDirector.resume_previous_track()
	_apply_battle_rewards()
	_refresh_danger_zone()
	queue_redraw()


func _battle_scene_ready_to_close() -> bool:
	if _active_battle == null or not is_instance_valid(_active_battle):
		return false
	if not _active_battle.has_method("is_sequence_finished"):
		return false
	return bool(_active_battle.call("is_sequence_finished"))


func _apply_battle_rewards() -> void:
	if _pending_battle_result == null:
		return
	var battle_result: BattleResult = _pending_battle_result
	_pending_battle_result = null
	_record_battle_summary(battle_result)
	_queue_level_up_reports(battle_result.level_ups)
	if battle_result.gold_awarded > 0:
		GameState.add_gold(battle_result.gold_awarded)
		_update_header()
		if battle_result.gold_sources.size() == 1:
			_update_status("Earned %d gold from %s." % [battle_result.gold_awarded, battle_result.gold_sources[0]])
		else:
			_update_status("Earned %d gold." % battle_result.gold_awarded)


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
	_close_unit_inspection(false)
	_selection.preview_path.clear()
	_enemy_preview_path.clear()
	_turn_controller.enter_enemy_phase()
	_selection.mode = SelectionController.Mode.ENEMY_PHASE
	_update_header()
	_update_status("Enemy phase...")
	await _run_enemy_phase()
	if _check_end_conditions():
		return
	_turn_controller.enter_player_phase(_units)
	_process_turn_events()
	if _check_end_conditions():
		return
	_selection.reset()
	_enemy_preview_path.clear()
	_update_header()
	_refresh_danger_zone()
	_update_status("Player phase. Press T to end turn if needed.")
	queue_redraw()


func _run_enemy_phase() -> void:
	for unit in _units:
		if unit.faction != "enemy" or not unit.is_alive():
			continue
		var action := _ai_controller.choose_action(unit, _units, _terrain_grid)
		var action_path: Array[Vector2i] = _extract_action_path(action, unit.position)
		match action.get("type", "wait"):
			"move_wait":
				await _preview_enemy_path(unit, action_path)
				await _move_unit_along_path(unit, action_path)
			"move_attack":
				await _preview_enemy_path(unit, action_path)
				await _move_unit_along_path(unit, action_path)
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
					_pending_battle_result = payload["result"] as BattleResult
					_battle_transition.begin_battle(payload)
					await _battle_completed()
		_enemy_preview_path.clear()
		_refresh_danger_zone()
		_update_hover_status()
		queue_redraw()
		if _check_end_conditions():
			return
	_enemy_preview_path.clear()
	queue_redraw()


func _extract_action_path(action: Dictionary, origin: Vector2i) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	var raw_path_value: Variant = action.get("path", [])
	if raw_path_value is Array:
		for tile_value in raw_path_value:
			path.append(_vector2i_from_variant(tile_value))
	if path.is_empty():
		path.append(origin)
	elif path[0] != origin:
		path.push_front(origin)
	return path


func _preview_enemy_path(unit: UnitState, path: Array[Vector2i]) -> void:
	_enemy_preview_path = path.duplicate()
	if _enemy_preview_path.size() < 2:
		return
	_update_status("%s advances." % unit.display_name)
	queue_redraw()
	await get_tree().create_timer(ENEMY_PATH_PREVIEW_PAUSE).timeout


func _move_unit_along_path(unit: UnitState, path: Array[Vector2i]) -> void:
	if unit == null or path.size() < 2:
		return
	for step_index in range(1, path.size()):
		unit.position = path[step_index]
		_refresh_danger_zone()
		_update_hover_status()
		queue_redraw()
		await get_tree().create_timer(ENEMY_PATH_STEP_PAUSE).timeout


func _process_turn_events() -> void:
	for reinforcement in _chapter.reinforcements:
		var reinforcement_id: String = str(reinforcement.get("instance_id", reinforcement.get("unit_id", "")))
		if int(reinforcement.get("turn", -1)) == _turn_controller.turn_number and not _spawned_reinforcements.has(reinforcement_id):
			_spawned_reinforcements.append(reinforcement_id)
			var spawned_unit: UnitState = _spawn_unit(reinforcement, true)
			if spawned_unit != null and spawned_unit.faction == "player":
				_record_recruit(spawned_unit.display_name)
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
	_close_unit_inspection(false)
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
			var spawned_unit: UnitState = _spawn_unit(event.get("spawn", {}), true)
			if spawned_unit != null and spawned_unit.faction == "player":
				_record_recruit(spawned_unit.display_name)
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


func _can_visit_location(unit: UnitState) -> bool:
	if unit == null or unit.faction != "player":
		return false
	var terrain_id: String = _get_terrain_id_at(unit.position)
	return terrain_id == "village" or terrain_id == "store"


func _get_shop_upgrade_weapon_id(unit: UnitState) -> String:
	if unit == null:
		return ""
	var allowed_types: PackedStringArray = unit.get_allowed_weapon_types()
	for weapon_type in allowed_types:
		if SHOP_UPGRADE_WEAPONS.has(weapon_type):
			return str(SHOP_UPGRADE_WEAPONS[weapon_type])
	return ""


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
	if _objective_controller.check_victory(_units, _chapter, _turn_controller.turn_number):
		if not GameState.permadeath_enabled:
			for unit in _units:
				if unit.faction == "player" and unit.downed:
					unit.downed = false
					unit.set_current_hp(maxi(1, int(unit.get_max_hp() / 2)))
		chapter_cleared.emit(_build_summary(true))
		return true
	return false


func _build_summary(success: bool) -> Dictionary:
	var survivors: PackedStringArray = PackedStringArray()
	var fallen: PackedStringArray = PackedStringArray()
	var player_states: Dictionary = {}
	for unit in _units:
		if unit.faction != "player":
			continue
		player_states[unit.unit_id] = unit.to_persistent_state()
		if unit.is_alive():
			survivors.append(unit.display_name)
		else:
			fallen.append(unit.display_name)
	return {
		"success": success,
		"chapter_id": _chapter.id,
		"chapter_name": _chapter.display_name,
		"turns": _turn_controller.turn_number,
		"objective": _objective_controller.get_objective_text(_chapter),
		"survivors": survivors,
		"fallen": fallen,
		"xp_gains": _chapter_xp_gains.duplicate(true),
		"gold_earned": _chapter_gold_earned,
		"gold_sources": _chapter_gold_sources,
		"recruits": _chapter_recruits,
		"weapon_breaks": _chapter_weapon_breaks,
		"used_items": _chapter_used_items,
		"player_states": player_states,
		"next_chapter_id": _chapter.next_chapter_id if _chapter else "",
	}


func _reset_chapter_summary_tracking() -> void:
	_chapter_xp_gains.clear()
	_chapter_gold_earned = 0
	_chapter_gold_sources.clear()
	_chapter_recruits.clear()
	_chapter_weapon_breaks.clear()
	_chapter_used_items.clear()


func _restore_chapter_summary_tracking(snapshot: Dictionary) -> void:
	_chapter_xp_gains = _variant_to_int_dictionary(snapshot.get("chapter_xp_gains", {}))
	_chapter_gold_earned = maxi(0, int(snapshot.get("chapter_gold_earned", 0)))
	_chapter_gold_sources = _variant_to_packed_string_array(snapshot.get("chapter_gold_sources", PackedStringArray()))
	_chapter_recruits = _variant_to_packed_string_array(snapshot.get("chapter_recruits", PackedStringArray()))
	_chapter_weapon_breaks = _variant_to_packed_string_array(snapshot.get("chapter_weapon_breaks", PackedStringArray()))
	_chapter_used_items = _variant_to_packed_string_array(snapshot.get("chapter_used_items", PackedStringArray()))


func _record_battle_summary(battle_result: BattleResult) -> void:
	if battle_result == null:
		return
	_chapter_gold_earned += maxi(0, int(battle_result.gold_awarded))
	for source_name in battle_result.gold_sources:
		_chapter_gold_sources.append(str(source_name))
	for unit_id_value in battle_result.xp_awards.keys():
		var unit_id: String = str(unit_id_value)
		var xp_amount: int = int(battle_result.xp_awards.get(unit_id_value, 0))
		if xp_amount <= 0:
			continue
		var unit: UnitState = _find_unit_by_id(unit_id)
		if unit == null or unit.faction != "player":
			continue
		_record_chapter_xp(unit, xp_amount)
	for strike_value in battle_result.strikes:
		if typeof(strike_value) != TYPE_DICTIONARY:
			continue
		var strike: Dictionary = strike_value
		if bool(strike.get("weapon_broke", false)):
			_record_weapon_break(str(strike.get("attacker_name", "")), str(strike.get("weapon_name", "Weapon")))


func _record_chapter_xp(unit: UnitState, amount: int) -> void:
	if unit == null or unit.faction != "player" or amount <= 0:
		return
	var key: String = unit.display_name
	_chapter_xp_gains[key] = int(_chapter_xp_gains.get(key, 0)) + amount


func _record_recruit(unit_name: String) -> void:
	if unit_name.is_empty() or _chapter_recruits.has(unit_name):
		return
	_chapter_recruits.append(unit_name)


func _record_weapon_break(unit_name: String, weapon_name: String) -> void:
	var formatted_name: String = weapon_name
	if not unit_name.is_empty():
		formatted_name = "%s's %s" % [unit_name, weapon_name]
	_chapter_weapon_breaks.append(formatted_name)


func _record_used_item(unit_name: String, item_name: String) -> void:
	var formatted_name: String = item_name
	if not unit_name.is_empty():
		formatted_name = "%s used %s" % [unit_name, item_name]
	_chapter_used_items.append(formatted_name)


func _queue_level_up_reports(reports: Array) -> void:
	for report_value in reports:
		if typeof(report_value) != TYPE_DICTIONARY:
			continue
		_queue_level_up_report(report_value)


func _queue_level_up_report(report: Dictionary) -> void:
	if report.is_empty():
		return
	_pending_level_up_reports.append(report.duplicate(true))


func _present_queued_level_up_reports() -> void:
	while not _pending_level_up_reports.is_empty():
		if _active_level_up != null:
			while _active_level_up != null:
				await get_tree().process_frame
			continue
		var report: Dictionary = _pending_level_up_reports.pop_front()
		_close_unit_inspection(false)
		_action_menu.hide_menu()
		_forecast_panel.hide_panel()
		_help_panel.visible = false
		_system_menu.visible = false
		_shop_menu.visible = false
		_end_turn_confirm.visible = false
		var level_up_scene: Control = LEVEL_UP_SCENE.instantiate()
		level_up_scene.setup(report)
		level_up_scene.level_up_finished.connect(Callable(self, "_on_level_up_finished"))
		_active_level_up = level_up_scene
		add_child(level_up_scene)
		while _active_level_up != null:
			await get_tree().process_frame


func _on_level_up_finished() -> void:
	if _active_level_up != null:
		_active_level_up.queue_free()
	_active_level_up = null
	queue_redraw()


func _dictionary_or_empty(value: Variant) -> Dictionary:
	if typeof(value) == TYPE_DICTIONARY:
		return (value as Dictionary).duplicate(true)
	return {}


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


func _find_unit_by_id(unit_id: String) -> UnitState:
	if unit_id.is_empty():
		return null
	for unit in _units:
		if unit == null:
			continue
		if unit.unit_id == unit_id or unit.base_unit_id == unit_id:
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
	_objective_label.text = _objective_controller.get_objective_text(_chapter)
	_gold_label.text = "Gold %d" % GameState.gold


func _update_hint() -> void:
	var danger_zone_state: String = "off"
	if _danger_zone_visible:
		danger_zone_state = "on"
	_hint_label.text = "Enter/Space confirm, Esc cancel, I inspect, V danger zone %s, P system menu, select a unit for attack range, T end-turn prompt." % [danger_zone_state]


func _toggle_danger_zone() -> void:
	_danger_zone_visible = not _danger_zone_visible
	_refresh_danger_zone()
	_update_hint()
	queue_redraw()


func _refresh_danger_zone() -> void:
	if not _danger_zone_visible:
		_danger_zone_tiles.clear()
		_boss_danger_tiles.clear()
		return
	_danger_zone_tiles = _danger_zone_service.build_enemy_threat_tiles(_units, _terrain_grid)
	_boss_danger_tiles = {}
	for unit in _units:
		if not _is_boss_unit(unit):
			continue
		var boss_threat_tiles: Dictionary = _danger_zone_service.build_threat_tiles_for_unit(unit, _units, _terrain_grid)
		for tile in boss_threat_tiles.keys():
			_boss_danger_tiles[tile] = int(_boss_danger_tiles.get(tile, 0)) + int(boss_threat_tiles[tile])


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
	_refresh_hover_enemy_readability(_resolve_hover_enemy_focus(unit))
	_hover_combat_preview.clear()
	if _selection.mode == SelectionController.Mode.UNIT_SELECTED and _selection.selected_unit != null and unit != null and unit.faction != _selection.selected_unit.faction:
		_hover_combat_preview = _build_hover_combat_preview(_selection.selected_unit, unit)
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
	if unit != null and not _unit_inspect_panel.visible:
		if unit.faction == "enemy":
			var combat_status: String = _build_hover_combat_status()
			if not combat_status.is_empty():
				_status_label.text = combat_status
			else:
				_status_label.text = _build_enemy_hover_status(unit)
		else:
			_status_label.text = "%s Lv.%d HP %d/%d" % [unit.display_name, unit.level, unit.get_current_hp(), unit.get_max_hp()]


func _unit_color(unit: UnitState) -> Color:
	if unit.faction == "player":
		return Color(0.286275, 0.486275, 0.768627, 1)
	return Color(0.733333, 0.286275, 0.239216, 1)


func _show_hover_portrait(unit: UnitState) -> void:
	_portrait_panel.visible = true
	_portrait_name.text = unit.display_name
	var class_display_name: String = unit.class_id.capitalize()
	var class_data: ClassData = DataRegistry.get_class_data(unit.class_id)
	if class_data != null:
		class_display_name = class_data.display_name
	var detail_lines: Array[String] = []
	detail_lines.append("%s  Lv.%d  HP %d/%d" % [
		class_display_name,
		unit.level,
		unit.get_current_hp(),
		unit.get_max_hp(),
	])
	if _is_boss_unit(unit):
		var boss_title: String = _get_unit_boss_title(unit)
		if boss_title.is_empty():
			detail_lines.append("Boss")
		else:
			detail_lines.append("Boss: %s" % boss_title)
	detail_lines.append(_format_unit_weapon_status(unit))
	detail_lines.append(_format_unit_potion_status(unit))
	if unit.faction == "enemy":
		for line in _build_hover_combat_detail_lines():
			detail_lines.append(line)
		detail_lines.append("Threatens: %d tiles" % _hover_enemy_threat_tiles.size())
		detail_lines.append(_build_enemy_target_summary())
	_portrait_details.text = "\n".join(detail_lines)
	var warning_text: String = _build_unit_break_warning(unit)
	_portrait_warning.text = warning_text
	_portrait_warning.visible = not warning_text.is_empty()
	var portrait := _load_portrait_for_unit(unit)
	_portrait_texture.texture = portrait
	_portrait_texture.visible = portrait != null
	_portrait_fallback.visible = portrait == null
	_portrait_fallback.text = unit.display_name.to_upper()
	_portrait_frame.color = _unit_color(unit)
	if portrait != null:
		_portrait_frame.color = Color(0.121569, 0.14902, 0.184314, 1)


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
	var potion_count: int = unit.get_available_item_count("health_potion")
	if potion_count <= 0:
		return "Potions: 0"
	if potion_count == 1:
		return "Potion: 1"
	return "Potions: %d" % potion_count


func _build_unit_break_warning(unit: UnitState) -> String:
	var weapon: WeaponData = DataRegistry.get_weapon_data(unit.get_equipped_weapon_id())
	if weapon == null or unit.get_equipped_weapon_uses() != 1:
		return ""
	return "%s breaks on next use." % weapon.name


func _resolve_hover_enemy_focus(hovered_unit: UnitState) -> UnitState:
	if hovered_unit != null and hovered_unit.faction == "enemy":
		return hovered_unit
	if _unit_inspect_panel.visible and _inspected_unit != null and _inspected_unit.faction == "enemy":
		return _inspected_unit
	return null


func _refresh_hover_enemy_readability(enemy_unit: UnitState) -> void:
	_hover_enemy_threat_tiles.clear()
	_hover_enemy_target_tiles.clear()
	_hover_enemy_target_names.clear()
	_hover_enemy_is_boss = false
	if enemy_unit == null:
		queue_redraw()
		return
	_hover_enemy_is_boss = _is_boss_unit(enemy_unit)
	_hover_enemy_threat_tiles = _danger_zone_service.build_threat_tiles_for_unit(enemy_unit, _units, _terrain_grid)
	for unit in _units:
		if unit == null or unit.faction != "player" or not unit.is_alive() or not unit.has_joined:
			continue
		if _hover_enemy_threat_tiles.has(unit.position):
			_hover_enemy_target_tiles[unit.position] = true
			_hover_enemy_target_names.append(unit.display_name)
	queue_redraw()


func _build_enemy_hover_status(unit: UnitState) -> String:
	var display_name: String = unit.display_name
	var boss_title: String = _get_unit_boss_title(unit)
	if _is_boss_unit(unit) and not boss_title.is_empty():
		display_name = "%s (%s)" % [display_name, boss_title]
	return "%s Lv.%d HP %d/%d | %s" % [
		display_name,
		unit.level,
		unit.get_current_hp(),
		unit.get_max_hp(),
		_build_enemy_target_summary(),
	]


func _build_enemy_target_summary() -> String:
	if _hover_enemy_target_names.is_empty():
		return "Can target: nobody"
	return "Can target: %s" % ", ".join(_packed_string_array_to_array(_hover_enemy_target_names))


func _build_hover_combat_preview(attacker: UnitState, defender: UnitState) -> Dictionary:
	var attacker_name: String = ""
	if attacker != null:
		attacker_name = attacker.display_name
	var defender_name: String = ""
	if defender != null:
		defender_name = defender.display_name
	var preview := {
		"attacker_name": attacker_name,
		"defender_name": defender_name,
		"can_attack": false,
	}
	if attacker == null or defender == null or attacker.faction == defender.faction:
		return preview
	if _selection.reachability.is_empty():
		return preview
	var attacker_weapon: WeaponData = DataRegistry.get_weapon_data(attacker.get_equipped_weapon_id())
	if attacker_weapon == null or attacker_weapon.weapon_type == "staff" or attacker.get_equipped_weapon_uses() <= 0:
		return preview
	var defender_terrain: TerrainData = _get_terrain_at(defender.position)
	var best_preview: Dictionary = {}
	for tile_value in _selection.reachability.get("costs", {}).keys():
		var attacker_tile: Vector2i = _vector2i_from_variant(tile_value)
		if not _combat_resolver.can_unit_attack_from_tile(attacker, defender, attacker_tile):
			continue
		var attacker_terrain: TerrainData = _get_terrain_at(attacker_tile)
		var forecast: CombatForecast = _combat_resolver.build_forecast_for_tile(attacker, defender, attacker_tile, attacker_terrain, defender_terrain)
		var attack_swings: int = 1 + int(forecast.attacker_follow_up)
		var counter_swings: int = 0
		if forecast.counter_allowed:
			counter_swings = 1 + int(forecast.defender_follow_up)
		var score: int = forecast.attacker_damage * attack_swings * 1000
		score += forecast.attacker_hit * 10
		score += forecast.attacker_crit
		score -= forecast.defender_damage * counter_swings * 150
		score -= forecast.defender_hit
		if not forecast.counter_allowed:
			score += 400
		score -= int(_selection.highlighted_tiles.get(attacker_tile, 0))
		if best_preview.is_empty() or score > int(best_preview.get("score", -999999)):
			best_preview = {
				"attacker_name": attacker.display_name,
				"defender_name": defender.display_name,
				"can_attack": true,
				"tile": attacker_tile,
				"forecast": forecast,
				"score": score,
			}
	if best_preview.is_empty():
		return preview
	return best_preview


func _build_hover_combat_detail_lines() -> Array[String]:
	var lines: Array[String] = []
	if _hover_combat_preview.is_empty():
		return lines
	var attacker_name: String = str(_hover_combat_preview.get("attacker_name", ""))
	if not bool(_hover_combat_preview.get("can_attack", false)):
		if not attacker_name.is_empty():
			lines.append("%s: Out of range" % attacker_name)
		return lines
	var forecast: CombatForecast = _hover_combat_preview.get("forecast") as CombatForecast
	if forecast == null:
		return lines
	var attack_swings: int = 1 + int(forecast.attacker_follow_up)
	lines.append("%s: %d x%d  HIT %d  CRT %d" % [
		attacker_name,
		forecast.attacker_damage,
		attack_swings,
		forecast.attacker_hit,
		forecast.attacker_crit,
	])
	if forecast.counter_allowed:
		var counter_swings: int = 1 + int(forecast.defender_follow_up)
		lines.append("Counter: %d x%d  HIT %d  CRT %d" % [
			forecast.defender_damage,
			counter_swings,
			forecast.defender_hit,
			forecast.defender_crit,
		])
	else:
		lines.append("Counter: none")
	return lines


func _build_hover_combat_status() -> String:
	if _hover_combat_preview.is_empty():
		return ""
	var attacker_name: String = str(_hover_combat_preview.get("attacker_name", ""))
	var defender_name: String = str(_hover_combat_preview.get("defender_name", ""))
	if not bool(_hover_combat_preview.get("can_attack", false)):
		return "%s cannot attack %s from current move range." % [attacker_name, defender_name]
	var forecast: CombatForecast = _hover_combat_preview.get("forecast") as CombatForecast
	if forecast == null:
		return ""
	var attack_swings: int = 1 + int(forecast.attacker_follow_up)
	var attack_summary: String = "%s -> %s: %dx%d @%d crt %d" % [
		attacker_name,
		defender_name,
		forecast.attacker_damage,
		attack_swings,
		forecast.attacker_hit,
		forecast.attacker_crit,
	]
	if not forecast.counter_allowed:
		return "%s | counter none" % attack_summary
	var counter_swings: int = 1 + int(forecast.defender_follow_up)
	return "%s | counter %dx%d @%d" % [
		attack_summary,
		forecast.defender_damage,
		counter_swings,
		forecast.defender_hit,
	]


func _is_boss_unit(unit: UnitState) -> bool:
	return unit != null and unit.has_flag("boss")


func _get_unit_boss_title(unit: UnitState) -> String:
	var unit_data: UnitData = _get_unit_data(unit)
	if unit_data == null:
		return ""
	return unit_data.boss_title


func _get_unit_data(unit: UnitState) -> UnitData:
	if unit == null:
		return null
	var candidate_ids := PackedStringArray()
	if not unit.base_unit_id.is_empty():
		candidate_ids.append(unit.base_unit_id)
	if not unit.unit_id.is_empty() and not candidate_ids.has(unit.unit_id):
		candidate_ids.append(unit.unit_id)
	for candidate_id in candidate_ids:
		var unit_data: UnitData = DataRegistry.get_unit_data(candidate_id)
		if unit_data != null:
			return unit_data
	return null


func _refresh_unit_inspection() -> void:
	if _inspected_unit == null:
		_close_unit_inspection(false)
		return
	var unit: UnitState = _inspected_unit
	_inspect_name.text = "%s  Lv.%d" % [unit.display_name, unit.level]
	_inspect_summary.text = _format_inspection_summary(unit)
	_inspect_stats.text = _format_inspection_stats(unit)
	_inspect_terrain.text = _format_inspection_terrain(unit)
	_inspect_inventory.text = _format_inspection_inventory(unit)
	var portrait := _load_portrait_for_unit(unit)
	_inspect_portrait_texture.texture = portrait
	_inspect_portrait_texture.visible = portrait != null
	_inspect_portrait_fallback.visible = portrait == null
	_inspect_portrait_fallback.text = unit.display_name.to_upper()
	_inspect_portrait_frame.color = _unit_color(unit)
	if portrait != null:
		_inspect_portrait_frame.color = Color(0.121569, 0.14902, 0.184314, 1)


func _format_inspection_summary(unit: UnitState) -> String:
	var class_data: ClassData = DataRegistry.get_class_data(unit.class_id)
	var unit_class_name: String = unit.class_id.capitalize()
	var move_range: int = 0
	var move_type: String = "--"
	if class_data != null:
		unit_class_name = class_data.display_name
		move_range = class_data.move_range
		move_type = class_data.move_type.capitalize()
	var faction_name: String = unit.faction.capitalize()
	var weapon: WeaponData = DataRegistry.get_weapon_data(unit.get_equipped_weapon_id())
	var weapon_line: String = "Weapon: Broken"
	var weapon_range: String = "--"
	if weapon != null:
		weapon_line = "Weapon: %s (%d/%d)" % [weapon.name, unit.get_equipped_weapon_uses(), int(weapon.uses)]
		weapon_range = _format_weapon_range(weapon)
	return "Faction: %s\nClass: %s\nMove: %d (%s)\nWeapon Range: %s\n%s" % [
		faction_name,
		unit_class_name,
		move_range,
		move_type,
		weapon_range,
		weapon_line,
	]


func _format_inspection_stats(unit: UnitState) -> String:
	return "HP: %d / %d\nSTR: %d    MAG: %d\nSKL: %d    SPD: %d\nLCK: %d    DEF: %d\nRES: %d    XP: %d" % [
		unit.get_current_hp(),
		unit.get_max_hp(),
		int(unit.stats.get("str", 0)),
		int(unit.stats.get("mag", 0)),
		int(unit.stats.get("skl", 0)),
		int(unit.stats.get("spd", 0)),
		int(unit.stats.get("lck", 0)),
		int(unit.stats.get("def", 0)),
		int(unit.stats.get("res", 0)),
		unit.xp,
	]


func _format_inspection_terrain(unit: UnitState) -> String:
	var terrain: TerrainData = _get_terrain_at(unit.position)
	if terrain == null:
		return "Unknown terrain"
	var class_data: ClassData = DataRegistry.get_class_data(unit.class_id)
	var move_cost_text: String = "--"
	var def_bonus_text: String = _format_signed_value(int(terrain.def_bonus))
	var avoid_bonus_text: String = _format_signed_value(int(terrain.avoid_bonus))
	if class_data != null:
		var move_cost: int = int(terrain.move_cost_by_type.get(class_data.move_type, 99))
		move_cost_text = str(move_cost)
		if terrain.is_blocking:
			move_cost_text = "Blocked"
	return "%s at (%d, %d)\nDEF Bonus: %s\nAvoid Bonus: %s\nMove Cost: %s" % [
		terrain.name,
		unit.position.x,
		unit.position.y,
		def_bonus_text,
		avoid_bonus_text,
		move_cost_text,
	]


func _format_inspection_inventory(unit: UnitState) -> String:
	if unit.inventory.is_empty():
		return "--"
	var equipped_index: int = unit.get_equipped_weapon_index()
	var lines: Array[String] = []
	for item_index in range(unit.inventory.size()):
		var item_id: String = str(unit.inventory[item_index])
		var prefix: String = ""
		if item_index == equipped_index:
			prefix = "[E] "
		var weapon: WeaponData = DataRegistry.get_weapon_data(item_id)
		if weapon != null:
			lines.append("%s%s (%d/%d uses, %s range)" % [
				prefix,
				weapon.name,
				unit.get_item_uses_at(item_index),
				int(weapon.uses),
				_format_weapon_range(weapon),
			])
			continue
		var item: ItemData = DataRegistry.get_item_data(item_id)
		if item != null:
			lines.append("%s%s (%d/%d uses)" % [
				prefix,
				item.name,
				unit.get_item_uses_at(item_index),
				int(item.uses),
			])
			continue
		lines.append("%s%s (%d uses)" % [prefix, item_id.capitalize(), unit.get_item_uses_at(item_index)])
	return "\n".join(lines)


func _format_weapon_range(weapon: WeaponData) -> String:
	if weapon == null:
		return "--"
	if weapon.min_range == weapon.max_range:
		return str(weapon.min_range)
	return "%d-%d" % [weapon.min_range, weapon.max_range]


func _format_signed_value(value: int) -> String:
	if value >= 0:
		return "+%d" % value
	return str(value)


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
		var texture: Texture2D = _load_map_unit_texture_by_id(candidate, _map_unit_animation_frame)
		if texture != null:
			return texture
	return null


func _load_map_unit_texture_by_id(texture_id: String, frame_index: int = 0) -> Texture2D:
	if texture_id.is_empty():
		return null
	var cache_key: String = "%s:%d" % [texture_id, frame_index]
	if _map_unit_texture_cache.has(cache_key):
		var cached_texture: Texture2D = _map_unit_texture_cache[cache_key] as Texture2D
		return cached_texture
	var texture: Texture2D = null
	var paths: Array[String] = []
	if frame_index == 1:
		paths.append("%s/%s_map_sprite_pos2.png" % [MAP_UNIT_TEXTURE_DIR, texture_id])
		paths.append("%s/%s_sprite_pos2.png" % [MAP_UNIT_TEXTURE_DIR, texture_id])
	paths.append("%s/%s_map_sprite.png" % [MAP_UNIT_TEXTURE_DIR, texture_id])
	paths.append("%s/%s_sprite.png" % [MAP_UNIT_TEXTURE_DIR, texture_id])
	for path in paths:
		if ResourceLoader.exists(path):
			texture = load(path) as Texture2D
			break
	_map_unit_texture_cache[cache_key] = texture
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


func _variant_to_int_dictionary(value: Variant) -> Dictionary:
	var result: Dictionary = {}
	if typeof(value) != TYPE_DICTIONARY:
		return result
	var dictionary: Dictionary = value
	for key_value in dictionary.keys():
		result[str(key_value)] = int(dictionary.get(key_value, 0))
	return result


func _packed_string_array_to_array(values: PackedStringArray) -> Array[String]:
	var result: Array[String] = []
	for entry in values:
		result.append(str(entry))
	return result
