extends Node

const CLASS_DIR := "res://data/classes"
const UNIT_DIR := "res://data/units"
const WEAPON_DIR := "res://data/weapons"
const TERRAIN_DIR := "res://data/terrains"
const CHAPTER_DIR := "res://data/chapters"

var classes: Dictionary = {}
var units: Dictionary = {}
var weapons: Dictionary = {}
var terrains: Dictionary = {}
var chapters: Dictionary = {}


func _ready() -> void:
	reload_all()


func reload_all() -> void:
	classes = _load_resource_dir(CLASS_DIR)
	units = _load_resource_dir(UNIT_DIR)
	weapons = _load_resource_dir(WEAPON_DIR)
	terrains = _load_resource_dir(TERRAIN_DIR)
	chapters = _load_resource_dir(CHAPTER_DIR)


func _load_resource_dir(path: String) -> Dictionary:
	var loaded: Dictionary = {}
	var files := DirAccess.get_files_at(path)
	for file_name in files:
		if not file_name.ends_with(".tres") and not file_name.ends_with(".res"):
			continue
		var resource = load(path.path_join(file_name))
		if resource == null:
			continue
		var id_value := ""
		if resource.has_method("get_id"):
			id_value = resource.get_id()
		else:
			var property_value = resource.get("id")
			if typeof(property_value) == TYPE_STRING:
				id_value = property_value
		if id_value.is_empty():
			id_value = file_name.get_basename()
		loaded[id_value] = resource
	return loaded


func get_class_data(id_value: String) -> ClassData:
	return classes.get(id_value)


func get_unit_data(id_value: String) -> UnitData:
	return units.get(id_value)


func get_weapon_data(id_value: String) -> WeaponData:
	return weapons.get(id_value)


func get_terrain_data(id_value: String) -> TerrainData:
	return terrains.get(id_value)


func get_chapter_data(id_value: String) -> ChapterData:
	return chapters.get(id_value)
