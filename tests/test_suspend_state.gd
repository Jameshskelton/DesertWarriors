extends RefCounted


func run() -> PackedStringArray:
	var failures := PackedStringArray()
	DataRegistry.reload_all()
	GameState.reset_runtime()
	var george := UnitState.from_unit_data(DataRegistry.get_unit_data("george"), Vector2i(2, 7))
	george.set_current_hp(11)
	george.moved = true
	george.acted = true
	george.item_uses[0] = 19
	george.consume_item_use(george.find_item_index("health_potion"))
	var george_state: Dictionary = george.to_battle_state()
	var restored_george: UnitState = UnitState.from_battle_state(george_state)
	_assert_true(restored_george != null, "player battle state should restore", failures)
	if restored_george != null:
		_assert_true(restored_george.get_current_hp() == 11, "restored player HP should match the suspend snapshot", failures)
		_assert_true(restored_george.get_equipped_weapon_uses() == 19, "restored weapon durability should match the suspend snapshot", failures)
		_assert_true(not restored_george.has_item("health_potion"), "consumed items should remain consumed in suspend restore", failures)
		_assert_true(restored_george.moved and restored_george.acted, "turn-state flags should survive suspend restore", failures)
	var knight := UnitState.from_unit_data(DataRegistry.get_unit_data("knight"), Vector2i(13, 4), "enemy")
	knight.unit_id = "silverguard_1"
	var knight_state: Dictionary = knight.to_battle_state()
	var restored_knight: UnitState = UnitState.from_battle_state(knight_state)
	_assert_true(restored_knight != null, "enemy battle state should restore", failures)
	if restored_knight != null:
		_assert_true(restored_knight.unit_id == "silverguard_1", "enemy runtime instance ids should survive suspend restore", failures)
		_assert_true(restored_knight.base_unit_id == "knight", "enemy base unit ids should survive suspend restore", failures)
	GameState.set_suspend_state({
		"chapter_id": "chapter_2",
		"turn_number": 3,
		"phase": "player",
		"units": [george_state, knight_state],
	})
	_assert_true(GameState.has_suspend_state_for_chapter("chapter_2"), "suspend state should be tracked for the saved chapter", failures)
	GameState.clear_suspend_state()
	_assert_true(not GameState.has_suspend_state(), "clearing suspend state should remove the saved battle snapshot", failures)
	return failures


func _assert_true(condition: bool, message: String, failures: PackedStringArray) -> void:
	if not condition:
		failures.append(message)
