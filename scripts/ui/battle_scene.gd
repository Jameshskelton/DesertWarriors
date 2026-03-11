extends Control

signal battle_finished

var _payload: Dictionary = {}
var _skip_requested: bool = false

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
	_left_texture.texture = _load_portrait_for_unit(attacker)
	_right_texture.texture = _load_portrait_for_unit(defender)
	_left_hp.max_value = attacker.get_max_hp()
	_left_hp.value = _payload.get("attacker_start_hp", attacker.get_current_hp())
	_right_hp.max_value = defender.get_max_hp()
	_right_hp.value = _payload.get("defender_start_hp", defender.get_current_hp())
	_refresh_hp_text()
	_battle_log.text = "%s clashes with %s" % [attacker.display_name, defender.display_name]


func _play_sequence() -> void:
	var result = _payload.get("result") as BattleResult
	var attacker = _payload.get("attacker") as UnitState
	var defender = _payload.get("defender") as UnitState
	if result == null or attacker == null or defender == null:
		_finish_immediately()
		return
	for strike in result.strikes:
		if _skip_requested:
			break
		_battle_log.text = "%s attacks %s" % [strike["attacker_name"], strike["defender_name"]]
		await _pause(0.35)
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


func _unit_color(unit: UnitState) -> Color:
	if unit.faction == "player":
		return Color(0.286275, 0.486275, 0.768627, 1)
	return Color(0.733333, 0.286275, 0.239216, 1)


func _load_portrait_for_unit(unit: UnitState) -> Texture2D:
	if unit == null:
		return null
	if not unit.portrait_id.is_empty():
		var portrait := _load_portrait_by_id(unit.portrait_id)
		if portrait != null:
			return portrait
	return _load_portrait_by_id(unit.unit_id)


func _load_portrait_by_id(portrait_id: String) -> Texture2D:
	if portrait_id.is_empty():
		return null
	var path := "res://assets/portraits/%s.png" % portrait_id
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D
