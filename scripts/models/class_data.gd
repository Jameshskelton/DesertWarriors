extends Resource
class_name ClassData

@export var id := ""
@export var display_name := ""
@export var move_type := "infantry"
@export var move_range := 5
@export var base_stats := {
	"max_hp": 18,
	"str": 5,
	"mag": 0,
	"skl": 5,
	"spd": 5,
	"lck": 3,
	"def": 4,
	"res": 1,
}
@export var growth_rates := {
	"max_hp": 70,
	"str": 45,
	"mag": 20,
	"skl": 40,
	"spd": 40,
	"lck": 35,
	"def": 30,
	"res": 20,
}
@export var weapon_types: PackedStringArray = PackedStringArray()
@export var can_use_staves := false
@export var battle_anim_set := ""


func get_id() -> String:
	return id
