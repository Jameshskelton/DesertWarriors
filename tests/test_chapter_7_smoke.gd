extends RefCounted


func run() -> PackedStringArray:
	var failures := PackedStringArray()
	DataRegistry.reload_all()
	var chapter: ChapterData = DataRegistry.get_chapter_data("chapter_7")
	if chapter == null:
		failures.append("chapter_7 should exist")
		return failures
	_assert_equal(chapter.objective_type, "defeat_boss", "chapter_7 should use the defeat_boss objective", failures)
	_assert_equal(chapter.deployment_unit_limit, 2, "chapter_7 should cap deployment at two units", failures)
	_assert_equal(chapter.starting_units.size(), 2, "chapter_7 should start with only George and Talis", failures)
	_assert_equal(str(chapter.starting_units[0].get("unit_id", "")), "george", "chapter_7 should include George", failures)
	_assert_equal(str(chapter.starting_units[1].get("unit_id", "")), "talis", "chapter_7 should include Talis", failures)
	_assert_equal(chapter.enemy_units.size(), 5, "chapter_7 should pit the duo against a raider pack", failures)
	_assert_equal(chapter.event_triggers.size(), 2, "chapter_7 should include a training talk and a boss confrontation", failures)
	for row in chapter.terrain_rows:
		_assert_equal(row.length(), chapter.map_width, "each chapter_7 terrain row should match map width", failures)
	return failures


func _assert_equal(actual, expected, message: String, failures: PackedStringArray) -> void:
	if actual != expected:
		failures.append("%s (expected %s, got %s)" % [message, str(expected), str(actual)])
