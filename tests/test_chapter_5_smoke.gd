extends RefCounted


func run() -> PackedStringArray:
	var failures := PackedStringArray()
	DataRegistry.reload_all()
	var chapter: ChapterData = DataRegistry.get_chapter_data("chapter_5")
	if chapter == null:
		failures.append("chapter_5 should exist")
		return failures
	_assert_equal(chapter.objective_type, "defeat_boss", "chapter_5 should use the defeat boss objective", failures)
	_assert_equal(str(chapter.terrain_legend.get("S", "")), "sand", "chapter_5 should define sand terrain", failures)
	var next_chapter_text: String = str(chapter.next_chapter_id)
	_assert_true(next_chapter_text.is_empty() or next_chapter_text == "null" or next_chapter_text == "<null>", "chapter_5 should currently end the campaign", failures)
	_assert_equal(chapter.reinforcements.size(), 1, "chapter_5 should define Ysult as its turn-3 reinforcement", failures)
	var ysult_reinforcement: Dictionary = chapter.reinforcements[0]
	_assert_equal(str(ysult_reinforcement.get("unit_id", "")), "ysult", "chapter_5 reinforcement should introduce Ysult", failures)
	_assert_equal(int(ysult_reinforcement.get("turn", -1)), 3, "Ysult should arrive on turn 3", failures)
	var boss_event: Dictionary = chapter.event_triggers[0]
	_assert_equal(str(boss_event.get("boss_id", "")), "bartram", "chapter_5 boss confrontation should point at Bartram", failures)
	return failures


func _assert_equal(actual, expected, message: String, failures: PackedStringArray) -> void:
	if actual != expected:
		failures.append("%s (expected %s, got %s)" % [message, str(expected), str(actual)])


func _assert_true(condition: bool, message: String, failures: PackedStringArray) -> void:
	if not condition:
		failures.append(message)
