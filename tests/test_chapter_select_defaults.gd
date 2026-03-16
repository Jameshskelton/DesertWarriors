extends RefCounted


func run() -> PackedStringArray:
	var failures := PackedStringArray()
	DataRegistry.reload_all()
	GameState.prepare_chapter_select_game("chapter_4")
	_assert_true(GameState.current_chapter_id == "chapter_4", "chapter select should set the requested chapter id", failures)
	_assert_true(GameState.cleared_chapters == PackedStringArray(["chapter_1", "chapter_2", "chapter_3"]), "chapter select should seed prior cleared chapters for later maps", failures)
	_assert_true(GameState.roster_state.has("george"), "chapter select should seed George into the default roster", failures)
	_assert_true(GameState.roster_state.has("balt"), "chapter select should seed Balt for chapter_4", failures)
	_assert_true(GameState.roster_state.has("ricodial"), "chapter select should seed Ricodial for chapter_4", failures)
	GameState.prepare_chapter_select_game("chapter_2")
	_assert_true(not GameState.roster_state.has("balt"), "chapter_2 chapter select should not unlock Balt early", failures)
	_assert_true(GameState.roster_state.has("ember"), "chapter_2 chapter select should include Ember", failures)
	_assert_true(GameState.roster_state.has("rowan"), "chapter_2 chapter select should include Rowan", failures)
	return failures


func _assert_true(condition: bool, message: String, failures: PackedStringArray) -> void:
	if not condition:
		failures.append(message)
