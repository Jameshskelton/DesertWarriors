extends Node

const SAVE_VERSION: int = 3
const DEFAULT_SETTINGS: Dictionary = {
	"battle_speed": 1.0,
	"music_volume": 0.8,
	"sfx_volume": 0.9,
}

var current_chapter_id: String = ""
var roster_state: Dictionary = {}
var cleared_chapters: PackedStringArray = PackedStringArray()
var settings: Dictionary = DEFAULT_SETTINGS.duplicate(true)
var gold: int = 0
var permadeath_enabled: bool = false
var fallen_units: PackedStringArray = PackedStringArray()
var rng_seed: int = 424242
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var last_results: Dictionary = {}
var is_continuing: bool = false
var suspend_state: Dictionary = {}
var preparation_assignments: Dictionary = {}
var convoy_items: Array = []
var tutorial_flags: PackedStringArray = PackedStringArray()


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
	_bind_action("open_system_menu", [KEY_P])
	_bind_action("inspect_unit", [KEY_I])


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
	gold = 0
	permadeath_enabled = false
	fallen_units.clear()
	last_results.clear()
	suspend_state.clear()
	preparation_assignments.clear()
	convoy_items.clear()
	tutorial_flags.clear()
	rng.seed = rng_seed
	is_continuing = false


func start_new_game(use_permadeath: bool = false) -> void:
	reset_runtime()
	current_chapter_id = "chapter_1"
	permadeath_enabled = use_permadeath


func prepare_chapter_select_game(chapter_id: String) -> void:
	start_new_game(false)
	current_chapter_id = _normalize_chapter_id(chapter_id)
	if current_chapter_id.is_empty():
		current_chapter_id = "chapter_1"
	cleared_chapters = _build_chapter_select_cleared_chapters(current_chapter_id)
	roster_state = _build_chapter_select_roster_state(current_chapter_id)
	gold = _build_chapter_select_gold(current_chapter_id)


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
	gold = maxi(0, int(save_data.get("gold", 0)))
	permadeath_enabled = bool(save_data.get("permadeath_enabled", false))
	fallen_units = _variant_to_packed_string_array(save_data.get("fallen_units", PackedStringArray()))
	rng_seed = save_data.get("rng_seed", 424242)
	rng.seed = rng_seed
	last_results = save_data.get("last_results", {}).duplicate(true)
	suspend_state = _normalize_suspend_state(save_data.get("suspend_state", {}))
	preparation_assignments = _normalize_preparation_assignments(save_data.get("preparation_assignments", {}))
	convoy_items = _normalize_convoy_items(save_data.get("convoy_items", []))
	tutorial_flags = _variant_to_packed_string_array(save_data.get("tutorial_flags", PackedStringArray()))
	
	# Apply saved roster state
	roster_state = _normalize_roster_state(save_data.get("roster_state", {}), true)
	
	is_continuing = true
	return true


func next_roll() -> float:
	return rng.randf()


func roll_percent(chance_percent: float) -> bool:
	return next_roll() * 100.0 <= clampf(chance_percent, 0.0, 100.0)


func apply_chapter_results(summary: Dictionary) -> void:
	last_results = summary.duplicate(true)
	suspend_state.clear()
	var chapter_id: String = str(summary.get("chapter_id", ""))
	if not chapter_id.is_empty() and not cleared_chapters.has(chapter_id):
		cleared_chapters.append(chapter_id)
	var should_heal_roster: bool = bool(summary.get("success", false))
	if not permadeath_enabled:
		fallen_units.clear()
	var player_states_value = summary.get("player_states", {})
	if typeof(player_states_value) == TYPE_DICTIONARY:
		var player_states: Dictionary = player_states_value
		for unit_id_value in player_states.keys():
			var unit_id: String = str(unit_id_value)
			var serialized_state = player_states.get(unit_id_value, {})
			if typeof(serialized_state) != TYPE_DICTIONARY:
				continue
			var is_unit_dead: bool = _is_serialized_unit_dead(serialized_state)
			if permadeath_enabled and is_unit_dead:
				roster_state.erase(unit_id)
				if not fallen_units.has(unit_id):
					fallen_units.append(unit_id)
				continue
			if fallen_units.has(unit_id):
				fallen_units.remove_at(fallen_units.find(unit_id))
			roster_state[unit_id] = _normalize_roster_entry(unit_id, serialized_state, should_heal_roster)
	var next_chapter_id: String = _normalize_chapter_id(summary.get("next_chapter_id", ""))
	if bool(summary.get("success", false)) and not next_chapter_id.is_empty():
		current_chapter_id = next_chapter_id


