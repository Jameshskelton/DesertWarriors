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
	var steel_sword_index: int = george.find_item_index("steel_sword")
	_assert_true(steel_sword_index != -1, "George should still be carrying the stored test weapon", failures)
	if steel_sword_index != -1:
		var convoy_item: Dictionary = george.extract_item_at(steel_sword_index)
		GameState.add_convoy_item(str(convoy_item.get("item_id", "")), int(convoy_item.get("uses", 0)))
		_assert_true(not george.has_item("steel_sword"), "moving an item into the convoy should remove it from the unit inventory", failures)
		_assert_true(GameState.get_convoy_items().size() == 1, "convoy storage should record deposited items", failures)
		var withdrawn_item: Dictionary = GameState.remove_convoy_item(0)
		george.add_item(str(withdrawn_item.get("item_id", "")), int(withdrawn_item.get("uses", 0)))
		_assert_true(george.has_item("steel_sword"), "items withdrawn from convoy should return to the unit inventory", failures)
		_assert_true(GameState.get_convoy_items().is_empty(), "withdrawing a convoy item should remove it from storage", failures)
	var deployment_slots: Array[Vector2i] = GameState.get_chapter_deployment_slots("chapter_1")
	_assert_true(deployment_slots.size() >= 2, "chapter 1 should expose deployment slots for preparation", failures)
	var deployment_assignments: Dictionary = GameState.build_preparation_assignments("chapter_1", prep_units)
	_assert_true(deployment_assignments.has("george"), "George should receive a deployment assignment in preparation", failures)
	if deployment_slots.size() >= 2:
		deployment_assignments["george"] = {"x": deployment_slots[1].x, "y": deployment_slots[1].y}
		deployment_assignments["bram"] = {"x": deployment_slots[0].x, "y": deployment_slots[0].y}
	GameState.store_preparation_assignments("chapter_1", deployment_assignments, prep_units)
	GameState.store_preparation_roster(prep_units)
	var restored_george := UnitState.from_unit_data(DataRegistry.get_unit_data("george"), Vector2i.ZERO)
	_assert_true(GameState.restore_player_unit_state(restored_george, "george"), "stored preparation changes should persist into roster state", failures)
	_assert_true(restored_george.get_equipped_weapon_id() == "bronze_sword", "restored roster state should keep the selected equipped weapon", failures)
	if deployment_slots.size() >= 2:
		var george_slot: Vector2i = GameState.resolve_preparation_position("chapter_1", "george", deployment_slots[0])
		var bram_slot: Vector2i = GameState.resolve_preparation_position("chapter_1", "bram", deployment_slots[1])
		_assert_true(george_slot == deployment_slots[1], "stored preparation deployment should move George to his chosen slot", failures)
		_assert_true(bram_slot == deployment_slots[0], "stored preparation deployment should swap Bram into the vacated slot", failures)
	var chapter_1: ChapterData = DataRegistry.get_chapter_data("chapter_1")
	var original_deployment_limit: int = int(chapter_1.deployment_unit_limit)
	var original_preparation_assignments: Dictionary = GameState.preparation_assignments.duplicate(true)
	chapter_1.deployment_unit_limit = 2
	var limited_slots: Array[Vector2i] = GameState.get_chapter_deployment_slots("chapter_1")
	_assert_true(limited_slots.size() == 2, "deployment_unit_limit should cap available deployment slots when set", failures)
	var limited_assignments: Dictionary = GameState.build_preparation_assignments("chapter_1", prep_units)
	_assert_true(limited_assignments.size() == 2, "limited deployment chapters should bench extra allies in preparation", failures)
	GameState.store_preparation_assignments("chapter_1", limited_assignments, prep_units)
	var hale_slot: Vector2i = GameState.resolve_preparation_position("chapter_1", "brother_hale", Vector2i.ZERO)
	_assert_true(hale_slot == Vector2i(-1, -1), "allies beyond the deployment limit should resolve to the bench", failures)
	chapter_1.deployment_unit_limit = original_deployment_limit
	GameState.preparation_assignments = original_preparation_assignments
	return failures


func _find_unit(units: Array[UnitState], unit_id: String) -> UnitState:
	for unit in units:
		if unit != null and unit.unit_id == unit_id:
			return unit
	return null


func _assert_true(condition: bool, message: String, failures: PackedStringArray) -> void:
	if not condition:
		failures.append(message)
