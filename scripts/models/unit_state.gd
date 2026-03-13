extends RefCounted
class_name UnitState

var unit_id: String = ""
var base_unit_id: String = ""
var display_name: String = ""
var class_id: String = ""
var level: int = 1
var stats: Dictionary = {}
var xp: int = 0
var inventory: PackedStringArray = PackedStringArray()
var item_uses: Array[int] = []
var portrait_id: String = ""
var faction: String = "player"
var ai_profile: String = "hold"
var join_event_id: String = ""
var story_flags: PackedStringArray = PackedStringArray()
var position: Vector2i = Vector2i.ZERO
var moved: bool = false
var acted: bool = false
var downed: bool = false
var has_joined: bool = true


static func from_unit_data(data: UnitData, tile_position: Vector2i, faction_override: String = "") -> UnitState:
	var state: UnitState = UnitState.new()
	state.unit_id = data.id
	state.base_unit_id = data.id
	state.display_name = data.display_name
	state.class_id = data.class_id
	state.level = data.level
	state.stats = data.stats.duplicate(true)
	state.xp = data.xp
	state.inventory = data.inventory.duplicate()
	state._ensure_item_uses_synced()
	state.portrait_id = data.portrait_id
	state.faction = data.faction if faction_override.is_empty() else faction_override
	state.ai_profile = data.ai_profile
	state.join_event_id = data.join_event_id
	state.story_flags = data.story_flags.duplicate()
	state.position = tile_position
	state.has_joined = faction_override != "reserve"
	return state


func get_max_hp() -> int:
	return int(stats.get("max_hp", 0))


func get_current_hp() -> int:
	return int(stats.get("hp", 0))


func set_current_hp(value: int) -> void:
	stats["hp"] = clampi(value, 0, get_max_hp())
	downed = stats["hp"] <= 0


func is_alive() -> bool:
	return not downed and get_current_hp() > 0


func reset_turn_state() -> void:
	moved = false
	acted = false


func consume_turn() -> void:
	moved = true
	acted = true


func apply_persistent_state(state: Dictionary) -> void:
	if state.is_empty():
		return
	base_unit_id = str(state.get("base_unit_id", base_unit_id))
	display_name = str(state.get("display_name", display_name))
	class_id = str(state.get("class_id", class_id))
	level = int(state.get("level", level))
	xp = int(state.get("xp", xp))
	portrait_id = str(state.get("portrait_id", portrait_id))
	faction = str(state.get("faction", faction))
	ai_profile = str(state.get("ai_profile", ai_profile))
	join_event_id = str(state.get("join_event_id", join_event_id))
	var stats_value = state.get("stats", stats)
	if typeof(stats_value) == TYPE_DICTIONARY:
		stats = (stats_value as Dictionary).duplicate(true)
	var inventory_value = state.get("inventory", [])
	var restored_inventory: PackedStringArray = PackedStringArray()
	if inventory_value is PackedStringArray:
		for entry in inventory_value:
			restored_inventory.append(str(entry))
	elif inventory_value is Array:
		for entry in inventory_value:
			restored_inventory.append(str(entry))
	inventory = restored_inventory
	item_uses.clear()
	var item_uses_value = state.get("item_uses", [])
	if item_uses_value is Array:
		for entry in item_uses_value:
			item_uses.append(int(entry))
	story_flags = _variant_to_packed_string_array(state.get("story_flags", story_flags))
	_ensure_item_uses_synced()
	downed = int(stats.get("hp", 0)) <= 0


func to_persistent_state() -> Dictionary:
	_ensure_item_uses_synced()
	var inventory_values: Array[String] = []
	for item_id in inventory:
		inventory_values.append(str(item_id))
	var saved_item_uses: Array[int] = []
	for remaining_uses in item_uses:
		saved_item_uses.append(int(remaining_uses))
	return {
		"unit_id": unit_id,
		"base_unit_id": base_unit_id,
		"display_name": display_name,
		"class_id": class_id,
		"level": level,
		"stats": stats.duplicate(true),
		"xp": xp,
		"inventory": inventory_values,
		"item_uses": saved_item_uses,
		"portrait_id": portrait_id,
		"faction": faction,
		"ai_profile": ai_profile,
		"join_event_id": join_event_id,
		"story_flags": _packed_string_array_to_array(story_flags),
	}


func to_battle_state() -> Dictionary:
	var state: Dictionary = to_persistent_state()
	state["runtime_unit_id"] = unit_id
	state["position"] = {
		"x": position.x,
		"y": position.y,
	}
	state["moved"] = moved
	state["acted"] = acted
	state["downed"] = downed
	state["has_joined"] = has_joined
	return state


