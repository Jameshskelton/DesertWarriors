extends Control

signal battle_finished

const FIGHT_ANIMATION_DIR := "res://assets/fight_animations"
const PORTRAIT_DIR := "res://assets/portraits"
const FIGHT_ANIMATION_FRAME_TIME := 1.0 / 18.0
const POPUP_DURATION := 0.55
const STRIKE_PAUSE := 0.12
const BOSS_BANNER_PAUSE := 0.9
const POPUP_RISE_DISTANCE := 42.0
const CRIT_SHAKE_DURATION := 0.28
const CRIT_SHAKE_MAGNITUDE := 18.0
const DAMAGE_POPUP_COLOR := Color(1.0, 0.901961, 0.670588, 1.0)
const MISS_POPUP_COLOR := Color(0.780392, 0.866667, 1.0, 1.0)
const CRIT_POPUP_COLOR := Color(1.0, 0.509804, 0.356863, 1.0)
const BREAK_POPUP_COLOR := Color(1.0, 0.764706, 0.423529, 1.0)
const ADVANTAGE_POPUP_COLOR := Color(1.0, 0.87451, 0.509804, 1.0)
const DISADVANTAGE_POPUP_COLOR := Color(0.984314, 0.615686, 0.521569, 1.0)
const HIT_FLASH_COLOR := Color(1.0, 0.956863, 0.803922, 0.0)
const CRIT_FLASH_COLOR := Color(1.0, 0.639216, 0.47451, 0.0)
const PLAYER_PANEL_COLOR := Color(0.286275, 0.486275, 0.768627, 1.0)
const ENEMY_PANEL_COLOR := Color(0.733333, 0.286275, 0.239216, 1.0)
const BOSS_PANEL_COLOR := Color(0.65098, 0.164706, 0.121569, 1.0)
const BOSS_ACCENT_COLOR := Color(1.0, 0.839216, 0.470588, 1.0)
const TERRAIN_BACKGROUND_TEXTURES := {
	"castle": preload("res://assets/terrain/castle.png"),
	"cobblestone": preload("res://assets/terrain/cobblestone.png"),
	"forest": preload("res://assets/terrain/thicket.png"),
	"mountain": preload("res://assets/terrain/mountain.png"),
	"plains": preload("res://assets/terrain/grassland.png"),
	"river": preload("res://assets/terrain/river.png"),
	"road": preload("res://assets/terrain/road.png"),
	"sand": preload("res://assets/terrain/sand.png"),
	"store": preload("res://assets/terrain/store.png"),
	"tall_mountain": preload("res://assets/terrain/tall_mountain.png"),
	"village": preload("res://assets/terrain/village.png"),
}
const FIGHT_ANIMATION_CLASS_FALLBACKS := {
	"brigand": "brigand_grunt",
	"captain": "captain_grunt",
	"cavalier": "rowan",
	"hunter": "hunter_grunt",
	"knight": "knight_grunt",
	"lord": "george",
	"mage": "ember",
	"paladin": "george",
}

var _payload: Dictionary = {}
var _skip_requested: bool = false
var _sequence_finished: bool = false
var _finish_signal_sent: bool = false
var _animation_frame_cache: Dictionary = {}
var _feedback_tweens: Dictionary = {}
var _left_portrait: Texture2D
var _right_portrait: Texture2D
var _left_popup: Label
var _right_popup: Label
var _center_notice: Label
var _strike_notice: Label
var _left_popup_base_position: Vector2 = Vector2.ZERO
var _right_popup_base_position: Vector2 = Vector2.ZERO
var _center_notice_base_position: Vector2 = Vector2.ZERO
var _strike_notice_base_position: Vector2 = Vector2.ZERO
var _left_hp_tween: Tween
var _right_hp_tween: Tween
var _battle_log_tween: Tween
var _left_hit_flash: ColorRect
var _right_hit_flash: ColorRect
var _background_left_texture: TextureRect
var _background_right_texture: TextureRect
var _background_left_scrim: ColorRect
var _background_right_scrim: ColorRect
var _presentation_base_positions: Dictionary = {}
var _presentation_nodes: Array[Control] = []
var _presentation_shake_token: int = 0
var _shake_rng: RandomNumberGenerator = RandomNumberGenerator.new()

