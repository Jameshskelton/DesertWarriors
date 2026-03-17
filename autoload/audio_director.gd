extends Node

signal track_changed(track_name: String)

const DEFAULT_TRACK_NAME := "desertwarriors"
const TRACK_FADE_TIME := 0.45
const TRACK_STREAMS := {
	"battle_theme": preload("res://assets/music/battle_scene.mp3"),
	"desertwarriors": preload("res://assets/music/desertwarriors.mp3"),
	"forest_realm": preload("res://assets/music/desertwarriors.mp3"),
	"story_theme": preload("res://assets/music/desertwarriors.mp3"),
	"title_theme": preload("res://assets/music/desertwarriors.mp3"),
}

var current_track := ""
var _music_volume: float = 0.8
var _sfx_volume: float = 0.9
var _music_players: Array[AudioStreamPlayer] = []
var _active_player_index: int = 0
var _music_fade_tween: Tween
var _track_positions: Dictionary = {}
var _resume_track_after_battle: String = ""


func _ready() -> void:
	for player_index in range(2):
		var player := AudioStreamPlayer.new()
		player.name = "BackgroundMusic%d" % player_index
		player.finished.connect(Callable(self, "_on_music_finished").bind(player_index))
		add_child(player)
		player.add_to_group("music")
		player.volume_db = linear_to_db(0.0001)
		_music_players.append(player)
	set_music_volume(_music_volume)
	_start_background_music()


func play_track(track_name: String) -> void:
	var resolved_track_name: String = _resolve_track_name(track_name)
	var target_stream: AudioStream = _get_track_stream(resolved_track_name)
	if target_stream == null:
		return
	if current_track == resolved_track_name and _get_active_player().playing and _get_active_player().stream == target_stream:
		return
	if resolved_track_name == "battle_theme" and not current_track.is_empty() and current_track != "battle_theme":
		_resume_track_after_battle = current_track
	elif resolved_track_name != "battle_theme":
		_resume_track_after_battle = ""
	_crossfade_to_track(resolved_track_name, target_stream, resolved_track_name != "battle_theme")


func resume_previous_track() -> void:
	var resume_track_name: String = _resume_track_after_battle
	if resume_track_name.is_empty():
		resume_track_name = DEFAULT_TRACK_NAME
	_resume_track_after_battle = ""
	var target_stream: AudioStream = _get_track_stream(resume_track_name)
	if target_stream == null:
		return
	if current_track == resume_track_name and _get_active_player().playing and _get_active_player().stream == target_stream:
		return
	_crossfade_to_track(resume_track_name, target_stream, true)


func stop_track() -> void:
	if _music_fade_tween != null:
		_music_fade_tween.kill()
		_music_fade_tween = null
	_store_active_track_position()
	for player in _music_players:
		player.stop()


func set_music_volume(volume: float) -> void:
	_music_volume = clampf(volume, 0.0, 1.0)
	if _music_players.is_empty():
		return
	var active_player: AudioStreamPlayer = _get_active_player()
	if active_player != null:
		active_player.volume_db = _target_volume_db()
	for player_index in range(_music_players.size()):
		if player_index == _active_player_index:
			continue
		_music_players[player_index].volume_db = linear_to_db(0.0001)


func set_sfx_volume(volume: float) -> void:
	_sfx_volume = clampf(volume, 0.0, 1.0)


func get_music_volume() -> float:
	return _music_volume


func get_sfx_volume() -> float:
	return _sfx_volume


func _start_background_music() -> void:
	var default_stream: AudioStream = _get_track_stream(DEFAULT_TRACK_NAME)
	if default_stream == null:
		return
	var active_player: AudioStreamPlayer = _get_active_player()
	active_player.stream = default_stream
	active_player.volume_db = _target_volume_db()
	active_player.play()
	current_track = DEFAULT_TRACK_NAME
	_track_positions[current_track] = 0.0
	track_changed.emit(current_track)


func _crossfade_to_track(track_name: String, stream: AudioStream, resume_saved_position: bool) -> void:
	if _music_fade_tween != null:
		_music_fade_tween.kill()
		_music_fade_tween = null
	var outgoing_player: AudioStreamPlayer = _get_active_player()
	_store_active_track_position()
	var incoming_index: int = 1 - _active_player_index
	var incoming_player: AudioStreamPlayer = _music_players[incoming_index]
	var start_position: float = 0.0
	if resume_saved_position:
		start_position = float(_track_positions.get(track_name, 0.0))
	incoming_player.stop()
	incoming_player.stream = stream
	incoming_player.volume_db = linear_to_db(0.0001)
	incoming_player.play(start_position)
	current_track = track_name
	track_changed.emit(current_track)
	_music_fade_tween = create_tween()
	_music_fade_tween.set_parallel(true)
	_music_fade_tween.tween_property(incoming_player, "volume_db", _target_volume_db(), TRACK_FADE_TIME)
	if outgoing_player != null and outgoing_player.playing:
		_music_fade_tween.tween_property(outgoing_player, "volume_db", linear_to_db(0.0001), TRACK_FADE_TIME)
		_music_fade_tween.chain().tween_callback(func() -> void:
			outgoing_player.stop()
			outgoing_player.volume_db = linear_to_db(0.0001)
		)
	_active_player_index = incoming_index


func _on_music_finished(player_index: int) -> void:
	if player_index != _active_player_index:
		return
	var active_player: AudioStreamPlayer = _get_active_player()
	if active_player == null or active_player.stream == null:
		return
	_track_positions[current_track] = 0.0
	active_player.play()


func _resolve_track_name(track_name: String) -> String:
	if TRACK_STREAMS.has(track_name):
		return track_name
	return DEFAULT_TRACK_NAME


func _get_track_stream(track_name: String) -> AudioStream:
	return TRACK_STREAMS.get(track_name) as AudioStream


func _get_active_player() -> AudioStreamPlayer:
	if _music_players.is_empty():
		return null
	return _music_players[_active_player_index]


func _target_volume_db() -> float:
	if _music_volume <= 0.0:
		return linear_to_db(0.0001)
	return linear_to_db(_music_volume)


func _store_active_track_position() -> void:
	if current_track.is_empty():
		return
	var active_player: AudioStreamPlayer = _get_active_player()
	if active_player == null or not active_player.playing:
		return
	_track_positions[current_track] = maxf(active_player.get_playback_position(), 0.0)
