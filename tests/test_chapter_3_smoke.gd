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
	var recruit_event: Dictionary = chapter.event_triggers[0]
	_assert_equal(str(recruit_event.get("id", "")), "ricodial_join", "chapter_3 recruit event id should match Ricodial", failures)
	_assert_equal(recruit_event.get("position", Vector2i.ZERO), Vector2i(4, 7), "Ricodial should be recruited from the chapter_3 village", failures)
	var spawn_data: Dictionary = recruit_event.get("spawn", {})
	_assert_equal(str(spawn_data.get("unit_id", "")), "ricodial", "chapter_3 village recruit should spawn Ricodial", failures)
	var boss_event: Dictionary = chapter.event_triggers[1]
	_assert_equal(str(boss_event.get("id", "")), "sir_aldric_confront", "chapter_3 should define Sir Aldric's confrontation event", failures)
	return failures


func _assert_equal(actual, expected, message: String, failures: PackedStringArray) -> void:
	if actual != expected:
		failures.append("%s (expected %s, got %s)" % [message, str(expected), str(actual)])
