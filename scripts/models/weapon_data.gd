extends Resource
class_name WeaponData

@export var id := ""
@export var name := ""
@export var weapon_type := "sword"
@export var damage_type := "physical"
@export var might := 5
@export var hit := 80
@export var crit := 0
@export var weight := 0
@export var min_range := 1
@export var max_range := 1
@export var uses := 45
@export var triangle_group := "neutral"
@export var anim_id := "basic"
@export var heal_power := 10


func get_id() -> String:
	return id
