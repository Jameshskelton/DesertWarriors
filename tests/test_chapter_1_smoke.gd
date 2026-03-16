extends RefCounted


func run() -> PackedStringArray:
	var failures := PackedStringArray()
	DataRegistry.reload_all()
	var chapter: ChapterData = DataRegistry.get_chapter_data("chapter_1")
	if chapter == null:
		failures.append("chapter_1 should exist")
		return failures
	_assert_equal(chapter.terrain_rows.size(), 15, "chapter_1 should have 15 terrain rows", failures)
	_assert_equal(chapter.starting_units.size(), 3, "chapter_1 should start with 3 allied units", failures)
	_assert_equal(chapter.enemy_units.size(), 7, "chapter_1 should start with 7 enemy units", failures)
	_assert_equal(chapter.reinforcements.size(), 2, "chapter_1 should have 2 reinforcement entries", failures)
	_assert_equal(chapter.event_triggers.size(), 2, "chapter_1 should have 2 event triggers", failures)
	for row in chapter.terrain_rows:
		_assert_equal(row.length(), chapter.map_width, "each terrain row should match map width", failures)
	return failures


func _assert_equal(actual, expected, message: String, failures: PackedStringArray) -> void:
	if actual != expected:
		failures.append("%s (expected %s, got %s)" % [message, str(expected), str(actual)])
