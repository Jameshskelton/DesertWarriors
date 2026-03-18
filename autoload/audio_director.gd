extends Node

signal track_changed(track_name: String)

const DEFAULT_TRACK_NAME := "desertwarriors"
const TRACK_FADE_TIME := 0.45
const SFX_PLAYER_COUNT := 12
const SFX_MIX_RATE := 44100.0
const SFX_BUFFER_LENGTH := 1.8
const TRACK_STREAMS := {
	"battle_theme": preload("res://assets/music/battle_scene.mp3"),
	"desertwarriors": preload("res://assets/music/desertwarriors.mp3"),
	"forest_realm": preload("res://assets/music/desertwarriors.mp3"),
	"story_theme": preload("res://assets/music/desertwarriors.mp3"),
	"title_theme": preload("res://assets/music/desertwarriors.mp3"),
}
const SFX_PRESETS := {
	"attack_hit": [
		{"wave": "noise", "duration": 0.028, "volume": 0.18, "attack": 0.04, "release": 0.68},
		{"wave": "triangle", "frequency": 210.0, "frequency_end": 138.0, "duration": 0.08, "volume": 0.22},
	],
	"battle_loss": [
		{"wave": "triangle", "frequency": 392.0, "frequency_end": 293.66, "duration": 0.14, "volume": 0.2},
		{"wave": "triangle", "frequency": 293.66, "frequency_end": 220.0, "duration": 0.18, "volume": 0.18},
		{"wave": "triangle", "frequency": 220.0, "frequency_end": 164.81, "duration": 0.3, "volume": 0.18},
	],
	"boss_intro": [
		{"wave": "triangle", "frequency": 220.0, "frequency_end": 196.0, "duration": 0.16, "volume": 0.18},
		{"wave": "triangle", "frequency": 293.66, "frequency_end": 261.63, "duration": 0.16, "volume": 0.2},
		{"wave": "triangle", "frequency": 392.0, "frequency_end": 329.63, "duration": 0.26, "volume": 0.2},
		{"wave": "noise", "duration": 0.04, "volume": 0.06, "attack": 0.02, "release": 0.9},
	],
	"chapter_clear": [
		{"wave": "square", "frequency": 523.25, "duration": 0.06, "volume": 0.18},
		{"wave": "square", "frequency": 659.25, "duration": 0.06, "volume": 0.2},
		{"wave": "square", "frequency": 783.99, "duration": 0.08, "volume": 0.2},
		{"wave": "square", "frequency": 1046.5, "duration": 0.12, "volume": 0.2},
		{"wave": "sine", "frequency": 1318.51, "duration": 0.26, "volume": 0.18},
	],
	"crit_sting": [
		{"wave": "square", "frequency": 1046.5, "duration": 0.05, "volume": 0.2},
		{"wave": "square", "frequency": 1318.51, "duration": 0.06, "volume": 0.22},
		{"wave": "square", "frequency": 1567.98, "duration": 0.16, "volume": 0.22},
	],
	"cursor_tick": [
		{"wave": "square", "frequency": 1318.51, "duration": 0.028, "volume": 0.12, "attack": 0.04, "release": 0.8},
	],
	"heal": [
		{"wave": "sine", "frequency": 659.25, "duration": 0.07, "volume": 0.16},
		{"wave": "sine", "frequency": 880.0, "duration": 0.1, "volume": 0.18},
		{"wave": "sine", "frequency": 1046.5, "duration": 0.16, "volume": 0.18},
	],
	"menu_cancel": [
		{"wave": "triangle", "frequency": 659.25, "duration": 0.04, "volume": 0.14},
		{"wave": "triangle", "frequency": 440.0, "duration": 0.08, "volume": 0.16},
	],
	"menu_confirm": [
		{"wave": "square", "frequency": 880.0, "duration": 0.04, "volume": 0.14},
		{"wave": "square", "frequency": 1174.66, "duration": 0.06, "volume": 0.16},
	],
	"miss_whoosh": [
		{"wave": "noise", "duration": 0.08, "volume": 0.08, "attack": 0.04, "release": 0.92},
		{"wave": "sine", "frequency": 720.0, "frequency_end": 420.0, "duration": 0.08, "volume": 0.06},
	],
	"shop_buy": [
		{"wave": "square", "frequency": 987.77, "duration": 0.05, "volume": 0.16},
		{"wave": "square", "frequency": 1318.51, "duration": 0.06, "volume": 0.18},
		{"wave": "sine", "frequency": 1567.98, "duration": 0.14, "volume": 0.16},
	],
	"shop_open": [
		{"wave": "triangle", "frequency": 523.25, "duration": 0.05, "volume": 0.14},
		{"wave": "triangle", "frequency": 659.25, "duration": 0.08, "volume": 0.14},
	],
	"village_visit": [
		{"wave": "triangle", "frequency": 392.0, "duration": 0.06, "volume": 0.14},
		{"wave": "triangle", "frequency": 523.25, "duration": 0.08, "volume": 0.16},
		{"wave": "triangle", "frequency": 659.25, "duration": 0.14, "volume": 0.14},
	],
	"weapon_break": [
		{"wave": "noise", "duration": 0.06, "volume": 0.14, "attack": 0.04, "release": 0.82},
		{"wave": "triangle", "frequency": 240.0, "frequency_end": 92.0, "duration": 0.16, "volume": 0.18},
	],
}