static func from_battle_state(state: Dictionary) -> UnitState:
	if state.is_empty():
		return null
	var template_unit_id: String = str(state.get("base_unit_id", state.get("unit_id", "")))
	var unit_data: UnitData = DataRegistry.get_unit_data(template_unit_id)
	if unit_data == null:
		return null
	var position_value: Variant = state.get("position", Vector2i.ZERO)
	var unit: UnitState = UnitState.from_unit_data(
		unit_data,
		_vector2i_from_variant(position_value),
		str(state.get("faction", unit_data.faction))
	)
	unit.apply_persistent_state(state)
	unit.unit_id = str(state.get("runtime_unit_id", unit.unit_id))
	if unit.unit_id.is_empty():
		unit.unit_id = unit.base_unit_id
	unit.position = _vector2i_from_variant(position_value)
	unit.moved = bool(state.get("moved", unit.moved))
	unit.acted = bool(state.get("acted", unit.acted))
	unit.downed = bool(state.get("downed", unit.downed))
	unit.has_joined = bool(state.get("has_joined", unit.has_joined))
	if unit.downed and unit.get_current_hp() > 0:
		unit.set_current_hp(0)
	return unit


func get_equipped_weapon_id() -> String:
	var weapon_index: int = _find_first_weapon_index()
	if weapon_index == -1:
		return ""
	return str(inventory[weapon_index])


func get_equipped_weapon_uses() -> int:
	_ensure_item_uses_synced()
	var weapon_index: int = _find_first_weapon_index()
	if weapon_index == -1 or weapon_index >= item_uses.size():
		return 0
	return maxi(0, int(item_uses[weapon_index]))


func has_usable_equipped_weapon() -> bool:
	return not get_equipped_weapon_id().is_empty() and get_equipped_weapon_uses() > 0


func consume_equipped_weapon_use() -> bool:
	return consume_item_use(_find_first_weapon_index())


func has_item(item_id: String) -> bool:
	return find_item_index(item_id) != -1


func find_item_index(item_id: String) -> int:
	for item_index in range(inventory.size()):
		if str(inventory[item_index]) == item_id:
			return item_index
	return -1


func get_item_uses_at(item_index: int) -> int:
	_ensure_item_uses_synced()
	if item_index < 0 or item_index >= inventory.size() or item_index >= item_uses.size():
		return 0
	return maxi(0, int(item_uses[item_index]))


func consume_item_use(item_index: int) -> bool:
	_ensure_item_uses_synced()
	if item_index < 0 or item_index >= inventory.size() or item_index >= item_uses.size():
		return false
	var remaining_uses: int = maxi(0, int(item_uses[item_index]) - 1)
	item_uses[item_index] = remaining_uses
	if remaining_uses <= 0:
		_remove_item_at(item_index)
	return true


func has_flag(flag_name: String) -> bool:
	return story_flags.has(flag_name)


func _ensure_item_uses_synced() -> void:
	if inventory.is_empty():
		item_uses.clear()
		return
	while item_uses.size() < inventory.size():
		var item_id: String = str(inventory[item_uses.size()])
		item_uses.append(_get_default_uses_for_item(item_id))
	while item_uses.size() > inventory.size():
		item_uses.pop_back()


func _find_first_weapon_index() -> int:
	for item_index in range(inventory.size()):
		if DataRegistry.get_weapon_data(str(inventory[item_index])) != null:
			return item_index
	return -1


func _get_default_uses_for_item(item_id: String) -> int:
	var weapon: WeaponData = DataRegistry.get_weapon_data(item_id)
	if weapon != null:
		return int(weapon.uses)
	var item: ItemData = DataRegistry.get_item_data(item_id)
	if item != null:
		return int(item.uses)
	return 0


func _remove_item_at(item_index: int) -> void:
	if inventory.is_empty() or item_index < 0 or item_index >= inventory.size():
		return
	var remaining_inventory: PackedStringArray = PackedStringArray()
	for index in range(inventory.size()):
		if index == item_index:
			continue
		remaining_inventory.append(str(inventory[index]))
	inventory = remaining_inventory
	if item_index < item_uses.size():
		item_uses.remove_at(item_index)


static func _vector2i_from_variant(value: Variant) -> Vector2i:
	if value is Vector2i:
		return value
	if typeof(value) == TYPE_DICTIONARY:
		var dictionary: Dictionary = value
		return Vector2i(int(dictionary.get("x", 0)), int(dictionary.get("y", 0)))
	return Vector2i.ZERO


static func _variant_to_packed_string_array(value: Variant) -> PackedStringArray:
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