@onready var _background: ColorRect = $Background
@onready var _title_label: Label = $TitleLabel
@onready var _left_panel: PanelContainer = $LeftPanel
@onready var _left_name: Label = $LeftPanel/LeftMargin/LeftVBox/LeftName
@onready var _left_sprite: ColorRect = $LeftPanel/LeftMargin/LeftVBox/LeftSprite
@onready var _left_texture: TextureRect = $LeftPanel/LeftMargin/LeftVBox/LeftSprite/Texture
@onready var _left_hp: ProgressBar = $LeftPanel/LeftMargin/LeftVBox/LeftHp
@onready var _left_stats: Label = $LeftPanel/LeftMargin/LeftVBox/LeftStats
@onready var _right_panel: PanelContainer = $RightPanel
@onready var _right_name: Label = $RightPanel/RightMargin/RightVBox/RightName
@onready var _right_sprite: ColorRect = $RightPanel/RightMargin/RightVBox/RightSprite
@onready var _right_texture: TextureRect = $RightPanel/RightMargin/RightVBox/RightSprite/Texture
@onready var _right_hp: ProgressBar = $RightPanel/RightMargin/RightVBox/RightHp
@onready var _right_stats: Label = $RightPanel/RightMargin/RightVBox/RightStats
@onready var _battle_log: Label = $BattleLog
@onready var _skip_hint: Label = $SkipHint
@onready var _boss_banner: PanelContainer = $BossBanner
@onready var _boss_banner_kicker: Label = $BossBanner/BannerMargin/BannerVBox/Kicker
@onready var _boss_banner_name: Label = $BossBanner/BannerMargin/BannerVBox/BossName
@onready var _boss_banner_title: Label = $BossBanner/BannerMargin/BannerVBox/BossTitle


func setup(payload: Dictionary) -> void:
	_payload = payload


func _ready() -> void:
	AudioDirector.play_track("battle_theme")
	_shake_rng.randomize()
	_boss_banner.visible = false
	_build_background_layers()
	_build_hit_flash_layers()
	_build_feedback_labels()
	_cache_presentation_positions()
	_reset_feedback_labels()
	if not _has_valid_payload():
		_set_battle_log_text("Battle data missing.")
		call_deferred("_finish_sequence", "Battle data missing.")
		return
	_apply_initial_state()
	call_deferred("_play_sequence")


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and _left_popup != null:
		_update_feedback_label_layout()
		_cache_presentation_positions()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("skip_battle"):
		_skip_requested = true


func _apply_initial_state() -> void:
	var attacker: UnitState = _payload.get("attacker") as UnitState
	var defender: UnitState = _payload.get("defender") as UnitState
	if attacker == null or defender == null:
		return
	_left_name.text = attacker.display_name
	_right_name.text = defender.display_name
	_apply_boss_presentation(attacker, defender)
	_left_sprite.color = _unit_color(attacker)
	_right_sprite.color = _unit_color(defender)
	_left_portrait = _load_portrait_for_unit(attacker)
	_right_portrait = _load_portrait_for_unit(defender)
	_left_texture.texture = _left_portrait
	_right_texture.texture = _right_portrait
	_apply_terrain_backgrounds()
	_left_hp.max_value = attacker.get_max_hp()
	_left_hp.value = float(_payload.get("attacker_start_hp", attacker.get_current_hp()))
	_right_hp.max_value = defender.get_max_hp()
	_right_hp.value = float(_payload.get("defender_start_hp", defender.get_current_hp()))
	_refresh_hp_text()
	_set_battle_log_text(_build_opening_log(attacker, defender))
	_restore_portraits()
	_reset_feedback_labels()


