extends RefCounted
class_name SelectionController

enum Mode {
	IDLE,
	UNIT_SELECTED,
	ACTION_MENU,
	TARGETING,
	ENEMY_PHASE,
	BATTLE,
}

var mode: int = Mode.IDLE
var selected_unit: UnitState
var origin_tile: Vector2i = Vector2i.ZERO
var pending_action: String = ""
var highlighted_tiles: Dictionary = {}
var target_tiles: Array[Vector2i] = []


func reset() -> void:
	mode = Mode.IDLE
	selected_unit = null
	origin_tile = Vector2i.ZERO
	pending_action = ""
	highlighted_tiles.clear()
	target_tiles.clear()
