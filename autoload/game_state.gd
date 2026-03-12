extends Node

const SAVE_VERSION: int = 2
const DEFAULT_SETTINGS: Dictionary = {
	"battle_speed": 1.0,
	"music_volume": 0.8,
	"sfx_volume": 0.9,
}

var current_chapter_id: String = ""
var roster_state: Dictionary = {}
var cleared_chapters: PackedStringArray = PackedStringArray()
var settings: Dictionary = DEFAULT_SETTINGS.duplicate(true)
var rng_seed: int = 424242
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var last_results: Dictionary = {}
var is_continuing: bool = false


func _ready() -> void:
	rng.seed = rng_seed


func ensure_input_actions() -> void:
	_bind_action("ui_accept", [KEY_ENTER, KEY_SPACE, KEY_Z])
	_bind_action("ui_cancel", [KEY_ESCAPE, KEY_X, KEY_BACKSPACE])
	_bind_action("ui_up", [KEY_UP, KEY_W])
	_bind_action("ui_down", [KEY_DOWN, KEY_S])
	_bind_action("ui_left", [KEY_LEFT, KEY_A])
	_bind_action("ui_right", [KEY_RIGHT, KEY_D])
	_bind_action("end_turn", [KEY_T])
	_bind_action("skip_battle", [KEY_SPACE, KEY_ENTER])
	_bind_action("toggle_danger_zone", [KEY_V])


func _bind_action(action_name: String, keycodes: Array) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	for keycode in keycodes:
		var event: InputEventKey = InputEventKey.new()
		event.keycode = keycode
		if not InputMap.action_has_event(action_name, event):
			InputMap.action_add_event(action_name, event)


func reset_runtime() -> void:
	current_chapter_id = ""
	roster_state.clear()
	cleared_chapters.clear()
	settings = DEFAULT_SETTINGS.duplicate(true)
	last_results.clear()
	rng.seed = rng_seed
	is_continuing = false


func start_new_game() -> void:
	reset_runtime()
	current_chapter_id = "chapter_1"


func continue_game() -> bool:
	var save_data = SaveSystem.load_game()
	if save_data.is_empty():
		return false
	DataRegistry.reload_all()
	
	var version = save_data.get("version", 0)
	if version != SAVE_VERSION:
		push_warning("Save version mismatch: " + str(version))
	
	current_chapter_id = _normalize_chapter_id(save_data.get("current_chapter_id", "chapter_1"))
	if current_chapter_id.is_empty():
		current_chapter_id = "chapter_1"
	cleared_chapters = save_data.get("cleared_chapters", PackedStringArray())
	settings = save_data.get("settings", DEFAULT_SETTINGS.duplicate(true)).duplicate(true)
	rng_seed = save_data.get("rng_seed", 424242)
	rng.seed = rng_seed
	last_results = save_data.get("last_results", {}).duplicate(true)
	
	# Apply saved roster state
	roster_state = _normalize_roster_state(save_data.get("roster_state", {}))
	
	is_continuing = true
	return true


func next_roll() -> float:
	return rng.randf()


func roll_percent(chance_percent: float) -> bool:
	return next_roll() * 100.0 <= clampf(chance_percent, 0.0, 100.0)


func apply_chapter_results(summary: Dictionary) -> void:
	last_results = summary.duplicate(true)
	var chapter_id: String = str(summary.get("chapter_id", ""))
	if not chapter_id.is_empty() and not cleared_chapters.has(chapter_id):
		cleared_chapters.append(chapter_id)
	var player_states_value = summary.get("player_states", {})
	if typeof(player_states_value) == TYPE_DICTIONARY:
		var player_states: Dictionary = player_states_value
		for unit_id_value in player_states.keys():
			var unit_id: String = str(unit_id_value)
			var serialized_state = player_states.get(unit_id_value, {})
			if typeof(serialized_state) == TYPE_DICTIONARY:
				roster_state[unit_id] = _normalize_roster_entry(unit_id, serialized_state)
	var next_chapter_id: String = _normalize_chapter_id(summary.get("next_chapter_id", ""))
	if bool(summary.get("success", false)) and not next_chapter_id.is_empty():
		current_chapter_id = next_chapter_id


func restore_player_unit_state(unit: UnitState, unit_id: String) -> bool:
	if unit == null or unit.faction != "player":
		return true
	if roster_state.is_empty():
		return true
	if not roster_state.has(unit_id):
		return false
	var saved_state_value = roster_state.get(unit_id, {})
	if typeof(saved_state_value) != TYPE_DICTIONARY:
		return false
	unit.apply_persistent_state(saved_state_value)
	return true


func build_save_payload() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"current_chapter_id": current_chapter_id,
		"cleared_chapters": cleared_chapters,
		"settings": settings,
		"rng_seed": rng_seed,
		"last_results": last_results,
		"roster_state": roster_state,
	}


func _normalize_roster_state(raw_roster: Variant) -> Dictionary:
	var normalized: Dictionary = {}
	if typeof(raw_roster) != TYPE_DICTIONARY:
		return normalized
	var raw_dictionary: Dictionary = raw_roster
	for key in raw_dictionary.keys():
		var raw_entry = raw_dictionary.get(key, {})
		if typeof(raw_entry) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = raw_entry
		var resolved_unit_id: String = str(entry.get("unit_id", str(key)))
		if DataRegistry.get_unit_data(resolved_unit_id) == null:
			resolved_unit_id = _find_unit_id_by_display_name(str(key))
		if resolved_unit_id.is_empty():
			continue
		normalized[resolved_unit_id] = _normalize_roster_entry(resolved_unit_id, entry)
	return normalized


func _normalize_roster_entry(unit_id: String, raw_entry: Dictionary) -> Dictionary:
	var unit_data: UnitData = DataRegistry.get_unit_data(unit_id)
	if unit_data == null:
		return {}
	var normalized_unit: UnitState = UnitState.from_unit_data(unit_data, Vector2i.ZERO)
	normalized_unit.apply_persistent_state(raw_entry)
	return normalized_unit.to_persistent_state()


func _find_unit_id_by_display_name(display_name: String) -> String:
	for unit_value in DataRegistry.units.values():
		var unit_data := unit_value as UnitData
		if unit_data != null and unit_data.display_name == display_name:
			return unit_data.id
	return ""


func _normalize_chapter_id(value: Variant) -> String:
	if value == null:
		return ""
	var chapter_id: String = str(value)
	if chapter_id == "null" or chapter_id == "<null>":
		return ""
	return chapter_id
