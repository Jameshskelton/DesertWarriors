extends Resource
class_name TerrainData

@export var id := ""
@export var name := ""
@export var move_cost_by_type := {
	"infantry": 1,
	"armored": 1,
	"cavalry": 1,
}
@export var avoid_bonus := 0
@export var def_bonus := 0
@export var is_blocking := false
@export var tile_tags: PackedStringArray = PackedStringArray()
@export var map_color := Color(0.2, 0.34, 0.2, 1.0)


func get_id() -> String:
	return id
