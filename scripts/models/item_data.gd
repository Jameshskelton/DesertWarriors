extends Resource
class_name ItemData

@export var id := ""
@export var name := ""
@export var item_type := "healing"
@export var uses := 1
@export var heal_amount := 10


func get_id() -> String:
	return id
