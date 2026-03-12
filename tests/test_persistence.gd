extends RefCounted


func run() -> PackedStringArray:
	var failures := PackedStringArray()
	DataRegistry.reload_all()
	GameState.reset_runtime()
	var george := UnitState.from_unit_data(DataRegistry.get_unit_data("george"), Vector2i(0, 0))
	george.set_current_hp(9)
	george.xp = 35
	george.item_uses[0] = 31
	var potion_index: int = george.find_item_index("health_potion")
	george.consume_item_use(potion_index)
	var ember := UnitState.from_unit_data(DataRegistry.get_unit_data("ember"), Vector2i(0, 0))
	ember.set_current_hp(4)
	var summary := {
		"success": true,
		"chapter_id": "chapter_1",
		"next_chapter_id": "chapter_2",
		"player_states": {
			"george": george.to_persistent_state(),
			"ember": ember.to_persistent_state(),
		},
	}
	GameState.apply_chapter_results(summary)
	_assert_true(GameState.current_chapter_id == "chapter_2", "clearing a chapter should advance the saved chapter ID", failures)
	var restored_george := UnitState.from_unit_data(DataRegistry.get_unit_data("george"), Vector2i(0, 0))
	_assert_true(GameState.restore_player_unit_state(restored_george, "george"), "George should be restorable from roster state", failures)
	_assert_true(restored_george.get_current_hp() == 9, "restored HP should match the saved state", failures)
	_assert_true(restored_george.xp == 35, "restored XP should match the saved state", failures)
	_assert_true(restored_george.get_equipped_weapon_uses() == 31, "restored weapon durability should match the saved state", failures)
	_assert_true(not restored_george.has_item("health_potion"), "consumed items should stay consumed after restoration", failures)
	var restored_ember := UnitState.from_unit_data(DataRegistry.get_unit_data("ember"), Vector2i(0, 0))
	_assert_true(GameState.restore_player_unit_state(restored_ember, "ember"), "recruited units should restore into later chapters", failures)
	_assert_true(restored_ember.get_current_hp() == 4, "restored recruit HP should match the saved state", failures)
	var bram := UnitState.from_unit_data(DataRegistry.get_unit_data("bram"), Vector2i(0, 0))
	_assert_true(not GameState.restore_player_unit_state(bram, "bram"), "units absent from the persisted roster should not auto-spawn", failures)
	return failures


func _assert_true(condition: bool, message: String, failures: PackedStringArray) -> void:
	if not condition:
		failures.append(message)