func restore_player_unit_state(unit: UnitState, unit_id: String, allow_missing_roster_entry: bool = false) -> bool:
	if unit == null or unit.faction != "player":
		return true
	if permadeath_enabled and fallen_units.has(unit_id):
		return false
	if roster_state.is_empty():
		return true
	if not roster_state.has(unit_id):
		return allow_missing_roster_entry
	var saved_state_value = roster_state.get(unit_id, {})
	if typeof(saved_state_value) != TYPE_DICTIONARY:
		return false
	unit.apply_persistent_state(saved_state_value)
	return true


func build_preparation_roster(chapter_id: String) -> Array[UnitState]:
	var chapter: ChapterData = DataRegistry.get_chapter_data(_normalize_chapter_id(chapter_id))
	var roster: Array[UnitState] = []
	if chapter == null:
		return roster
	var seen_units: PackedStringArray = PackedStringArray()
	for entry_value in chapter.starting_units:
		if typeof(entry_value) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = entry_value
		var unit_id: String = str(entry.get("unit_id", ""))
		if unit_id.is_empty() or seen_units.has(unit_id):
			continue
		var unit_data: UnitData = DataRegistry.get_unit_data(unit_id)
		if unit_data == null:
			continue
		var faction_override: String = str(entry.get("faction", ""))
		var unit: UnitState = UnitState.from_unit_data(unit_data, Vector2i.ZERO, faction_override)
		if unit.faction != "player":
			continue
		var can_fall_back_to_default_state: bool = not unit_data.join_event_id.is_empty()
		if not restore_player_unit_state(unit, unit_id, can_fall_back_to_default_state):
			continue
		unit.position = Vector2i.ZERO
		unit.reset_turn_state()
		roster.append(unit)
		seen_units.append(unit_id)
	return roster


func store_preparation_roster(units: Array[UnitState]) -> void:
	for unit in units:
		if unit == null or unit.faction != "player":
			continue
		if permadeath_enabled and fallen_units.has(unit.unit_id):
			continue
		roster_state[unit.unit_id] = _normalize_roster_entry(unit.unit_id, unit.to_persistent_state(), false)


func get_chapter_deployment_slots(chapter_id: String) -> Array[Vector2i]:
	var chapter: ChapterData = DataRegistry.get_chapter_data(_normalize_chapter_id(chapter_id))
	var slots: Array[Vector2i] = []
	if chapter == null:
		return slots
	for entry_value in chapter.starting_units:
		if typeof(entry_value) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = entry_value
		if str(entry.get("faction", "")) != "player":
			continue
		var slot_position: Vector2i = _vector2i_from_variant(entry.get("position", Vector2i.ZERO))
		if not slots.has(slot_position):
			slots.append(slot_position)
	return slots


