extends Resource
class_name ChapterData

@export var id := ""
@export var display_name := ""
@export var objective_type := "defeat_boss"
@export var objective_turns := 0
@export var map_width := 20
@export var map_height := 15
@export var terrain_rows: PackedStringArray = PackedStringArray()
@export var terrain_legend: Dictionary = {}
@export var deployment_slots := 5
@export var deployment_unit_limit := 0
@export var starting_units: Array[Dictionary] = []
@export var enemy_units: Array[Dictionary] = []
@export var reinforcements: Array[Dictionary] = []
@export var event_triggers: Array[Dictionary] = []
@export var opening_dialogue: Array[Dictionary] = []
@export var victory_dialogue: Array[Dictionary] = []
@export var next_chapter_id := "chapter_2"


func get_id() -> String:
	return id