func _play_sequence() -> void:
	if _sequence_finished:
		return
	var result: BattleResult = _payload.get("result") as BattleResult
	var attacker: UnitState = _payload.get("attacker") as UnitState
	var defender: UnitState = _payload.get("defender") as UnitState
	if result == null or attacker == null or defender == null:
		_finish_sequence("Battle data missing.")
		return
	if result.strikes.is_empty():
		_finish_sequence()
		return
	await _play_intro_banner(attacker, defender)
	if _sequence_finished or _skip_requested:
		_finish_sequence()
		return
	for strike in result.strikes:
		if _sequence_finished or _skip_requested:
			break
		_reset_feedback_labels()
		var attacker_name: String = str(strike.get("attacker_name", ""))
		var defender_name: String = str(strike.get("defender_name", ""))
		var striking_left: bool = attacker_name == attacker.display_name
		var target_left: bool = defender_name == attacker.display_name
		var striking_unit: UnitState = attacker
		if not striking_left:
			striking_unit = defender
		var target_popup: Label = _right_popup
		if target_left:
			target_popup = _left_popup
		var attacker_popup: Label = _left_popup
		if not striking_left:
			attacker_popup = _right_popup
		var weapon_name: String = str(strike.get("weapon_name", "Weapon"))
		var triangle_state: int = int(strike.get("triangle_state", 0))
		_set_battle_log_text("%s attacks %s with %s" % [attacker_name, defender_name, weapon_name])
		_show_triangle_callout(triangle_state)
		await _play_attack_animation(striking_unit, striking_left)
		if _sequence_finished or _skip_requested:
			break
		var did_hit: bool = bool(strike.get("hit", false))
		var did_crit: bool = bool(strike.get("crit", false))
		var damage: int = int(strike.get("damage", 0))
		var target_hp: int = int(strike.get("target_hp", 0))
		if did_hit:
			AudioDirector.play_sfx("attack_hit")
			_play_hit_spark(target_left, did_crit)
			if did_crit:
				AudioDirector.play_sfx("crit_sting")
				_start_screen_shake()
				_set_battle_log_text("CRITICAL! %s's %s tears through for %d damage!" % [attacker_name, weapon_name, damage], CRIT_POPUP_COLOR)
				_start_feedback_tween(_center_notice, "CRITICAL!", CRIT_POPUP_COLOR)
			else:
				_set_battle_log_text("%s's %s hits for %d damage!" % [attacker_name, weapon_name, damage], DAMAGE_POPUP_COLOR)
			_start_strike_notice(_build_strike_notice(weapon_name, damage, did_hit, did_crit), DAMAGE_POPUP_COLOR if not did_crit else CRIT_POPUP_COLOR)
			_start_feedback_tween(target_popup, "-%d" % damage, DAMAGE_POPUP_COLOR)
			_animate_hp_change(target_left, target_hp)
		else:
			AudioDirector.play_sfx("miss_whoosh")
			_set_battle_log_text("%s's %s misses %s." % [attacker_name, weapon_name, defender_name], MISS_POPUP_COLOR)
			_start_strike_notice(_build_strike_notice(weapon_name, damage, did_hit, did_crit), MISS_POPUP_COLOR)
			_start_feedback_tween(target_popup, "MISS", MISS_POPUP_COLOR)
		await _pause(POPUP_DURATION + 0.05)
		if _sequence_finished or _skip_requested:
			break
		_refresh_hp_text()
		if bool(strike.get("weapon_broke", false)):
			AudioDirector.play_sfx("weapon_break")
			_set_battle_log_text("%s shatters in the clash!" % weapon_name, BREAK_POPUP_COLOR)
			_start_strike_notice("BREAK", BREAK_POPUP_COLOR)
			_start_feedback_tween(attacker_popup, "BREAK", BREAK_POPUP_COLOR)
			await _pause(POPUP_DURATION)
			if _sequence_finished or _skip_requested:
				break
		await _pause(STRIKE_PAUSE)
	_finish_sequence()


func _finish_sequence(final_log: String = "") -> void:
	if _sequence_finished:
		return
	_sequence_finished = true
	_skip_requested = true
	_boss_banner.visible = false
	_reset_presentation_positions()
	_reset_hit_flashes()
	_restore_portraits()
	_stop_hp_tweens()
	_reset_feedback_labels()
	_sync_hp_to_live_state()
	if final_log.is_empty():
		final_log = _build_final_log()
	_set_battle_log_text(final_log)
	call_deferred("_emit_battle_finished_once")


func is_sequence_finished() -> bool:
	return _sequence_finished


func _emit_battle_finished_once() -> void:
	if _finish_signal_sent:
		return
	_finish_signal_sent = true
	battle_finished.emit()


func _has_valid_payload() -> bool:
	return (_payload.get("attacker") as UnitState) != null and (_payload.get("defender") as UnitState) != null and (_payload.get("result") as BattleResult) != null


func _build_final_log() -> String:
	var attacker: UnitState = _payload.get("attacker") as UnitState
	var defender: UnitState = _payload.get("defender") as UnitState
	if attacker == null or defender == null:
		return "Battle ends."
	if not attacker.is_alive() and not defender.is_alive():
		return "%s and %s fall." % [attacker.display_name, defender.display_name]
	if not defender.is_alive():
		return "%s falls." % defender.display_name
	if not attacker.is_alive():
		return "%s falls." % attacker.display_name
	return "Battle ends."


