extends Resource
class_name UnitData

@export var id := ""
@export var display_name := ""
@export var class_id := ""
@export var level := 1
@export var stats := {
	"max_hp": 18,
	"hp": 18,
	"str": 5,
	"mag": 0,
	"skl": 5,
	"spd": 5,
	"lck": 3,
	"def": 4,
	"res": 1,
}
@export var xp := 0
@export var inventory: PackedStringArray = PackedStringArray()
@export var portrait_id := ""
@export var faction := "player"
@export var ai_profile := "hold"
@export var join_event_id := ""
@export var story_flags: PackedStringArray = PackedStringArray()


func get_id() -> String:
	return id