func build_preparation_assignments(chapter_id: String, units: Array[UnitState]) -> Dictionary:
	var slots: Array[Vector2i] = get_chapter_deployment_slots(chapter_id)
	var assignments: Dictionary = {}
	if slots.is_empty() or units.is_empty():
		return assignments
	var valid_unit_ids: PackedStringArray = PackedStringArray()
	for unit in units:
		if unit == null:
			continue
		valid_unit_ids.append(unit.unit_id)
	var chapter_key: String = _normalize_chapter_id(chapter_id)
	var saved_assignments_value: Variant = preparation_assignments.get(chapter_key, {})
	var used_slots: Array[Vector2i] = []
	if typeof(saved_assignments_value) == TYPE_DICTIONARY:
		var saved_assignments: Dictionary = saved_assignments_value
		for unit_id_value in saved_assignments.keys():
			var unit_id: String = str(unit_id_value)
			if not valid_unit_ids.has(unit_id):
				continue
			var slot_position: Vector2i = _vector2i_from_variant(saved_assignments.get(unit_id_value, Vector2i.ZERO))
			if not slots.has(slot_position) or used_slots.has(slot_position):
				continue
			assignments[unit_id] = _serialize_vector2i(slot_position)
			used_slots.append(slot_position)
	var slot_index: int = 0
	for unit in units:
		if unit == null or assignments.has(unit.unit_id):
			continue
		while slot_index < slots.size() and used_slots.has(slots[slot_index]):
			slot_index += 1
		if slot_index >= slots.size():
			break
		assignments[unit.unit_id] = _serialize_vector2i(slots[slot_index])
		used_slots.append(slots[slot_index])
		slot_index += 1
	return assignments


func store_preparation_assignments(chapter_id: String, assignments: Dictionary, units: Array[UnitState]) -> void:
	var chapter_key: String = _normalize_chapter_id(chapter_id)
	if chapter_key.is_empty():
		return
	var slots: Array[Vector2i] = get_chapter_deployment_slots(chapter_key)
	var valid_unit_ids: PackedStringArray = PackedStringArray()
	for unit in units:
		if unit == null:
			continue
		valid_unit_ids.append(unit.unit_id)
	var normalized_assignments: Dictionary = {}
	var used_slots: Array[Vector2i] = []
	for unit_id_value in assignments.keys():
		var unit_id: String = str(unit_id_value)
		if not valid_unit_ids.has(unit_id):
			continue
		var slot_position: Vector2i = _vector2i_from_variant(assignments.get(unit_id_value, Vector2i.ZERO))
		if not slots.has(slot_position) or used_slots.has(slot_position):
			continue
		normalized_assignments[unit_id] = _serialize_vector2i(slot_position)
		used_slots.append(slot_position)
	preparation_assignments[chapter_key] = normalized_assignments


func resolve_preparation_position(chapter_id: String, unit_id: String, fallback_position: Vector2i) -> Vector2i:
	var chapter_key: String = _normalize_chapter_id(chapter_id)
	if chapter_key.is_empty() or not preparation_assignments.has(chapter_key):
		return fallback_position
	var assignments_value: Variant = preparation_assignments.get(chapter_key, {})
	if typeof(assignments_value) != TYPE_DICTIONARY:
		return fallback_position
	var assignments: Dictionary = assignments_value
	if not assignments.has(unit_id):
		return fallback_position
	return _vector2i_from_variant(assignments.get(unit_id, fallback_position))


func build_save_payload() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"current_chapter_id": current_chapter_id,
		"cleared_chapters": cleared_chapters,
		"settings": settings,
		"gold": gold,
		"permadeath_enabled": permadeath_enabled,
		"fallen_units": fallen_units,
		"rng_seed": rng_seed,
		"last_results": last_results,
		"roster_state": roster_state,
		"suspend_state": suspend_state,
		"preparation_assignments": preparation_assignments,
		"convoy_items": convoy_items,
		"tutorial_flags": tutorial_flags,
	}


func has_suspend_state() -> bool:
	return not suspend_state.is_empty()


func has_suspend_state_for_chapter(chapter_id: String) -> bool:
	return has_suspend_state() and _normalize_chapter_id(suspend_state.get("chapter_id", "")) == _normalize_chapter_id(chapter_id)


func set_suspend_state(state: Dictionary) -> void:
	suspend_state = state.duplicate(true)
	var suspend_chapter_id: String = _normalize_chapter_id(suspend_state.get("chapter_id", current_chapter_id))
	if not suspend_chapter_id.is_empty():
		current_chapter_id = suspend_chapter_id


func clear_suspend_state() -> void:
	suspend_state.clear()


func add_gold(amount: int) -> void:
	if amount <= 0:
		return
	gold += amount


