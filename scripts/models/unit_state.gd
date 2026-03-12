extends RefCounted
class_name UnitState

var unit_id: String = ""
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
