extends RefCounted


func run() -> PackedStringArray:
	var failures := PackedStringArray()
	var item_service := ItemService.new()
	DataRegistry.reload_all()
	var george := UnitState.from_unit_data(DataRegistry.get_unit_data("george"), Vector2i(0, 0))
	_assert_true(george.has_item("health_potion"), "units should start with a health potion", failures)
	_assert_true(not item_service.can_use_any_item(george), "full-health units should not be able to use a potion", failures)
	george.set_current_hp(8)
	_assert_true(item_service.can_use_any_item(george), "wounded units should be able to use a potion", failures)
	var outcome: Dictionary = item_service.use_first_item(george)
	_assert_true(int(outcome.get("heal_amount", 0)) == 10, "health potion should restore 10 HP", failures)
	_assert_true(george.get_current_hp() == 18, "health potion should heal George back to full HP in the test case", failures)
	_assert_true(not george.has_item("health_potion"), "health potion should be removed after use", failures)
	_assert_true(george.get_equipped_weapon_id() == "bronze_sword", "using a potion should not unequip the weapon", failures)
	return failures


func _assert_true(condition: bool, message: String, failures: PackedStringArray) -> void:
	if not condition:
		failures.append(message)
