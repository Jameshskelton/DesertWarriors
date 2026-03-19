extends RefCounted


func run() -> PackedStringArray:
	var failures := PackedStringArray()
	DataRegistry.reload_all()
	var chapter: ChapterData = DataRegistry.get_chapter_data("chapter_1")
	var director := EventDirector.new()
	var village_tile := Vector2i(5, 14)
	var preview_events: Array[Dictionary] = director.peek_tile_events("george", village_tile, chapter)
	_assert_equal(preview_events.size(), 1, "chapter_1 village should preview one join event", failures)
	var consumed_events: Array[Dictionary] = director.consume_tile_events("george", village_tile, chapter)
	_assert_equal(consumed_events.size(), 1, "chapter_1 village should consume one join event", failures)
	var remaining_events: Array[Dictionary] = director.peek_tile_events("george", village_tile, chapter)
	_assert_true(remaining_events.is_empty(), "consumed village events should not preview again", failures)
	var george: UnitState = UnitState.from_unit_data(DataRegistry.get_unit_data("george"), Vector2i(0, 0))
	var bram: UnitState = UnitState.from_unit_data(DataRegistry.get_unit_data("bram"), Vector2i(1, 0))
	var talk_preview: Dictionary = director.peek_talk_event(george, bram, chapter)
	_assert_equal(str(talk_preview.get("id", "")), "chapter_1_talk_george_bram", "chapter_1 should expose George and Bram's talk event", failures)
	var talk_event: Dictionary = director.consume_talk_event(bram, george, chapter)
	_assert_equal(str(talk_event.get("id", "")), "chapter_1_talk_george_bram", "talk events should match in either unit order and consume once", failures)
	var repeated_talk_event: Dictionary = director.consume_talk_event(george, bram, chapter)
	_assert_true(repeated_talk_event.is_empty(), "talk events should only fire once per chapter", failures)
	var briar: UnitState = UnitState.from_unit_data(DataRegistry.get_unit_data("captain_briar"), Vector2i(1, 0), "enemy")
	var boss_event: Dictionary = director.consume_boss_confront_event(george, briar, chapter)
	_assert_equal(str(boss_event.get("id", "")), "captain_briar_confront", "chapter_1 should trigger Briar's confrontation before the first duel", failures)
	var repeated_boss_event: Dictionary = director.consume_boss_confront_event(george, briar, chapter)
	_assert_true(repeated_boss_event.is_empty(), "boss confrontation should only fire once per chapter", failures)
	return failures


func _assert_equal(actual, expected, message: String, failures: PackedStringArray) -> void:
	if actual != expected:
		failures.append("%s (expected %s, got %s)" % [message, str(expected), str(actual)])


func _assert_true(condition: bool, message: String, failures: PackedStringArray) -> void:
	if not condition:
		failures.append(message)
