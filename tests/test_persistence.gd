extends RefCounted


func run() -> PackedStringArray:
	var failures := PackedStringArray()
	DataRegistry.reload_all()
	_run_non_permadeath_persistence_checks(failures)
	_run_permadeath_persistence_checks(failures)
	return failures


func _assert_true(condition: bool, message: String, failures: PackedStringArray) -> void:
	if not condition:
		failures.append(message)


func _run_non_permadeath_persistence_checks(failures: PackedStringArray) -> void:
	GameState.start_new_game(false)
	GameState.add_gold(17)
	GameState.add_convoy_item("steel_sword", 22)
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
	_assert_true(GameState.gold == 17, "shared gold should persist across chapter transitions", failures)
	_assert_true(int(GameState.build_save_payload().get("gold", -1)) == 17, "shared gold should be written into the save payload", failures)
	var convoy_payload: Array = GameState.build_save_payload().get("convoy_items", [])
	_assert_true(convoy_payload.size() == 1, "convoy items should be written into the save payload", failures)
	if convoy_payload.size() == 1 and typeof(convoy_payload[0]) == TYPE_DICTIONARY:
		var convoy_entry: Dictionary = convoy_payload[0]
		_assert_true(str(convoy_entry.get("item_id", "")) == "steel_sword", "convoy payload should preserve item ids", failures)
		_assert_true(int(convoy_entry.get("uses", -1)) == 22, "convoy payload should preserve remaining uses", failures)
	_assert_true(not GameState.permadeath_enabled, "permadeath should stay disabled for the default new game flow", failures)
	_assert_true(GameState.fallen_units.is_empty(), "fallen unit tracking should stay empty when permadeath is off", failures)
	_assert_true(GameState.get_convoy_items().size() == 1, "convoy storage should persist across chapter transitions", failures)
	var restored_george := UnitState.from_unit_data(DataRegistry.get_unit_data("george"), Vector2i(0, 0))
	_assert_true(GameState.restore_player_unit_state(restored_george, "george"), "George should be restorable from roster state", failures)
	_assert_true(restored_george.get_current_hp() == restored_george.get_max_hp(), "restored units should heal to full between chapters", failures)
	_assert_true(restored_george.xp == 35, "restored XP should match the saved state", failures)
	_assert_true(restored_george.get_equipped_weapon_uses() == 31, "restored weapon durability should match the saved state", failures)
	_assert_true(not restored_george.has_item("health_potion"), "consumed items should stay consumed after restoration", failures)
	var restored_ember := UnitState.from_unit_data(DataRegistry.get_unit_data("ember"), Vector2i(0, 0))
	_assert_true(GameState.restore_player_unit_state(restored_ember, "ember"), "recruited units should restore into later chapters", failures)
	_assert_true(restored_ember.get_current_hp() == restored_ember.get_max_hp(), "restored recruits should also heal to full between chapters", failures)
	var bram := UnitState.from_unit_data(DataRegistry.get_unit_data("bram"), Vector2i(0, 0))
	_assert_true(not GameState.restore_player_unit_state(bram, "bram"), "units absent from the persisted roster should not auto-spawn", failures)
	var balt := UnitState.from_unit_data(DataRegistry.get_unit_data("balt"), Vector2i(19, 2))
	_assert_true(GameState.restore_player_unit_state(balt, "balt", true), "explicit join events should allow new player units to spawn even if they are not yet in the roster", failures)
	_assert_true(balt.get_current_hp() == balt.get_max_hp(), "newly joined units should keep their default chapter-start HP", failures)


func _run_permadeath_persistence_checks(failures: PackedStringArray) -> void:
	GameState.start_new_game(true)
	var george := UnitState.from_unit_data(DataRegistry.get_unit_data("george"), Vector2i(0, 0))
	george.set_current_hp(3)
	george.xp = 12
	var ember := UnitState.from_unit_data(DataRegistry.get_unit_data("ember"), Vector2i(0, 0))
	ember.set_current_hp(0)
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
	_assert_true(GameState.permadeath_enabled, "permadeath choice should persist for the campaign state", failures)
	_assert_true(GameState.fallen_units.has("ember"), "dead player units should be tracked as fallen when permadeath is enabled", failures)
	_assert_true(not GameState.roster_state.has("ember"), "fallen units should be removed from the persistent roster", failures)
	var restored_george := UnitState.from_unit_data(DataRegistry.get_unit_data("george"), Vector2i(0, 0))
	_assert_true(GameState.restore_player_unit_state(restored_george, "george"), "living units should still restore when permadeath is enabled", failures)
	_assert_true(restored_george.get_current_hp() == restored_george.get_max_hp(), "surviving units should still heal between chapters", failures)
	var restored_ember := UnitState.from_unit_data(DataRegistry.get_unit_data("ember"), Vector2i(0, 0))
	_assert_true(not GameState.restore_player_unit_state(restored_ember, "ember"), "fallen units should not return in later chapters when permadeath is enabled", failures)
	var balt := UnitState.from_unit_data(DataRegistry.get_unit_data("balt"), Vector2i(19, 2))
	_assert_true(GameState.restore_player_unit_state(balt, "balt", true), "new join events should still be allowed for units who have not fallen", failures)
