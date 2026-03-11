extends RefCounted
class_name UnitState

var unit_id: String = ""
var display_name: String = ""
var class_id: String = ""
var level: int = 1
var stats: Dictionary = {}
var xp: int = 0
var inventory: PackedStringArray = PackedStringArray()
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
	state.inventory = data.inventory
	state.portrait_id = data.portrait_id
	state.faction = data.faction if faction_override.is_empty() else faction_override
	state.ai_profile = data.ai_profile
	state.join_event_id = data.join_event_id
	state.story_flags = data.story_flags
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
	if inventory.is_empty():
		return ""
	return inventory[0]


func has_flag(flag_name: String) -> bool:
	return story_flags.has(flag_name)
