extends RefCounted


func run() -> PackedStringArray:
	var failures := PackedStringArray()
	DataRegistry.reload_all()
	var chapter: ChapterData = DataRegistry.get_chapter_data("chapter_4")
	if chapter == null:
		failures.append("chapter_4 should exist")
		return failures
	_assert_equal(chapter.objective_type, "survive_turns", "chapter_4 should use the survival objective", failures)
	_assert_equal(chapter.objective_turns, 10, "chapter_4 should require surviving 10 turns", failures)
	_assert_equal(chapter.reinforcements.size(), 11, "chapter_4 should define the wave reinforcements plus boss arrival", failures)
	_assert_equal(str(chapter.terrain_legend.get("B", "")), "cobblestone", "chapter_4 should define monastery cobblestone terrain", failures)
	var boss_reinforcement: Dictionary = chapter.reinforcements[8]
	_assert_equal(int(boss_reinforcement.get("turn", -1)), 6, "Lysandra should arrive on turn 6 after the mid-map pressure builds", failures)
	var boss_event: Dictionary = chapter.event_triggers[0]
	_assert_equal(str(boss_event.get("id", "")), "lysandra_quill_confront", "chapter_4 should define Lysandra's boss confrontation event", failures)
	_assert_equal(str(boss_event.get("boss_id", "")), "lysandra_quill", "chapter_4 boss confrontation should point at Lysandra", failures)
	return failures


func _assert_equal(actual, expected, message: String, failures: PackedStringArray) -> void:
	if actual != expected:
		failures.append("%s (expected %s, got %s)" % [message, str(expected), str(actual)])