func _sync_hp_to_live_state() -> void:
	var attacker: UnitState = _payload.get("attacker") as UnitState
	var defender: UnitState = _payload.get("defender") as UnitState
	if attacker != null:
		_left_hp.max_value = attacker.get_max_hp()
		_left_hp.value = attacker.get_current_hp()
	if defender != null:
		_right_hp.max_value = defender.get_max_hp()
		_right_hp.value = defender.get_current_hp()
	_refresh_hp_text()


func _refresh_hp_text() -> void:
	_left_stats.text = "HP %d / %d\nTerrain: %s" % [
		int(_left_hp.value),
		int(_left_hp.max_value),
		_get_payload_terrain_name("attacker_terrain_id"),
	]
	_right_stats.text = "HP %d / %d\nTerrain: %s" % [
		int(_right_hp.value),
		int(_right_hp.max_value),
		_get_payload_terrain_name("defender_terrain_id"),
	]


func _pause(duration: float) -> void:
	if duration <= 0.0:
		return
	var remaining: float = duration
	while remaining > 0.0:
		if _skip_requested or _sequence_finished:
			return
		await get_tree().process_frame
		remaining -= get_process_delta_time()


func _play_intro_banner(attacker: UnitState, defender: UnitState) -> void:
	var boss_unit: UnitState = _get_featured_boss_unit(attacker, defender)
	if boss_unit == null:
		return
	_boss_banner.visible = true
	_boss_banner.modulate = Color(1.0, 1.0, 1.0, 1.0)
	await _pause(BOSS_BANNER_PAUSE)
	_boss_banner.visible = false


func _play_attack_animation(unit: UnitState, attacking_left: bool) -> void:
	if _sequence_finished:
		return
	var frames: Array = _load_fight_animation_frames(unit)
	var texture_rect: TextureRect = _left_texture
	if not attacking_left:
		texture_rect = _right_texture
	if frames.is_empty():
		await _pause(0.2)
		_restore_portraits()
		return
	for frame_value in frames:
		if _skip_requested or _sequence_finished:
			break
		var frame: Texture2D = frame_value as Texture2D
		if frame != null:
			texture_rect.texture = frame
		await _pause(FIGHT_ANIMATION_FRAME_TIME)
	_restore_portraits()


func _animate_hp_change(target_left: bool, target_hp: int) -> void:
	var hp_bar: ProgressBar = _right_hp
	var active_tween: Tween = _right_hp_tween
	if target_left:
		hp_bar = _left_hp
		active_tween = _left_hp_tween
	if active_tween != null:
		active_tween.kill()
	if _skip_requested or _sequence_finished:
		hp_bar.value = target_hp
		return
	var tween := create_tween()
	tween.tween_property(hp_bar, "value", float(target_hp), 0.24)
	if target_left:
		_left_hp_tween = tween
	else:
		_right_hp_tween = tween


func _stop_hp_tweens() -> void:
	if _left_hp_tween != null:
		_left_hp_tween.kill()
		_left_hp_tween = null
	if _right_hp_tween != null:
		_right_hp_tween.kill()
		_right_hp_tween = null


func _restore_portraits() -> void:
	_left_texture.texture = _left_portrait
	_right_texture.texture = _right_portrait


func _build_background_layers() -> void:
	if _background_left_texture != null:
		return
	_background_left_texture = _create_background_texture("TerrainLeft", 0.0, 0.5)
	_background_right_texture = _create_background_texture("TerrainRight", 0.5, 1.0)
	_background_left_scrim = _create_background_scrim("TerrainLeftScrim", 0.0, 0.5)
	_background_right_scrim = _create_background_scrim("TerrainRightScrim", 0.5, 1.0)


func _create_background_texture(node_name: String, left_anchor: float, right_anchor: float) -> TextureRect:
	var texture_rect := TextureRect.new()
	texture_rect.name = node_name
	texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_rect.layout_mode = 1
	texture_rect.anchor_left = left_anchor
	texture_rect.anchor_top = 0.0
	texture_rect.anchor_right = right_anchor
	texture_rect.anchor_bottom = 1.0
	texture_rect.grow_horizontal = Control.GROW_DIRECTION_BOTH
	texture_rect.grow_vertical = Control.GROW_DIRECTION_BOTH
	texture_rect.expand_mode = 1
	texture_rect.stretch_mode = 6
	texture_rect.modulate = Color(1.0, 1.0, 1.0, 0.2)
	_background.add_child(texture_rect)
	return texture_rect


