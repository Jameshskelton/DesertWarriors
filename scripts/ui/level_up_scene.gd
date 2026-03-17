extends Control

signal level_up_finished

const PORTRAIT_DIR := "res://assets/portraits"
const STAT_ORDER := ["max_hp", "str", "mag", "skl", "spd", "lck", "def", "res"]
const STAT_LABELS := {
	"max_hp": "HP",
	"str": "STR",
	"mag": "MAG",
	"skl": "SKL",
	"spd": "SPD",
	"lck": "LCK",
	"def": "DEF",
	"res": "RES",
}

var _report: Dictionary = {}
var _finished: bool = false

@onready var _title_label: Label = $Overlay/Center/Panel/Margin/VBox/Title
@onready var _name_label: Label = $Overlay/Center/Panel/Margin/VBox/Name
@onready var _summary_label: Label = $Overlay/Center/Panel/Margin/VBox/ContentRow/InfoColumn/Summary
@onready var _gains_label: Label = $Overlay/Center/Panel/Margin/VBox/ContentRow/InfoColumn/Gains
@onready var _portrait_frame: ColorRect = $Overlay/Center/Panel/Margin/VBox/ContentRow/PortraitFrame
@onready var _portrait_texture: TextureRect = $Overlay/Center/Panel/Margin/VBox/ContentRow/PortraitFrame/PortraitTexture
@onready var _portrait_fallback: Label = $Overlay/Center/Panel/Margin/VBox/ContentRow/PortraitFrame/PortraitFallback
@onready var _continue_button: Button = $Overlay/Center/Panel/Margin/VBox/ContinueButton


func setup(report: Dictionary) -> void:
	_report = report.duplicate(true)


func _ready() -> void:
	_continue_button.pressed.connect(Callable(self, "_finish"))
	_populate()
	_continue_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
		_finish()
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_finish()


func _populate() -> void:
	var unit_name: String = str(_report.get("unit_name", "Unit"))
	var previous_level: int = int(_report.get("previous_level", maxi(1, int(_report.get("level", 1)) - 1)))
	var new_level: int = int(_report.get("level", previous_level + 1))
	var class_id: String = str(_report.get("class_id", ""))
	var unit_class_name: String = class_id.capitalize()
	var class_data: ClassData = DataRegistry.get_class_data(class_id)
	if class_data != null:
		unit_class_name = class_data.display_name
	_title_label.text = "Level Up!"
	_name_label.text = unit_name
	_summary_label.text = "%s\nLevel %d -> %d" % [unit_class_name, previous_level, new_level]
	_gains_label.text = _build_gains_text()
	var portrait: Texture2D = _load_portrait()
	_portrait_texture.texture = portrait
	_portrait_texture.visible = portrait != null
	_portrait_fallback.visible = portrait == null
	_portrait_fallback.text = unit_name.to_upper()
	if portrait == null:
		_portrait_frame.color = Color(0.203922, 0.25098, 0.321569, 1.0)
	else:
		_portrait_frame.color = Color(0.121569, 0.14902, 0.184314, 1.0)


func _build_gains_text() -> String:
	var gains_value: Variant = _report.get("gains", {})
	if typeof(gains_value) != TYPE_DICTIONARY:
		return "No stat increases this level."
	var gains: Dictionary = gains_value
	if gains.is_empty():
		return "No stat increases this level."
	var lines: Array[String] = []
	for stat_name in STAT_ORDER:
		if not gains.has(stat_name):
			continue
		lines.append("%s +%d" % [_get_stat_label(stat_name), int(gains.get(stat_name, 0))])
	for stat_name_value in gains.keys():
		var stat_name: String = str(stat_name_value)
		if STAT_ORDER.has(stat_name):
			continue
		lines.append("%s +%d" % [_get_stat_label(stat_name), int(gains.get(stat_name_value, 0))])
	if lines.is_empty():
		return "No stat increases this level."
	return "\n".join(lines)


func _get_stat_label(stat_name: String) -> String:
	if STAT_LABELS.has(stat_name):
		return str(STAT_LABELS[stat_name])
	return stat_name.to_upper()


func _load_portrait() -> Texture2D:
	var portrait_id: String = str(_report.get("portrait_id", ""))
	if not portrait_id.is_empty():
		var portrait: Texture2D = _load_portrait_by_id(portrait_id)
		if portrait != null:
			return portrait
	var unit_id: String = str(_report.get("unit_id", ""))
	if unit_id.is_empty():
		return null
	return _load_portrait_by_id(unit_id)


func _load_portrait_by_id(portrait_id: String) -> Texture2D:
	if portrait_id.is_empty():
		return null
	var path: String = _resolve_portrait_path(portrait_id)
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


func _resolve_portrait_path(portrait_id: String) -> String:
	var exact_path: String = "%s/%s.png" % [PORTRAIT_DIR, portrait_id]
	if ResourceLoader.exists(exact_path):
		return exact_path
	var portrait_key: String = portrait_id.to_lower()
	for file_name in DirAccess.get_files_at(PORTRAIT_DIR):
		if file_name.get_extension().to_lower() != "png":
			continue
		if file_name.get_basename().to_lower() == portrait_key:
			return "%s/%s" % [PORTRAIT_DIR, file_name]
	return exact_path


func _finish() -> void:
	if _finished:
		return
	_finished = true
	level_up_finished.emit()