var current_track := ""
var _music_volume: float = 0.8
var _sfx_volume: float = 0.9
var _music_players: Array[AudioStreamPlayer] = []
var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_request_ids: Array[int] = []
var _active_player_index: int = 0
var _next_sfx_player_index: int = 0
var _music_fade_tween: Tween
var _track_positions: Dictionary = {}
var _resume_track_after_battle: String = ""
var _noise_rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	_noise_rng.randomize()
	for player_index in range(2):
		var player := AudioStreamPlayer.new()
		player.name = "BackgroundMusic%d" % player_index
		player.finished.connect(Callable(self, "_on_music_finished").bind(player_index))
		add_child(player)
		player.add_to_group("music")
		player.volume_db = linear_to_db(0.0001)
		_music_players.append(player)
	for player_index in range(SFX_PLAYER_COUNT):
		var sfx_player := AudioStreamPlayer.new()
		sfx_player.name = "SfxPlayer%d" % player_index
		var generator := AudioStreamGenerator.new()
		generator.mix_rate = SFX_MIX_RATE
		generator.buffer_length = SFX_BUFFER_LENGTH
		sfx_player.stream = generator
		sfx_player.volume_db = linear_to_db(0.0001)
		add_child(sfx_player)
		sfx_player.add_to_group("sfx")
		_sfx_players.append(sfx_player)
		_sfx_request_ids.append(0)
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


func play_sfx(sfx_name: String) -> void:
	if _sfx_volume <= 0.0 or not SFX_PRESETS.has(sfx_name) or _sfx_players.is_empty():
		return
	var player_index: int = _next_sfx_player_index
	_next_sfx_player_index = (_next_sfx_player_index + 1) % _sfx_players.size()
	var player: AudioStreamPlayer = _sfx_players[player_index]
	var request_id: int = int(_sfx_request_ids[player_index]) + 1
	_sfx_request_ids[player_index] = request_id
	player.stop()
	player.volume_db = linear_to_db(maxf(_sfx_volume, 0.0001))
	player.play()
	call_deferred("_fill_sfx_buffer", player_index, request_id, sfx_name)


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


func _fill_sfx_buffer(player_index: int, request_id: int, sfx_name: String) -> void:
	if player_index < 0 or player_index >= _sfx_players.size():
		return
	if int(_sfx_request_ids[player_index]) != request_id:
		return
	var player: AudioStreamPlayer = _sfx_players[player_index]
	var playback := player.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback == null:
		return
	var preset_value: Variant = SFX_PRESETS.get(sfx_name, [])
	if typeof(preset_value) != TYPE_ARRAY:
		return
	for segment_value in preset_value:
		if int(_sfx_request_ids[player_index]) != request_id:
			return
		if typeof(segment_value) != TYPE_DICTIONARY:
			continue
		_push_sfx_segment(playback, segment_value)


func _push_sfx_segment(playback: AudioStreamGeneratorPlayback, segment: Dictionary) -> void:
	var duration: float = maxf(0.01, float(segment.get("duration", 0.08)))
	var frame_count: int = maxi(1, int(duration * SFX_MIX_RATE))
	var wave: String = str(segment.get("wave", "sine"))
	var start_frequency: float = maxf(1.0, float(segment.get("frequency", 440.0)))
	var end_frequency: float = maxf(1.0, float(segment.get("frequency_end", start_frequency)))
	var volume: float = clampf(float(segment.get("volume", 0.2)), 0.0, 1.0)
	var attack_ratio: float = clampf(float(segment.get("attack", 0.16)), 0.01, 1.0)
	var release_ratio: float = clampf(float(segment.get("release", 0.24)), 0.01, 1.0)
	var phase: float = 0.0
	for frame_index in range(frame_count):
		var progress: float = float(frame_index) / float(frame_count)
		var attack: float = minf(progress / attack_ratio, 1.0)
		var release: float = minf((1.0 - progress) / release_ratio, 1.0)
		var envelope: float = attack * release
		var frequency: float = lerpf(start_frequency, end_frequency, progress)
		phase = fmod(phase + (TAU * frequency / SFX_MIX_RATE), TAU)
		var sample: float = _sample_wave(wave, phase) * volume * envelope
		playback.push_frame(Vector2(sample, sample))


func _sample_wave(wave: String, phase: float) -> float:
	match wave:
		"noise":
			return _noise_rng.randf_range(-1.0, 1.0)
		"square":
			return 1.0 if sin(phase) >= 0.0 else -1.0
		"triangle":
			return (2.0 / PI) * asin(sin(phase))
		_:
			return sin(phase)
