extends Control

const TITLE_SCENE := preload("res://scenes/title/title_screen.tscn")
const DIALOGUE_SCENE := preload("res://scenes/dialogue/dialogue_scene.tscn")
const TACTICAL_MAP_SCENE := preload("res://scenes/map/tactical_map.tscn")
const RESULTS_SCENE := preload("res://scenes/results/results_scene.tscn")

@onready var scene_root: Control = $SceneRoot

var _current_scene: Node
var _last_chapter_cleared: String = ""


func _ready() -> void:
	GameState.ensure_input_actions()
	GameState.reset_runtime()
	_show_title()


func _clear_scene() -> void:
	if _current_scene != null:
		_current_scene.queue_free()
		_current_scene = null


func _mount_scene(node: Node) -> void:
	_clear_scene()
	_current_scene = node
	scene_root.add_child(node)


func _show_title() -> void:
	var scene := TITLE_SCENE.instantiate()
	scene.new_game_requested.connect(_on_new_game_requested)
	scene.continue_requested.connect(_on_continue_requested)
	scene.chapter_select_requested.connect(_on_chapter_select_requested)
	_mount_scene(scene)


func _show_dialogue(lines: Array, next_tag: String, chapter_id: String = "") -> void:
	if lines.is_empty():
		push_warning("Dialogue lines are empty, skipping to map")
		if not chapter_id.is_empty():
			_show_map(chapter_id)
		else:
			_show_title()
		return
	
	var scene = DIALOGUE_SCENE.instantiate()
	scene.setup(lines, next_tag)
	scene.dialogue_finished.connect(_on_dialogue_finished)
	_mount_scene(scene)


func _show_map(chapter_id: String) -> void:
	if chapter_id.is_empty():
		push_warning("Chapter ID is empty, returning to title")
		_show_title()
		return
	
	GameState.current_chapter_id = chapter_id
	var scene = TACTICAL_MAP_SCENE.instantiate()
	scene.setup(chapter_id)
	scene.request_dialogue.connect(_show_dialogue)
	scene.chapter_cleared.connect(_on_chapter_cleared)
	scene.chapter_failed.connect(_on_chapter_failed)
	scene.suspend_requested.connect(_on_suspend_requested)
	scene.restart_requested.connect(_on_restart_requested)
	_mount_scene(scene)


func _show_results(summary: Dictionary) -> void:
	var scene = RESULTS_SCENE.instantiate()
	scene.setup(summary)
	scene.return_to_title.connect(_show_title)
	scene.continue_to_next_chapter.connect(_on_continue_to_next_chapter)
	_mount_scene(scene)


func _on_new_game_requested() -> void:
	GameState.start_new_game()
	GameState.is_continuing = false
	var chapter: ChapterData = DataRegistry.get_chapter_data("chapter_1")
	if chapter == null:
		push_error("Failed to load chapter_1")
		_show_title()
		return
	_show_dialogue(chapter.opening_dialogue, "intro_complete")


func _on_continue_requested(chapter_id: String) -> void:
	GameState.is_continuing = true
	if GameState.has_suspend_state_for_chapter(chapter_id):
		_show_map(chapter_id)
		return
	var chapter: ChapterData = DataRegistry.get_chapter_data(chapter_id)
	if chapter == null:
		push_error("Failed to load chapter: " + chapter_id)
		_show_title()
		return
	# Show opening dialogue if it's a fresh chapter, otherwise go straight to map
	var is_already_playing = GameState.cleared_chapters.has(chapter_id)
	if is_already_playing:
		_show_map(chapter_id)
	else:
		_show_dialogue(chapter.opening_dialogue, "intro_complete", chapter_id)


func _on_chapter_select_requested() -> void:
	# Title screen handles this internally
	pass


func _on_dialogue_finished(next_tag: String) -> void:
	match next_tag:
		"intro_complete":
			_show_map(GameState.current_chapter_id)
		"victory_results":
			_show_results(GameState.last_results)
		"next_chapter":
			if _last_chapter_cleared.is_empty():
				push_warning("No next chapter to continue to")
				_show_title()
			else:
				_show_map(_last_chapter_cleared)
		_:
			_show_title()


func _on_chapter_cleared(summary: Dictionary) -> void:
	GameState.apply_chapter_results(summary)
	var chapter_id: String = str(summary.get("chapter_id", "chapter_1"))
	var chapter: ChapterData = DataRegistry.get_chapter_data(chapter_id)
	if chapter == null:
		push_error("Failed to get chapter data for: " + chapter_id)
		_show_results(summary)
		return
	
	_last_chapter_cleared = chapter.next_chapter_id if chapter else ""
	_show_dialogue(chapter.victory_dialogue, "victory_results")


func _on_chapter_failed(summary: Dictionary) -> void:
	GameState.clear_suspend_state()
	_show_results(summary)


func _on_continue_to_next_chapter(next_chapter_id: String) -> void:
	if next_chapter_id.is_empty() or next_chapter_id == "null":
		push_warning("Invalid next chapter ID: " + next_chapter_id)
		_show_title()
		return
	
	var chapter: ChapterData = DataRegistry.get_chapter_data(next_chapter_id)
	if chapter == null:
		push_error("Failed to load chapter: " + next_chapter_id)
		_show_title()
		return
	
	# Update the current chapter ID
	GameState.current_chapter_id = next_chapter_id
	
	# Show the opening dialogue for the next chapter
	_show_dialogue(chapter.opening_dialogue, "next_chapter", next_chapter_id)


func _on_suspend_requested() -> void:
	_show_title()


func _on_restart_requested(chapter_id: String) -> void:
	_show_map(chapter_id)
