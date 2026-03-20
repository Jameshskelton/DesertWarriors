extends RefCounted


func run() -> PackedStringArray:
	var failures := PackedStringArray()
	DataRegistry.reload_all()
	var chapter: ChapterData = DataRegistry.get_chapter_data("chapter_6")
	if chapter == null:
		failures.append("chapter_6 should exist")
		return failures
	_assert_equal(chapter.objective_type, "survive_turns", "chapter_6 should use the survive_turns objective", failures)
	_assert_equal(chapter.objective_turns, 10, "chapter_6 should last for 10 turns", failures)
	_assert_equal(str(chapter.terrain_legend.get("S", "")), "sand", "chapter_6 should define sand terrain", failures)
	_assert_equal(chapter.starting_units.size(), 8, "chapter_6 should start with the full eight-unit roster", failures)
	_assert_equal(chapter.enemy_units.size(), 5, "chapter_6 should start with five enemies on the map", failures)
	_assert_equal(chapter.reinforcements.size(), 8, "chapter_6 should define four enemy reinforcement waves", failures)
	var next_chapter_text: String = str(chapter.next_chapter_id)
	_assert_true(next_chapter_text.is_empty() or next_chapter_text == "null" or next_chapter_text == "<null>", "chapter_6 should currently end the campaign", failures)
	for row in chapter.terrain_rows:
		_assert_equal(row.length(), chapter.map_width, "each chapter_6 terrain row should match map width", failures)
	return failures


func _assert_equal(actual, expected, message: String, failures: PackedStringArray) -> void:
	if actual != expected:
		failures.append("%s (expected %s, got %s)" % [message, str(expected), str(actual)])


func _assert_true(condition: bool, message: String, failures: PackedStringArray) -> void:
	if not condition:
		failures.append(message)
