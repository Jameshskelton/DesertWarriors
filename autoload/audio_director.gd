extends Node

signal track_changed(track_name: String)

var current_track := ""
var _music_volume: float = 0.8
var _sfx_volume: float = 0.9


func play_track(track_name: String) -> void:
	if current_track == track_name:
		return
	current_track = track_name
	track_changed.emit(track_name)


func stop_track() -> void:
	current_track = ""
	track_changed.emit(current_track)


func set_music_volume(volume: float) -> void:
	_music_volume = clampf(volume, 0.0, 1.0)
	# Apply to any playing music node
	var music = get_tree().get_first_node_in_group("music")
	if music and music is AudioStreamPlayer:
		music.volume_db = linear_to_db(_music_volume)


func set_sfx_volume(volume: float) -> void:
	_sfx_volume = clampf(volume, 0.0, 1.0)


func get_music_volume() -> float:
	return _music_volume


func get_sfx_volume() -> float:
	return _sfx_volume
