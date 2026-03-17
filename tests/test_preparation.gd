extends RefCounted


func run() -> PackedStringArray:
	var failures := PackedStringArray()
	DataRegistry.reload_all()
	GameState.start_new_game(false)
	var prep_units: Array[UnitState] = GameState.build_preparation_roster("chapter_1")
	_assert_true(prep_units.size() >= 3, "chapter 1 preparation should include the starting roster", failures)
	var george: UnitState = _find_unit(prep_units, "george")
	var bram: UnitState = _find_unit(prep_units, "bram")
	_assert_true(george != null and bram != null, "George and Bram should both be present in chapter 1 preparation", failures)
	if george == null or bram == null:
		return failures
	george.add_equipped_weapon("steel_sword", 40)
	_assert_true(george.get_equipped_weapon_id() == "steel_sword", "newly added weapon should become equipped before reordering", failures)
	_assert_true(george.move_item(1, 0), "moving an inventory item should succeed for a valid reorder", failures)
	_assert_true(george.get_equipped_weapon_id() == "bronze_sword", "reordering weapons should change which weapon is equipped", failures)
	var potion_index: int = george.find_item_index("health_potion")
	_assert_true(george.transfer_item_to(potion_index, bram), "usable consumables should transfer between allied units", failures)
	_assert_true(not george.has_item("health_potion"), "source unit should lose transferred items", failures)
	_assert_true(bram.get_available_item_count("health_potion") >= 2, "target unit should gain transferred consumables", failures)
	_assert_true(not george.transfer_item_to(0, bram), "units should not hand off weapons the receiver cannot use", failures)
	GameState.store_preparation_roster(prep_units)
	var restored_george := UnitState.from_unit_data(DataRegistry.get_unit_data("george"), Vector2i.ZERO)
	_assert_true(GameState.restore_player_unit_state(restored_george, "george"), "stored preparation changes should persist into roster state", failures)
	_assert_true(restored_george.get_equipped_weapon_id() == "bronze_sword", "restored roster state should keep the selected equipped weapon", failures)
	return failures


func _find_unit(units: Array[UnitState], unit_id: String) -> UnitState:
	for unit in units:
		if unit != null and unit.unit_id == unit_id:
			return unit
	return null


func _assert_true(condition: bool, message: String, failures: PackedStringArray) -> void:
	if not condition:
		failures.append(message)
