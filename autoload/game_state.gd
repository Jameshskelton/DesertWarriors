extends Node

const SAVE_VERSION: int = 1
const DEFAULT_SETTINGS: Dictionary = {
	"battle_speed": 1.0,
	"music_volume": 0.8,
	"sfx_volume": 0.9,
}

var current_chapter_id: String = ""
var roster_state: Dictionary = {}
var cleared_chapters: PackedStringArray = PackedStringArray()
var settings: Dictionary = DEFAULT_SETTINGS.duplicate(true)
var rng_seed: int = 424242
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var last_results: Dictionary = {}
var is_continuing: bool = false


func _ready() -> void:
	rng.seed = rng_seed


func ensure_input_actions() -> void:
	_bind_action("ui_accept", [KEY_ENTER, KEY_SPACE, KEY_Z])
	_bind_action("ui_cancel", [KEY_ESCAPE, KEY_X, KEY_BACKSPACE])
	_bind_action("ui_up", [KEY_UP, KEY_W])
	_bind_action("ui_down", [KEY_DOWN, KEY_S])
	_bind_action("ui_left", [KEY_LEFT, KEY_A])
	_bind_action("ui_right", [KEY_RIGHT, KEY_D])
	_bind_action("end_turn", [KEY_T])
	_bind_action("skip_battle", [KEY_SPACE, KEY_ENTER])


func _bind_action(action_name: String, keycodes: Array) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	for keycode in keycodes:
		var event: InputEventKey = InputEventKey.new()
		event.keycode = keycode
		if not InputMap.action_has_event(action_name, event):
			InputMap.action_add_event(action_name, event)


func reset_runtime() -> void:
	current_chapter_id = ""
	roster_state.clear()
	cleared_chapters.clear()
	settings = DEFAULT_SETTINGS.duplicate(true)
	last_results.clear()
	rng.seed = rng_seed
	is_continuing = false


func start_new_game() -> void:
	reset_runtime()
	current_chapter_id = "chapter_1"


func continue_game() -> bool:
	var save_data = SaveSystem.load_game()
	if save_data.is_empty():
		return false
	
	var version = save_data.get("version", 0)
	if version != SAVE_VERSION:
		push_warning("Save version mismatch: " + str(version))
	
	current_chapter_id = save_data.get("current_chapter_id", "chapter_1")
	cleared_chapters = save_data.get("cleared_chapters", PackedStringArray())
	settings = save_data.get("settings", DEFAULT_SETTINGS.duplicate(true)).duplicate(true)
	rng_seed = save_data.get("rng_seed", 424242)
	rng.seed = rng_seed
	last_results = save_data.get("last_results", {}).duplicate(true)
	
	# Apply saved roster state
	roster_state = save_data.get("roster_state", {}).duplicate(true)
	
	is_continuing = true
	return true


func next_roll() -> float:
	return rng.randf()


func roll_percent(chance_percent: float) -> bool:
	return next_roll() * 100.0 <= clampf(chance_percent, 0.0, 100.0)


func apply_chapter_results(summary: Dictionary) -> void:
	last_results = summary.duplicate(true)
	var chapter_id: String = str(summary.get("chapter_id", ""))
	if not chapter_id.is_empty() and not cleared_chapters.has(chapter_id):
		cleared_chapters.append(chapter_id)
	
	# Update roster state from units
	if summary.has("survivors"):
		var survivors = summary.get("survivors", PackedStringArray())
		for unit_name in survivors:
			if not roster_state.has(unit_name):
				roster_state[unit_name] = {"level": 1, "exp": 0}


func build_save_payload() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"current_chapter_id": current_chapter_id,
		"cleared_chapters": cleared_chapters,
		"settings": settings,
		"rng_seed": rng_seed,
		"last_results": last_results,
		"roster_state": roster_state,
	}