func spend_gold(amount: int) -> bool:
	if amount <= 0:
		return true
	if gold < amount:
		return false
	gold -= amount
	return true


func get_convoy_items() -> Array:
	var copied_items: Array = []
	for entry in convoy_items:
		copied_items.append(entry.duplicate(true))
	return copied_items


func add_convoy_item(item_id: String, uses: int = -1) -> void:
	if item_id.is_empty():
		return
	var normalized_uses: int = uses
	if normalized_uses < 0:
		var weapon: WeaponData = DataRegistry.get_weapon_data(item_id)
		if weapon != null:
			normalized_uses = int(weapon.uses)
		else:
			var item: ItemData = DataRegistry.get_item_data(item_id)
			if item != null:
				normalized_uses = int(item.uses)
	if normalized_uses < 0:
		normalized_uses = 0
	convoy_items.append({
		"item_id": item_id,
		"uses": normalized_uses,
	})


func remove_convoy_item(index: int) -> Dictionary:
	if index < 0 or index >= convoy_items.size():
		return {}
	var entry: Dictionary = convoy_items[index].duplicate(true)
	convoy_items.remove_at(index)
	return entry


func has_seen_tutorial(tutorial_id: String) -> bool:
	return not tutorial_id.is_empty() and tutorial_flags.has(tutorial_id)


func should_show_tutorial(tutorial_id: String) -> bool:
	return not has_seen_tutorial(tutorial_id)


func mark_tutorial_seen(tutorial_id: String) -> void:
	if tutorial_id.is_empty() or tutorial_flags.has(tutorial_id):
		return
	tutorial_flags.append(tutorial_id)


func _normalize_roster_state(raw_roster: Variant, heal_to_full: bool = false) -> Dictionary:
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
		normalized[resolved_unit_id] = _normalize_roster_entry(resolved_unit_id, entry, heal_to_full)
	return normalized


func _normalize_suspend_state(raw_suspend_state: Variant) -> Dictionary:
	if typeof(raw_suspend_state) != TYPE_DICTIONARY:
		return {}
	return (raw_suspend_state as Dictionary).duplicate(true)


func _normalize_preparation_assignments(raw_assignments: Variant) -> Dictionary:
	var normalized: Dictionary = {}
	if typeof(raw_assignments) != TYPE_DICTIONARY:
		return normalized
	var raw_dictionary: Dictionary = raw_assignments
	for chapter_key_value in raw_dictionary.keys():
		var chapter_key: String = _normalize_chapter_id(chapter_key_value)
		if chapter_key.is_empty():
			continue
		var chapter_slots: Array[Vector2i] = get_chapter_deployment_slots(chapter_key)
		if chapter_slots.is_empty():
			continue
		var raw_chapter_assignments: Variant = raw_dictionary.get(chapter_key_value, {})
		if typeof(raw_chapter_assignments) != TYPE_DICTIONARY:
			continue
		var chapter_assignments: Dictionary = raw_chapter_assignments
		var normalized_chapter_assignments: Dictionary = {}
		var used_slots: Array[Vector2i] = []
		for unit_id_value in chapter_assignments.keys():
			var unit_id: String = str(unit_id_value)
			if DataRegistry.get_unit_data(unit_id) == null:
				continue
			var slot_position: Vector2i = _vector2i_from_variant(chapter_assignments.get(unit_id_value, Vector2i.ZERO))
			if not chapter_slots.has(slot_position) or used_slots.has(slot_position):
				continue
			normalized_chapter_assignments[unit_id] = _serialize_vector2i(slot_position)
			used_slots.append(slot_position)
		normalized[chapter_key] = normalized_chapter_assignments
	return normalized


