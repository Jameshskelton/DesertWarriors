extends Node

signal track_changed(track_name: String)

const BACKGROUND_TRACK_NAME := "desertwarriors"
const BACKGROUND_MUSIC := preload("res://assets/music/desertwarriors.mp3")

var current_track := ""
var _music_volume: float = 0.8
var _sfx_volume: float = 0.9
var _music_player: AudioStreamPlayer


func _ready() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "BackgroundMusic"
	_music_player.stream = BACKGROUND_MUSIC
	_music_player.finished.connect(_on_music_finished)
	add_child(_music_player)
	_music_player.add_to_group("music")
	set_music_volume(_music_volume)
	_start_background_music()


func play_track(_track_name: String) -> void:
	if current_track != BACKGROUND_TRACK_NAME:
		current_track = BACKGROUND_TRACK_NAME
		track_changed.emit(current_track)
	_ensure_music_playing()


func stop_track() -> void:
	_ensure_music_playing()


func set_music_volume(volume: float) -> void:
	_music_volume = clampf(volume, 0.0, 1.0)
	if _music_player != null:
		_music_player.volume_db = linear_to_db(_music_volume)


func set_sfx_volume(volume: float) -> void:
	_sfx_volume = clampf(volume, 0.0, 1.0)


func get_music_volume() -> float:
	return _music_volume


func get_sfx_volume() -> float:
	return _sfx_volume


func _start_background_music() -> void:
	current_track = BACKGROUND_TRACK_NAME
	track_changed.emit(current_track)
	_ensure_music_playing()


func _ensure_music_playing() -> void:
	if _music_player == null:
		return
	if _music_player.stream != BACKGROUND_MUSIC:
		_music_player.stream = BACKGROUND_MUSIC
	if not _music_player.playing:
		_music_player.play()


func _on_music_finished() -> void:
	_ensure_music_playing()
