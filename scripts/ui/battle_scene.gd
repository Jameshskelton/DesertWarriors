extends Control

signal battle_finished

const FIGHT_ANIMATION_DIR := "res://assets/fight_animations"
const FIGHT_ANIMATION_FRAME_TIME := 1.0 / 18.0
const FIGHT_ANIMATION_CLASS_FALLBACKS := {
	"brigand": "brigand_grunt",
	"captain": "captain_grunt",
	"cavalier": "rowan",
	"hunter": "hunter_grunt",
	"knight": "knight_grunt",
	"lord": "george",
	"mage": "ember",
}

var _payload: Dictionary = {}
var _skip_requested: bool = false
var _animation_frame_cache: Dictionary = {}
var _left_portrait: Texture2D
var _right_portrait: Texture2D

@onready var _left_name: Label = $LeftPanel/LeftMargin/LeftVBox/LeftName
@onready var _left_sprite: ColorRect = $LeftPanel/LeftMargin/LeftVBox/LeftSprite
@onready var _left_texture: TextureRect = $LeftPanel/LeftMargin/LeftVBox/LeftSprite/Texture
@onready var _left_hp: ProgressBar = $LeftPanel/LeftMargin/LeftVBox/LeftHp
@onready var _left_stats: Label = $LeftPanel/LeftMargin/LeftVBox/LeftStats
@onready var _right_name: Label = $RightPanel/RightMargin/RightVBox/RightName
@onready var _right_sprite: ColorRect = $RightPanel/RightMargin/RightVBox/RightSprite
@onready var _right_texture: TextureRect = $RightPanel/RightMargin/RightVBox/RightSprite/Texture
@onready var _right_hp: ProgressBar = $RightPanel/RightMargin/RightVBox/RightHp
@onready var _right_stats: Label = $RightPanel/RightMargin/RightVBox/RightStats
@onready var _battle_log: Label = $BattleLog


func setup(payload: Dictionary) -> void:
	_payload = payload


func _ready() -> void:
	AudioDirector.play_track("battle_theme")
	if not _has_valid_payload():
		_battle_log.text = "Battle data missing."
		call_deferred("_finish_immediately")
		return
	_apply_initial_state()
	call_deferred("_play_sequence")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("skip_battle"):
		_skip_requested = true


func _apply_initial_state() -> void:
	var attacker = _payload.get("attacker") as UnitState
	var defender = _payload.get("defender") as UnitState
	if attacker == null or defender == null:
		return
	_left_name.text = attacker.display_name
	_right_name.text = defender.display_name
	_left_sprite.color = _unit_color(attacker)
	_right_sprite.color = _unit_color(defender)
	_left_portrait = _load_portrait_for_unit(attacker)
	_right_portrait = _load_portrait_for_unit(defender)
	_left_texture.texture = _left_portrait
	_right_texture.texture = _right_portrait
	_left_hp.max_value = attacker.get_max_hp()
	_left_hp.value = _payload.get("attacker_start_hp", attacker.get_current_hp())
	_right_hp.max_value = defender.get_max_hp()
	_right_hp.value = _payload.get("defender_start_hp", defender.get_current_hp())
	_refresh_hp_text()
	_battle_log.text = "%s clashes with %s" % [attacker.display_name, defender.display_name]


func _play_sequence() -> void:
	var result: BattleResult = _payload.get("result") as BattleResult
	var attacker: UnitState = _payload.get("attacker") as UnitState
	var defender: UnitState = _payload.get("defender") as UnitState
	if result == null or attacker == null or defender == null:
		_finish_immediately()
		return
	for strike in result.strikes:
		if _skip_requested:
			break
		var attacker_name: String = str(strike.get("attacker_name", ""))
		var striking_left: bool = attacker_name == attacker.display_name
		var striking_unit: UnitState = attacker
		if not striking_left:
			striking_unit = defender
		_battle_log.text = "%s attacks %s" % [strike["attacker_name"], strike["defender_name"]]
		await _play_attack_animation(striking_unit, striking_left)
		if strike["hit"]:
			if strike["crit"]:
				_battle_log.text = "Critical! %s loses %d HP" % [strike["defender_name"], strike["damage"]]
			else:
				_battle_log.text = "%s loses %d HP" % [strike["defender_name"], strike["damage"]]
		else:
			_battle_log.text = "%s dodges the blow" % [strike["defender_name"]]
		if strike["defender_name"] == attacker.display_name:
			_left_hp.value = strike["target_hp"]
		else:
			_right_hp.value = strike["target_hp"]
		_refresh_hp_text()
		await _pause(0.45)
	_restore_portraits()
	_left_hp.value = attacker.get_current_hp()
	_right_hp.value = defender.get_current_hp()
	_refresh_hp_text()
	_battle_log.text = "Battle ends."
	await _pause(0.2)
	battle_finished.emit()