func _normalize_convoy_items(raw_convoy_items: Variant) -> Array:
	var normalized: Array = []
	if typeof(raw_convoy_items) != TYPE_ARRAY:
		return normalized
	for entry_value in raw_convoy_items:
		if typeof(entry_value) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = entry_value
		var item_id: String = str(entry.get("item_id", ""))
		if item_id.is_empty():
			continue
		var weapon: WeaponData = DataRegistry.get_weapon_data(item_id)
		var item: ItemData = DataRegistry.get_item_data(item_id)
		if weapon == null and item == null:
			continue
		var uses: int = int(entry.get("uses", -1))
		if uses < 0:
			if weapon != null:
				uses = int(weapon.uses)
			elif item != null:
				uses = int(item.uses)
			else:
				uses = 0
		normalized.append({
			"item_id": item_id,
			"uses": maxi(0, uses),
		})
	return normalized


func _normalize_roster_entry(unit_id: String, raw_entry: Dictionary, heal_to_full: bool = false) -> Dictionary:
	var unit_data: UnitData = DataRegistry.get_unit_data(unit_id)
	if unit_data == null:
		return {}
	var normalized_unit: UnitState = UnitState.from_unit_data(unit_data, Vector2i.ZERO)
	normalized_unit.apply_persistent_state(raw_entry)
	if heal_to_full:
		normalized_unit.set_current_hp(normalized_unit.get_max_hp())
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


func _build_chapter_select_cleared_chapters(chapter_id: String) -> PackedStringArray:
	match chapter_id:
		"chapter_2":
			return PackedStringArray(["chapter_1"])
		"chapter_3":
			return PackedStringArray(["chapter_1", "chapter_2"])
		"chapter_4":
			return PackedStringArray(["chapter_1", "chapter_2", "chapter_3"])
		"chapter_5":
			return PackedStringArray(["chapter_1", "chapter_2", "chapter_3", "chapter_4"])
		_:
			return PackedStringArray()


func _build_chapter_select_roster_state(chapter_id: String) -> Dictionary:
	var roster: Dictionary = {}
	for unit_id in _get_chapter_select_unit_ids(chapter_id):
		var unit_data: UnitData = DataRegistry.get_unit_data(unit_id)
		if unit_data == null:
			continue
		var state: UnitState = UnitState.from_unit_data(unit_data, Vector2i.ZERO)
		state.set_current_hp(state.get_max_hp())
		roster[unit_id] = state.to_persistent_state()
	return roster


func _build_chapter_select_gold(chapter_id: String) -> int:
	var chapter_number: int = 1
	if chapter_id.begins_with("chapter_"):
		chapter_number = maxi(1, int(chapter_id.trim_prefix("chapter_")))
	return maxi(0, (chapter_number - 1) * 30)


func _get_chapter_select_unit_ids(chapter_id: String) -> PackedStringArray:
	match chapter_id:
		"chapter_2":
			return PackedStringArray(["george", "bram", "brother_hale", "ember", "rowan"])
		"chapter_3":
			return PackedStringArray(["george", "bram", "brother_hale", "ember", "rowan", "balt"])
		"chapter_4":
			return PackedStringArray(["george", "bram", "brother_hale", "ember", "rowan", "balt", "ricodial"])
		"chapter_5":
			return PackedStringArray(["george", "bram", "brother_hale", "ember", "rowan", "balt", "ricodial"])
		_:
			return PackedStringArray(["george", "bram", "brother_hale"])


func _vector2i_from_variant(value: Variant) -> Vector2i:
	if value is Vector2i:
		return value
	if typeof(value) == TYPE_DICTIONARY:
		var dictionary: Dictionary = value
		return Vector2i(int(dictionary.get("x", 0)), int(dictionary.get("y", 0)))
	return Vector2i.ZERO


func _serialize_vector2i(value: Vector2i) -> Dictionary:
	return {
		"x": value.x,
		"y": value.y,
	}


func _variant_to_packed_string_array(value: Variant) -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	if value is PackedStringArray:
		for entry in value:
			result.append(str(entry))
	elif value is Array:
		for entry in value:
			result.append(str(entry))
	return result


func _is_serialized_unit_dead(serialized_state: Dictionary) -> bool:
	var stats_value: Variant = serialized_state.get("stats", {})
	if typeof(stats_value) != TYPE_DICTIONARY:
		return false
	var stats: Dictionary = stats_value
	return int(stats.get("hp", 0)) <= 0