func _create_background_scrim(node_name: String, left_anchor: float, right_anchor: float) -> ColorRect:
	var scrim := ColorRect.new()
	scrim.name = node_name
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scrim.layout_mode = 1
	scrim.anchor_left = left_anchor
	scrim.anchor_top = 0.0
	scrim.anchor_right = right_anchor
	scrim.anchor_bottom = 1.0
	scrim.grow_horizontal = Control.GROW_DIRECTION_BOTH
	scrim.grow_vertical = Control.GROW_DIRECTION_BOTH
	scrim.color = Color(0.0, 0.0, 0.0, 0.18)
	_background.add_child(scrim)
	return scrim


func _apply_terrain_backgrounds() -> void:
	if _background_left_texture == null or _background_right_texture == null:
		return
	var attacker_terrain_id: String = str(_payload.get("attacker_terrain_id", "plains"))
	var defender_terrain_id: String = str(_payload.get("defender_terrain_id", "plains"))
	_apply_terrain_background_to_side(_background_left_texture, _background_left_scrim, attacker_terrain_id, true)
	_apply_terrain_background_to_side(_background_right_texture, _background_right_scrim, defender_terrain_id, false)
	_background.color = _build_background_color(attacker_terrain_id, defender_terrain_id)


func _apply_terrain_background_to_side(texture_rect: TextureRect, scrim: ColorRect, terrain_id: String, left_side: bool) -> void:
	if texture_rect == null or scrim == null:
		return
	texture_rect.texture = TERRAIN_BACKGROUND_TEXTURES.get(terrain_id) as Texture2D
	texture_rect.flip_h = not left_side
	texture_rect.modulate = Color(1.0, 1.0, 1.0, 0.22)
	var scrim_color: Color = _get_terrain_color(terrain_id)
	scrim_color.a = 0.18
	scrim.color = scrim_color


func _build_background_color(attacker_terrain_id: String, defender_terrain_id: String) -> Color:
	var left_color: Color = _get_terrain_color(attacker_terrain_id)
	var right_color: Color = _get_terrain_color(defender_terrain_id)
	var mixed := Color(
		(left_color.r + right_color.r) * 0.5,
		(left_color.g + right_color.g) * 0.5,
		(left_color.b + right_color.b) * 0.5,
		0.96
	)
	mixed.r *= 0.34
	mixed.g *= 0.34
	mixed.b *= 0.34
	return mixed


func _get_terrain_color(terrain_id: String) -> Color:
	var terrain: TerrainData = DataRegistry.get_terrain_data(terrain_id)
	if terrain == null:
		return Color(0.18, 0.15, 0.12, 1.0)
	return terrain.map_color


func _get_payload_terrain_name(key: String) -> String:
	var terrain_id: String = str(_payload.get(key, "plains"))
	var terrain: TerrainData = DataRegistry.get_terrain_data(terrain_id)
	if terrain == null:
		return "Unknown"
	return terrain.name


func _build_hit_flash_layers() -> void:
	if _left_hit_flash != null:
		return
	_left_hit_flash = _create_hit_flash(_left_sprite, "LeftHitFlash")
	_right_hit_flash = _create_hit_flash(_right_sprite, "RightHitFlash")


func _create_hit_flash(parent: Control, node_name: String) -> ColorRect:
	var flash := ColorRect.new()
	flash.name = node_name
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.layout_mode = 1
	flash.anchor_right = 1.0
	flash.anchor_bottom = 1.0
	flash.grow_horizontal = Control.GROW_DIRECTION_BOTH
	flash.grow_vertical = Control.GROW_DIRECTION_BOTH
	flash.color = HIT_FLASH_COLOR
	flash.visible = false
	flash.z_index = 3
	parent.add_child(flash)
	return flash


