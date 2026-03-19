extends RefCounted


func run() -> PackedStringArray:
	var failures := PackedStringArray()
	DataRegistry.reload_all()
	var controller := AIController.new()
	var aldric := UnitState.from_unit_data(DataRegistry.get_unit_data("sir_aldric"), Vector2i(1, 1), "enemy")
	var george := UnitState.from_unit_data(DataRegistry.get_unit_data("george"), Vector2i(4, 1), "player")
	var terrain_grid := [
		["plains", "plains", "plains", "plains", "plains"],
		["plains", "castle", "plains", "plains", "plains"],
		["plains", "plains", "plains", "plains", "plains"],
	]
	_assert_equal(aldric.ai_profile, "castle_guard", "Sir Aldric should use the castle_guard AI profile", failures)
	var hold_action: Dictionary = controller.choose_action(aldric, [aldric, george], terrain_grid)
	_assert_equal(str(hold_action.get("type", "")), "move_wait", "castle_guard enemies should wait when nobody is in range", failures)
	_assert_equal(hold_action.get("destination", Vector2i.ZERO), Vector2i(1, 1), "castle_guard enemies should keep their current tile when holding", failures)
	george.position = Vector2i(2, 1)
	var attack_action: Dictionary = controller.choose_action(aldric, [aldric, george], terrain_grid)
	_assert_equal(str(attack_action.get("type", "")), "move_attack", "castle_guard enemies should still attack from their castle tile", failures)
	_assert_equal(attack_action.get("destination", Vector2i.ZERO), Vector2i(1, 1), "castle_guard attacks should not move off the castle tile", failures)
	var neutral_george := UnitState.from_unit_data(DataRegistry.get_unit_data("george"), Vector2i(0, 0), "neutral")
	var brigand := UnitState.from_unit_data(DataRegistry.get_unit_data("brigand_grunt"), Vector2i(1, 0), "enemy")
	var neutral_action: Dictionary = controller.choose_action(neutral_george, [neutral_george, brigand], terrain_grid)
	_assert_equal(str(neutral_action.get("type", "")), "move_attack", "neutral allies should target enemies with the normal AI", failures)
	return failures


func _assert_equal(actual, expected, message: String, failures: PackedStringArray) -> void:
	if actual != expected:
		failures.append("%s (expected %s, got %s)" % [message, str(expected), str(actual)])
