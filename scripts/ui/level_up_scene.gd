extends Control

signal level_up_finished

const PORTRAIT_DIR := "res://assets/portraits"
const STAT_ORDER := ["max_hp", "str", "mag", "skl", "spd", "lck", "def", "res"]
const INTRO_FADE_TIME := 0.22
const INTRO_STAGGER_TIME := 0.1
const STING_MIX_RATE := 44100.0
const STING_SEGMENTS := [
	{"frequency": 523.25, "duration": 0.08, "volume": 0.32},
	{"frequency": 659.25, "duration": 0.08, "volume": 0.34},
	{"frequency": 783.99, "duration": 0.1, "volume": 0.36},
	{"frequency": 1046.5, "duration": 0.24, "volume": 0.38},
]
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
const CLASS_FLAVOR_TEXT := {
	"captain": "Command settles heavier on the shoulders, but the blade follows with it.",
	"cavalier": "The road opens wider for riders who trust their charge.",
	"hunter": "Distance becomes a weapon when patience and instinct sharpen together.",
	"knight": "Iron yields only to greater resolve, and today that resolve grew.",
	"lord": "A prince's burden grows, but so does the strength to carry it.",
	"mage": "Spellcraft answers careful study with sudden flashes of power.",
	"paladin": "Horse and steel move as one when discipline becomes second nature.",
	"priest": "Grace answers faithful hands with steadier miracles.",
}

var _report: Dictionary = {}
var _finished: bool = false
var _intro_tween: Tween

@onready var _panel: PanelContainer = $Overlay/Center/Panel
@onready var _title_label: Label = $Overlay/Center/Panel/Margin/VBox/Title
@onready var _name_label: Label = $Overlay/Center/Panel/Margin/VBox/Name
@onready var _summary_label: Label = $Overlay/Center/Panel/Margin/VBox/ContentRow/InfoColumn/Summary
@onready var _flavor_label: Label = $Overlay/Center/Panel/Margin/VBox/ContentRow/InfoColumn/Flavor
@onready var _gains_label: Label = $Overlay/Center/Panel/Margin/VBox/ContentRow/InfoColumn/Gains
@onready var _portrait_frame: ColorRect = $Overlay/Center/Panel/Margin/VBox/ContentRow/PortraitFrame
@onready var _portrait_texture: TextureRect = $Overlay/Center/Panel/Margin/VBox/ContentRow/PortraitFrame/PortraitTexture
@onready var _portrait_fallback: Label = $Overlay/Center/Panel/Margin/VBox/ContentRow/PortraitFrame/PortraitFallback
@onready var _continue_button: Button = $Overlay/Center/Panel/Margin/VBox/ContinueButton
@onready var _sting_player: AudioStreamPlayer = $StingPlayer


func setup(report: Dictionary) -> void:
	_report = report.duplicate(true)


func _ready() -> void:
	_continue_button.pressed.connect(Callable(self, "_finish"))
	_prepare_sting_player()
	_populate()
	_set_intro_state()
	call_deferred("_play_intro_presentation")
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
	_flavor_label.text = _build_flavor_text(class_id, unit_name)
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


func _build_flavor_text(class_id: String, unit_name: String) -> String:
	if CLASS_FLAVOR_TEXT.has(class_id):
		return str(CLASS_FLAVOR_TEXT[class_id])
	return "%s grows surer in battle, one hard-earned lesson at a time." % unit_name


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


func _prepare_sting_player() -> void:
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = STING_MIX_RATE
	generator.buffer_length = 0.8
	_sting_player.stream = generator


func _set_intro_state() -> void:
	_panel.pivot_offset = _panel.size * 0.5
	_panel.scale = Vector2(0.94, 0.94)
	_panel.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_title_label.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_title_label.scale = Vector2(1.08, 1.08)
	_name_label.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_summary_label.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_flavor_label.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_gains_label.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_gains_label.scale = Vector2(0.96, 0.96)
	_portrait_frame.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_portrait_frame.scale = Vector2(0.92, 0.92)
	_continue_button.modulate = Color(1.0, 1.0, 1.0, 0.0)


func _play_intro_presentation() -> void:
	if _finished:
		return
	_panel.pivot_offset = _panel.size * 0.5
	_play_level_up_sting()
	_intro_tween = create_tween()
	_intro_tween.tween_property(_panel, "modulate", Color(1.0, 1.0, 1.0, 1.0), INTRO_FADE_TIME)
	_intro_tween.parallel().tween_property(_panel, "scale", Vector2.ONE, INTRO_FADE_TIME).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_intro_tween.chain().tween_property(_title_label, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.14)
	_intro_tween.parallel().tween_property(_title_label, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_intro_tween.chain().tween_interval(INTRO_STAGGER_TIME * 0.4)
	_intro_tween.tween_property(_name_label, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.12)
	_intro_tween.parallel().tween_property(_portrait_frame, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.18)
	_intro_tween.parallel().tween_property(_portrait_frame, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_intro_tween.chain().tween_interval(INTRO_STAGGER_TIME)
	_intro_tween.tween_property(_summary_label, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.12)
	_intro_tween.parallel().tween_property(_flavor_label, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.18)
	_intro_tween.chain().tween_interval(INTRO_STAGGER_TIME)
	_intro_tween.tween_property(_gains_label, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.16)
	_intro_tween.parallel().tween_property(_gains_label, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_intro_tween.chain().tween_interval(INTRO_STAGGER_TIME * 0.5)
	_intro_tween.tween_property(_continue_button, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.14)


func _play_level_up_sting() -> void:
	if AudioDirector.get_sfx_volume() <= 0.0:
		return
	if _sting_player.stream == null:
		_prepare_sting_player()
	_sting_player.volume_db = linear_to_db(maxf(AudioDirector.get_sfx_volume(), 0.0001))
	_sting_player.stop()
	_sting_player.play()
	call_deferred("_fill_sting_buffer")


func _fill_sting_buffer() -> void:
	var playback := _sting_player.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback == null:
		return
	for segment_value in STING_SEGMENTS:
		var segment: Dictionary = segment_value
		_push_sting_tone(
			playback,
			float(segment.get("frequency", 440.0)),
			float(segment.get("duration", 0.08)),
			float(segment.get("volume", 0.3))
		)


func _push_sting_tone(playback: AudioStreamGeneratorPlayback, frequency: float, duration: float, volume: float) -> void:
	var frame_count: int = maxi(1, int(duration * STING_MIX_RATE))
	for frame_index in range(frame_count):
		var progress: float = float(frame_index) / float(frame_count)
		var attack: float = minf(progress / 0.18, 1.0)
		var release: float = minf((1.0 - progress) / 0.32, 1.0)
		var envelope: float = attack * release
		var sample: float = sin(TAU * frequency * (float(frame_index) / STING_MIX_RATE)) * volume * envelope
		playback.push_frame(Vector2(sample, sample))


func _finish() -> void:
	if _finished:
		return
	_finished = true
	if _intro_tween != null:
		_intro_tween.kill()
	_sting_player.stop()
	level_up_finished.emit()