func _play_hit_spark(target_left: bool, critical: bool) -> void:
	var flash: ColorRect = _right_hit_flash
	var texture_rect: TextureRect = _right_texture
	if target_left:
		flash = _left_hit_flash
		texture_rect = _left_texture
	if flash == null or texture_rect == null:
		return
	flash.visible = true
	var flash_color: Color = HIT_FLASH_COLOR
	flash_color.a = 0.58
	if critical:
		flash_color = CRIT_FLASH_COLOR
		flash_color.a = 0.72
	flash.color = flash_color
	texture_rect.pivot_offset = texture_rect.size * 0.5
	texture_rect.scale = Vector2.ONE
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(flash, "color", Color(flash_color.r, flash_color.g, flash_color.b, 0.0), 0.18)
	tween.tween_property(texture_rect, "scale", Vector2.ONE * (1.06 if critical else 1.03), 0.08)
	tween.chain().tween_property(texture_rect, "scale", Vector2.ONE, 0.12)
	tween.chain().tween_callback(func() -> void:
		flash.visible = false
		texture_rect.scale = Vector2.ONE
	)


func _reset_hit_flashes() -> void:
	for flash in [_left_hit_flash, _right_hit_flash]:
		if flash == null:
			continue
		flash.visible = false
		flash.color = HIT_FLASH_COLOR
	_left_texture.scale = Vector2.ONE
	_right_texture.scale = Vector2.ONE


func _cache_presentation_positions() -> void:
	_presentation_nodes = [
		_title_label,
		_left_panel,
		_right_panel,
		_battle_log,
		_skip_hint,
		_boss_banner,
	]
	_presentation_base_positions.clear()
	for node in _presentation_nodes:
		if node == null:
			continue
		_presentation_base_positions[node.get_instance_id()] = node.position


func _reset_presentation_positions() -> void:
	for node in _presentation_nodes:
		if node == null:
			continue
		var base_position: Vector2 = _presentation_base_positions.get(node.get_instance_id(), node.position)
		node.position = base_position


func _start_screen_shake() -> void:
	_presentation_shake_token += 1
	call_deferred("_run_screen_shake", _presentation_shake_token)


func _run_screen_shake(shake_token: int) -> void:
	var elapsed: float = 0.0
	while elapsed < CRIT_SHAKE_DURATION and shake_token == _presentation_shake_token and not _sequence_finished:
		var strength: float = CRIT_SHAKE_MAGNITUDE * (1.0 - (elapsed / CRIT_SHAKE_DURATION))
		for node in _presentation_nodes:
			if node == null:
				continue
			var base_position: Vector2 = _presentation_base_positions.get(node.get_instance_id(), node.position)
			node.position = base_position + Vector2(
				_shake_rng.randf_range(-strength, strength),
				_shake_rng.randf_range(-strength, strength)
			)
		await get_tree().process_frame
		elapsed += get_process_delta_time()
	if shake_token == _presentation_shake_token:
		_reset_presentation_positions()


