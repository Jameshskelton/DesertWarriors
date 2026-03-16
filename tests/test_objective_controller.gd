extends RefCounted


func run() -> PackedStringArray:
	var failures := PackedStringArray()
	DataRegistry.reload_all()
	var controller := ObjectiveController.new()
	var chapter := ChapterData.new()
	chapter.objective_type = "survive_turns"
	chapter.objective_turns = 10
	chapter.reinforcements = [{
		"faction": "enemy",
		"instance_id": "lysandra_wave",
		"turn": 5,
		"unit_id": "lysandra_quill",
	}]
	_assert_true(not controller.check_victory([], chapter, 10), "survival maps should not clear before the target turn fully passes", failures)
	_assert_true(not controller.check_victory([], chapter, 5), "survival maps should not clear early before the boss has spawned", failures)
	var boss := UnitState.from_unit_data(DataRegistry.get_unit_data("lysandra_quill"), Vector2i.ZERO)
	boss.unit_id = "lysandra_wave"
	_assert_true(not controller.check_victory([boss], chapter, 5), "survival maps should not clear while the spawned boss is still alive", failures)
	boss.set_current_hp(0)
	_assert_true(controller.check_victory([boss], chapter, 5), "survival maps should clear if the spawned boss is defeated early", failures)
	_assert_true(controller.check_victory([], chapter, 11), "survival maps should clear once the post-target turn begins", failures)
	_assert_true(controller.get_objective_text(chapter) == "Survive 10 Turns or Defeat Boss", "survival boss maps should advertise the alternate victory condition", failures)
	return failures


func _assert_true(condition: bool, message: String, failures: PackedStringArray) -> void:
	if not condition:
		failures.append(message)
