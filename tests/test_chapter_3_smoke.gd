extends RefCounted


func run() -> PackedStringArray:
	var failures := PackedStringArray()
	DataRegistry.reload_all()
	var chapter: ChapterData = DataRegistry.get_chapter_data("chapter_3")
	if chapter == null:
		failures.append("chapter_3 should exist")
		return failures
	_assert_equal(chapter.reinforcements.size(), 1, "chapter_3 should only keep the enemy reinforcement", failures)
	_assert_equal(chapter.event_triggers.size(), 2, "chapter_3 should have a village recruit event and a boss confrontation event", failures)
	_assert_equal(str(chapter.terrain_legend.get("T", "")), "tall_mountain", "chapter_3 should define tall mountain terrain", failures)
	_assert_equal(str(chapter.terrain_legend.get("S", "")), "store", "chapter_3 should define the new store terrain", failures)
	_assert_equal(chapter.starting_units.size(), 6, "chapter_3 should start with Balt available in the roster preview flow", failures)
	_assert_equal(chapter.terrain_rows[7].substr(3, 3), "BVB", "chapter_3 village should be wrapped with cobblestone on its row", failures)
	_assert_equal(chapter.terrain_rows[14].substr(0, 1), "S", "chapter_3 bottom-left corner should be the store tile", failures)
	var recruit_event: Dictionary = chapter.event_triggers[0]
	_assert_equal(str(recruit_event.get("id", "")), "ricodial_join", "chapter_3 recruit event id should match Ricodial", failures)
	_assert_equal(recruit_event.get("position", Vector2i.ZERO), Vector2i(4, 7), "Ricodial should be recruited from the chapter_3 village", failures)
	var spawn_data: Dictionary = recruit_event.get("spawn", {})
	_assert_equal(str(spawn_data.get("unit_id", "")), "ricodial", "chapter_3 village recruit should spawn Ricodial", failures)
	var boss_event: Dictionary = chapter.event_triggers[1]
	_assert_equal(str(boss_event.get("id", "")), "sir_aldric_confront", "chapter_3 should define Sir Aldric's confrontation event", failures)
	_assert_equal(str(chapter.next_chapter_id), "chapter_4", "chapter_3 should now lead into chapter_4", failures)
	return failures


func _assert_equal(actual, expected, message: String, failures: PackedStringArray) -> void:
	if actual != expected:
		failures.append("%s (expected %s, got %s)" % [message, str(expected), str(actual)])
