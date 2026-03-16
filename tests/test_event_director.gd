extends RefCounted


func run() -> PackedStringArray:
	var failures := PackedStringArray()
	DataRegistry.reload_all()
	var chapter: ChapterData = DataRegistry.get_chapter_data("chapter_1")
	var director := EventDirector.new()
	var village_tile := Vector2i(15, 3)
	var preview_events: Array[Dictionary] = director.peek_tile_events("george", village_tile, chapter)
	_assert_equal(preview_events.size(), 1, "chapter_1 village should preview one join event", failures)
	var consumed_events: Array[Dictionary] = director.consume_tile_events("george", village_tile, chapter)
	_assert_equal(consumed_events.size(), 1, "chapter_1 village should consume one join event", failures)
	var remaining_events: Array[Dictionary] = director.peek_tile_events("george", village_tile, chapter)
	_assert_true(remaining_events.is_empty(), "consumed village events should not preview again", failures)
	return failures


func _assert_equal(actual, expected, message: String, failures: PackedStringArray) -> void:
	if actual != expected:
		failures.append("%s (expected %s, got %s)" % [message, str(expected), str(actual)])


func _assert_true(condition: bool, message: String, failures: PackedStringArray) -> void:
	if not condition:
		failures.append(message)