func _has_valid_payload() -> bool:
	return (_payload.get("attacker") as UnitState) != null and (_payload.get("defender") as UnitState) != null and (_payload.get("result") as BattleResult) != null


func _finish_immediately() -> void:
	battle_finished.emit()


func _refresh_hp_text() -> void:
	_left_stats.text = "HP %d / %d" % [int(_left_hp.value), int(_left_hp.max_value)]
	_right_stats.text = "HP %d / %d" % [int(_right_hp.value), int(_right_hp.max_value)]


func _pause(duration: float) -> void:
	if _skip_requested:
		await get_tree().process_frame
	else:
		await get_tree().create_timer(duration).timeout


func _play_attack_animation(unit: UnitState, attacking_left: bool) -> void:
	var frames: Array = _load_fight_animation_frames(unit)
	if frames.is_empty():
		await _pause(0.35)
		return
	var texture_rect: TextureRect = _left_texture
	if not attacking_left:
		texture_rect = _right_texture
	for frame in frames:
		if _skip_requested:
			break
		texture_rect.texture = frame
		await _pause(FIGHT_ANIMATION_FRAME_TIME)
	_restore_portraits()


func _restore_portraits() -> void:
	_left_texture.texture = _left_portrait
	_right_texture.texture = _right_portrait


func _load_fight_animation_frames(unit: UnitState) -> Array:
	if unit == null:
		return []
	var candidates: PackedStringArray = PackedStringArray()
	for candidate in [
		unit.unit_id,
		unit.portrait_id,
		unit.display_name.to_lower().replace(" ", "_"),
		str(FIGHT_ANIMATION_CLASS_FALLBACKS.get(unit.class_id, "")),
	]:
		if not candidate.is_empty() and not candidates.has(candidate):
			candidates.append(candidate)
	for candidate in candidates:
		var frames: Array = _load_fight_animation_frames_by_id(candidate)
		if not frames.is_empty():
			return frames
	return []


func _load_fight_animation_frames_by_id(animation_id: String) -> Array:
	if animation_id.is_empty():
		return []
	if _animation_frame_cache.has(animation_id):
		return _animation_frame_cache[animation_id]
	var directory: DirAccess = DirAccess.open("%s/%s" % [FIGHT_ANIMATION_DIR, animation_id])
	var frames: Array[Texture2D] = []
	if directory != null:
		var file_names: PackedStringArray = directory.get_files()
		file_names.sort()
		for file_name in file_names:
			if not file_name.ends_with(".jpg") and not file_name.ends_with(".png") and not file_name.ends_with(".webp"):
				continue
			var texture: Texture2D = load(directory.get_current_dir().path_join(file_name)) as Texture2D
			if texture != null:
				frames.append(texture)
	_animation_frame_cache[animation_id] = frames
	return frames


func _unit_color(unit: UnitState) -> Color:
	if unit.faction == "player":
		return Color(0.286275, 0.486275, 0.768627, 1)
	return Color(0.733333, 0.286275, 0.239216, 1)


func _load_portrait_for_unit(unit: UnitState) -> Texture2D:
	if unit == null:
		return null
	if not unit.portrait_id.is_empty():
		var portrait: Texture2D = _load_portrait_by_id(unit.portrait_id)
		if portrait != null:
			return portrait
	return _load_portrait_by_id(unit.unit_id)


func _load_portrait_by_id(portrait_id: String) -> Texture2D:
	if portrait_id.is_empty():
		return null
	var path: String = "res://assets/portraits/%s.png" % portrait_id
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D
