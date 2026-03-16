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
	var shopper := UnitState.from_unit_data(DataRegistry.get_unit_data("george"), Vector2i(0, 0))
	var starting_potions: int = shopper.get_available_item_count("health_potion")
	shopper.add_item("health_potion")
	_assert_true(shopper.get_available_item_count("health_potion") == starting_potions + 1, "buying an item should add it to the unit inventory", failures)
	shopper.add_equipped_weapon("steel_sword")
	_assert_true(shopper.get_equipped_weapon_id() == "steel_sword", "buying an upgraded weapon should make it the equipped weapon", failures)
	GameState.reset_runtime()
	GameState.add_gold(15)
	_assert_true(GameState.spend_gold(10), "shared gold should be spendable for shop purchases", failures)
	_assert_true(GameState.gold == 5, "spending gold should reduce the shared total", failures)
	_assert_true(not GameState.spend_gold(10), "shop purchases should fail when the party cannot afford them", failures)
	return failures


func _assert_true(condition: bool, message: String, failures: PackedStringArray) -> void:
	if not condition:
		failures.append(message)
