extends RefCounted


func run() -> PackedStringArray:
	var failures := PackedStringArray()
	DataRegistry.reload_all()
	GameState.prepare_chapter_select_game("chapter_4")
	_assert_true(GameState.current_chapter_id == "chapter_4", "chapter select should set the requested chapter id", failures)
	_assert_true(GameState.cleared_chapters == PackedStringArray(["chapter_1", "chapter_2", "chapter_3"]), "chapter select should seed prior cleared chapters for later maps", failures)
	_assert_true(GameState.gold == 90, "chapter_4 chapter select should seed 90 starting gold", failures)
	_assert_true(GameState.roster_state.has("george"), "chapter select should seed George into the default roster", failures)
	_assert_true(GameState.roster_state.has("balt"), "chapter select should seed Balt for chapter_4", failures)
	_assert_true(GameState.roster_state.has("ricodial"), "chapter select should seed Ricodial for chapter_4", failures)
	GameState.prepare_chapter_select_game("chapter_5")
	_assert_true(GameState.current_chapter_id == "chapter_5", "chapter select should allow jumping directly to chapter_5", failures)
	_assert_true(GameState.cleared_chapters == PackedStringArray(["chapter_1", "chapter_2", "chapter_3", "chapter_4"]), "chapter_5 chapter select should seed prior cleared chapters through chapter_4", failures)
	_assert_true(GameState.gold == 120, "chapter_5 chapter select should seed 120 starting gold", failures)
	_assert_true(GameState.roster_state.has("ricodial"), "chapter_5 chapter select should keep Ricodial in the default roster", failures)
	_assert_true(not GameState.roster_state.has("ysult"), "chapter_5 chapter select should not unlock Ysult before her mid-map arrival", failures)
	GameState.prepare_chapter_select_game("chapter_6")
	_assert_true(GameState.current_chapter_id == "chapter_6", "chapter select should allow jumping directly to chapter_6", failures)
	_assert_true(GameState.cleared_chapters == PackedStringArray(["chapter_1", "chapter_2", "chapter_3", "chapter_4", "chapter_5"]), "chapter_6 chapter select should seed prior cleared chapters through chapter_5", failures)
	_assert_true(GameState.gold == 150, "chapter_6 chapter select should seed 150 starting gold", failures)
	_assert_true(GameState.roster_state.has("ysult"), "chapter_6 chapter select should include Ysult after her chapter_5 arrival", failures)
	_assert_true(not GameState.roster_state.has("talis"), "chapter_6 chapter select should not unlock Talis before the Griesha rescue", failures)
	GameState.prepare_chapter_select_game("chapter_7")
	_assert_true(GameState.current_chapter_id == "chapter_7", "chapter select should allow jumping directly to chapter_7", failures)
	_assert_true(GameState.cleared_chapters == PackedStringArray(["chapter_1", "chapter_2", "chapter_3", "chapter_4", "chapter_5", "chapter_6"]), "chapter_7 chapter select should seed prior cleared chapters through chapter_6", failures)
	_assert_true(GameState.gold == 180, "chapter_7 chapter select should seed 180 starting gold", failures)
	_assert_true(GameState.roster_state.has("talis"), "chapter_7 chapter select should include Talis after the Griesha rescue", failures)
	GameState.prepare_chapter_select_game("chapter_2")
	_assert_true(GameState.gold == 30, "chapter_2 chapter select should seed 30 starting gold", failures)
	_assert_true(not GameState.roster_state.has("balt"), "chapter_2 chapter select should not unlock Balt early", failures)
	_assert_true(GameState.roster_state.has("ember"), "chapter_2 chapter select should include Ember", failures)
	_assert_true(GameState.roster_state.has("rowan"), "chapter_2 chapter select should include Rowan", failures)
	GameState.prepare_chapter_select_game("chapter_1")
	_assert_true(GameState.gold == 0, "chapter_1 chapter select should start with 0 gold", failures)
	return failures


func _assert_true(condition: bool, message: String, failures: PackedStringArray) -> void:
	if not condition:
		failures.append(message)
