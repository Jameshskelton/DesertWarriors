extends RefCounted


func run() -> PackedStringArray:
	var failures := PackedStringArray()
	var controller := ObjectiveController.new()
	var chapter := ChapterData.new()
	chapter.objective_type = "survive_turns"
	chapter.objective_turns = 10
	_assert_true(not controller.check_victory([], chapter, 10), "survival maps should not clear before the target turn fully passes", failures)
	_assert_true(controller.check_victory([], chapter, 11), "survival maps should clear once the post-target turn begins", failures)
	return failures


func _assert_true(condition: bool, message: String, failures: PackedStringArray) -> void:
	if not condition:
		failures.append(message)
