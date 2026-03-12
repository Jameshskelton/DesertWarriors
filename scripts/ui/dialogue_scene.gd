extends Control

signal dialogue_finished(next_tag: String)

var _lines: Array = []
var _line_index: int = 0
var _next_tag: String = ""

@onready var _chapter_label: Label = $Margin/VBox/ChapterLabel
@onready var _portrait_frame: ColorRect = $Margin/VBox/SpeakerPanel/SpeakerMargin/SpeakerHBox/PortraitFrame
@onready var _portrait_texture: TextureRect = $Margin/VBox/SpeakerPanel/SpeakerMargin/SpeakerHBox/PortraitFrame/PortraitTexture
@onready var _portrait_label: Label = $Margin/VBox/SpeakerPanel/SpeakerMargin/SpeakerHBox/PortraitFrame/PortraitLabel
@onready var _speaker_label: Label = $Margin/VBox/SpeakerPanel/SpeakerMargin/SpeakerHBox/TextVBox/SpeakerLabel
@onready var _dialogue_label: RichTextLabel = $Margin/VBox/SpeakerPanel/SpeakerMargin/SpeakerHBox/TextVBox/DialogueLabel


func setup(lines: Array, next_tag: String) -> void:
	_lines = lines.duplicate()
	_next_tag = next_tag


func _ready() -> void:
	AudioDirector.play_track("story_theme")
	_render_line()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		_advance()


func _advance() -> void:
	_line_index += 1
	if _line_index >= _lines.size():
		dialogue_finished.emit(_next_tag)
		return
	_render_line()


func _render_line() -> void:
	if _lines.is_empty():
		dialogue_finished.emit(_next_tag)
		return
	
	if _line_index < 0 or _line_index >= _lines.size():
		push_warning("Line index out of bounds: " + str(_line_index) + " of " + str(_lines.size()))
		dialogue_finished.emit(_next_tag)
		return
	
	var line = _lines[_line_index]
	if not line is Dictionary:
		push_warning("Line is not a Dictionary: " + str(line))
		dialogue_finished.emit(_next_tag)
		return
	
	_chapter_label.text = str(line.get("chapter", "Desert Warriors"))
	var speaker: String = str(line.get("speaker", "Narrator"))
	_speaker_label.text = speaker
	_dialogue_label.text = str(line.get("text", ""))
	_portrait_label.text = speaker.to_upper()
	var portrait_texture := _load_portrait_for_speaker(speaker)
	_portrait_texture.texture = portrait_texture
	_portrait_texture.visible = portrait_texture != null
	_portrait_label.visible = portrait_texture == null
	_portrait_frame.color = Color(0.121569, 0.14902, 0.184314, 1) if portrait_texture != null else _speaker_color(speaker)


func _speaker_color(speaker: String) -> Color:
	match speaker:
		"George":
			return Color(0.329412, 0.494118, 0.776471, 1)
		"Bram":
			return Color(0.592157, 0.611765, 0.690196, 1)
		"Rowan":
			return Color(0.843137, 0.647059, 0.262745, 1)
		"Ember":
			return Color(0.807843, 0.32549, 0.247059, 1)
		"Brother Hale":
			return Color(0.792157, 0.756863, 0.662745, 1)
		_:
			return Color(0.247059, 0.309804, 0.376471, 1)


func _load_portrait_for_speaker(speaker: String) -> Texture2D:
	for entry in DataRegistry.units.values():
		var unit := entry as UnitData
		if unit == null or unit.display_name != speaker:
			continue
		var portrait := _load_portrait_by_id(unit.portrait_id)
		if portrait != null:
			return portrait
		portrait = _load_portrait_by_id(unit.id)
		if portrait != null:
			return portrait
	var fallback_id := speaker.to_lower().replace(" ", "_")
	return _load_portrait_by_id(fallback_id)


func _load_portrait_by_id(portrait_id: String) -> Texture2D:
	if portrait_id.is_empty():
		return null
	var path := "res://assets/portraits/%s.png" % portrait_id
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D