func _set_battle_log_text(text: String, accent_color: Color = Color(1.0, 1.0, 1.0, 1.0)) -> void:
	_battle_log.text = text
	_battle_log.modulate = accent_color
	_battle_log.pivot_offset = _battle_log.size * 0.5
	if _battle_log_tween != null:
		_battle_log_tween.kill()
	_battle_log.scale = Vector2.ONE * 1.03
	_battle_log_tween = create_tween()
	_battle_log_tween.tween_property(_battle_log, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _show_triangle_callout(triangle_state: int) -> void:
	var callout_text: String = _build_triangle_display_text(triangle_state)
	if callout_text.is_empty():
		return
	var callout_color: Color = ADVANTAGE_POPUP_COLOR
	if triangle_state < 0:
		callout_color = DISADVANTAGE_POPUP_COLOR
	_start_feedback_tween(_center_notice, callout_text, callout_color, 28.0, 0.42, 1.12)


func _build_triangle_display_text(triangle_state: int) -> String:
	if triangle_state > 0:
		return "ADVANTAGE"
	if triangle_state < 0:
		return "DISADVANTAGE"
	return ""


func _build_strike_notice(weapon_name: String, damage: int, did_hit: bool, did_crit: bool) -> String:
	var notice_weapon_name: String = weapon_name.to_upper()
	if not did_hit:
		return "%s - MISS" % notice_weapon_name
	if did_crit:
		return "%s - %d CRIT" % [notice_weapon_name, damage]
	return "%s - %d DMG" % [notice_weapon_name, damage]


func _start_strike_notice(text: String, color: Color) -> void:
	_start_feedback_tween(_strike_notice, text, color, 24.0, 0.5, 1.1)


func _build_feedback_labels() -> void:
	if _left_popup != null:
		return
	_left_popup = _create_feedback_label(50)
	_right_popup = _create_feedback_label(50)
	_center_notice = _create_feedback_label(56)
	_strike_notice = _create_feedback_label(76, Vector2(960.0, 96.0))
	_update_feedback_label_layout()


func _create_feedback_label(font_size: int, label_size: Vector2 = Vector2(420.0, 72.0)) -> Label:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.z_index = 30
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size = label_size
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_outline_color", Color(0.0823529, 0.0470588, 0.0313725, 0.94))
	label.add_theme_constant_override("outline_size", 6)
	label.visible = false
	add_child(label)
	return label


func _update_feedback_label_layout() -> void:
	var root_origin: Vector2 = global_position
	var left_rect: Rect2 = _left_sprite.get_global_rect()
	var right_rect: Rect2 = _right_sprite.get_global_rect()
	var log_rect: Rect2 = _battle_log.get_global_rect()
	_left_popup_base_position = left_rect.position - root_origin + Vector2((left_rect.size.x - _left_popup.size.x) * 0.5, left_rect.size.y * 0.14)
	_right_popup_base_position = right_rect.position - root_origin + Vector2((right_rect.size.x - _right_popup.size.x) * 0.5, right_rect.size.y * 0.14)
	_strike_notice_base_position = log_rect.position - root_origin + Vector2((log_rect.size.x - _strike_notice.size.x) * 0.5, -90.0)
	_center_notice_base_position = log_rect.position - root_origin + Vector2((log_rect.size.x - _center_notice.size.x) * 0.5, -168.0)
	_left_popup.pivot_offset = _left_popup.size / 2.0
	_right_popup.pivot_offset = _right_popup.size / 2.0
	_center_notice.pivot_offset = _center_notice.size / 2.0
	_strike_notice.pivot_offset = _strike_notice.size / 2.0
	_left_popup.position = _left_popup_base_position
	_right_popup.position = _right_popup_base_position
	_center_notice.position = _center_notice_base_position
	_strike_notice.position = _strike_notice_base_position
	_battle_log.pivot_offset = _battle_log.size * 0.5


func _reset_feedback_labels() -> void:
	_reset_feedback_label(_left_popup)
	_reset_feedback_label(_right_popup)
	_reset_feedback_label(_center_notice)
	_reset_feedback_label(_strike_notice)


func _reset_feedback_label(label: Label) -> void:
	if label == null:
		return
	_stop_feedback_tween(label)
	label.visible = false
	label.modulate = Color(1.0, 1.0, 1.0, 1.0)
	label.scale = Vector2.ONE
	label.position = _get_feedback_base_position(label)


func _start_feedback_tween(label: Label, text: String, color: Color, rise_distance: float = POPUP_RISE_DISTANCE, duration: float = POPUP_DURATION, peak_scale: float = 1.06) -> void:
	if label == null or text.is_empty():
		return
	_stop_feedback_tween(label)
	var base_position: Vector2 = _get_feedback_base_position(label)
	label.text = text
	label.visible = true
	label.position = base_position
	label.modulate = Color(1.0, 1.0, 1.0, 1.0)
	label.scale = Vector2.ONE
	label.add_theme_color_override("font_color", color)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position", base_position - Vector2(0.0, rise_distance), duration)
	tween.tween_property(label, "modulate", Color(1.0, 1.0, 1.0, 0.0), duration)
	tween.tween_property(label, "scale", Vector2.ONE * peak_scale, duration * 0.3)
	_feedback_tweens[label.get_instance_id()] = tween


func _stop_feedback_tween(label: Label) -> void:
	if label == null:
		return
	var key: int = label.get_instance_id()
	var tween: Tween = _feedback_tweens.get(key) as Tween
	if tween != null:
		tween.kill()
	_feedback_tweens.erase(key)


func _get_feedback_base_position(label: Label) -> Vector2:
	if label == _left_popup:
		return _left_popup_base_position
	if label == _right_popup:
		return _right_popup_base_position
	if label == _strike_notice:
		return _strike_notice_base_position
	return _center_notice_base_position


func _load_fight_animation_frames(unit: UnitState) -> Array:
	if unit == null:
		return []
	var candidates: PackedStringArray = PackedStringArray()
	var raw_candidates: Array = [
		unit.unit_id,
		unit.portrait_id,
		unit.display_name.to_lower().replace(" ", "_"),
		str(FIGHT_ANIMATION_CLASS_FALLBACKS.get(unit.class_id, "")),
	]
	for candidate_value in raw_candidates:
		var candidate: String = str(candidate_value)
		if candidate.is_empty() or candidates.has(candidate):
			continue
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
	var frames: Array = []
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
	if _unit_is_boss(unit):
		return BOSS_PANEL_COLOR
	if unit.faction == "player":
		return PLAYER_PANEL_COLOR
	if unit.faction == "neutral":
		return Color(0.698039, 0.752941, 0.435294, 1.0)
	return ENEMY_PANEL_COLOR


func _apply_boss_presentation(attacker: UnitState, defender: UnitState) -> void:
	var boss_unit: UnitState = _get_featured_boss_unit(attacker, defender)
	_title_label.text = "Battle"
	_title_label.remove_theme_color_override("font_color")
	_apply_nameplate_style(_left_name, attacker)
	_apply_nameplate_style(_right_name, defender)
	_boss_banner.visible = false
	_boss_banner_kicker.text = ""
	_boss_banner_name.text = ""
	_boss_banner_title.text = ""
	_boss_banner_title.visible = false
	if boss_unit == null:
		return
	_title_label.text = _build_battle_title(attacker, defender)
	_title_label.add_theme_color_override("font_color", BOSS_ACCENT_COLOR)
	_boss_banner_kicker.text = _build_boss_kicker(attacker, defender, boss_unit)
	_boss_banner_name.text = boss_unit.display_name
	_boss_banner_title.text = _get_unit_boss_title(boss_unit)
	_boss_banner_title.visible = not _boss_banner_title.text.is_empty()


func _apply_nameplate_style(label: Label, unit: UnitState) -> void:
	label.remove_theme_color_override("font_color")
	if _unit_is_boss(unit):
		label.add_theme_color_override("font_color", BOSS_ACCENT_COLOR)


func _build_battle_title(attacker: UnitState, defender: UnitState) -> String:
	if _get_featured_boss_unit(attacker, defender) == null:
		return "Battle"
	if _is_george(attacker) or _is_george(defender):
		return "Boss Duel"
	return "Boss Battle"


func _build_boss_kicker(attacker: UnitState, defender: UnitState, boss_unit: UnitState) -> String:
	if _is_george(attacker) or _is_george(defender):
		return "George's Reckoning"
	if boss_unit.faction == "enemy":
		return "Boss Approaches"
	return "A Champion Stands Forward"


func _build_opening_log(attacker: UnitState, defender: UnitState) -> String:
	var boss_unit: UnitState = _get_featured_boss_unit(attacker, defender)
	if boss_unit == null:
		return "%s clashes with %s" % [attacker.display_name, defender.display_name]
	var opposing_unit: UnitState = defender
	if boss_unit == defender:
		opposing_unit = attacker
	return "%s steps forward to face %s." % [opposing_unit.display_name, boss_unit.display_name]


func _get_featured_boss_unit(attacker: UnitState, defender: UnitState) -> UnitState:
	if _unit_is_boss(defender):
		return defender
	if _unit_is_boss(attacker):
		return attacker
	return null


func _unit_is_boss(unit: UnitState) -> bool:
	return unit != null and unit.has_flag("boss")


func _is_george(unit: UnitState) -> bool:
	if unit == null:
		return false
	return unit.base_unit_id == "george" or unit.unit_id == "george" or unit.display_name == "George"


func _get_unit_boss_title(unit: UnitState) -> String:
	var unit_data: UnitData = _get_unit_data(unit)
	if unit_data == null:
		return ""
	return unit_data.boss_title


func _get_unit_data(unit: UnitState) -> UnitData:
	if unit == null:
		return null
	var candidate_ids := PackedStringArray()
	if not unit.base_unit_id.is_empty():
		candidate_ids.append(unit.base_unit_id)
	if not unit.unit_id.is_empty() and not candidate_ids.has(unit.unit_id):
		candidate_ids.append(unit.unit_id)
	for candidate_id in candidate_ids:
		var unit_data: UnitData = DataRegistry.get_unit_data(candidate_id)
		if unit_data != null:
			return unit_data
	return null


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
