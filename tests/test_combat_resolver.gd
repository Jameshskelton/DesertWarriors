extends RefCounted


func run() -> PackedStringArray:
	var failures := PackedStringArray()
	var resolver := CombatResolver.new()
	DataRegistry.reload_all()
	GameState.reset_runtime()
	var george := UnitState.from_unit_data(DataRegistry.get_unit_data("george"), Vector2i(0, 0))
	var brigand := UnitState.from_unit_data(DataRegistry.get_unit_data("brigand_grunt"), Vector2i(0, 1), "enemy")
	var plains: TerrainData = DataRegistry.get_terrain_data("plains")
	var forest: TerrainData = DataRegistry.get_terrain_data("forest")
	var plains_forecast: CombatForecast = resolver.build_forecast(brigand, george, plains, plains)
	var forest_forecast: CombatForecast = resolver.build_forecast(brigand, george, plains, forest)
	_assert_true(forest_forecast.attacker_hit < plains_forecast.attacker_hit, "forest should reduce incoming hit chance", failures)
	_assert_true(forest_forecast.attacker_damage <= plains_forecast.attacker_damage, "forest should not increase incoming damage", failures)
	var rowan := UnitState.from_unit_data(DataRegistry.get_unit_data("rowan"), Vector2i(0, 0))
	var pursuer := UnitState.from_unit_data(DataRegistry.get_unit_data("pursuer_armor"), Vector2i(0, 1), "enemy")
	var forecast: CombatForecast = resolver.build_forecast(rowan, pursuer, DataRegistry.get_terrain_data("plains"), DataRegistry.get_terrain_data("plains"))
	_assert_true(forecast.attacker_follow_up, "speed advantage should trigger a follow-up attack", failures)
	var hale := UnitState.from_unit_data(DataRegistry.get_unit_data("brother_hale"), Vector2i(0, 0))
	var wounded_george := UnitState.from_unit_data(DataRegistry.get_unit_data("george"), Vector2i(0, 1))
	wounded_george.set_current_hp(8)
	var outcome: Dictionary = resolver.resolve_staff(hale, wounded_george)
	_assert_true(int(outcome.get("heal_amount", 0)) > 0, "staff healing should restore HP", failures)
	_assert_true(wounded_george.get_current_hp() > 8, "healed unit HP should increase", failures)
	_assert_true(hale.xp == 15, "staff use should grant 15 XP", failures)
	var durable_george := UnitState.from_unit_data(DataRegistry.get_unit_data("george"), Vector2i(0, 0))
	var durable_brigand := UnitState.from_unit_data(DataRegistry.get_unit_data("brigand_grunt"), Vector2i(0, 1), "enemy")
	var george_start_uses: int = durable_george.get_equipped_weapon_uses()
	resolver.resolve_battle(durable_george, durable_brigand, plains, plains)
	_assert_true(durable_george.get_equipped_weapon_uses() == george_start_uses - 1, "attacking should spend one weapon use", failures)
	var fragile_george := UnitState.from_unit_data(DataRegistry.get_unit_data("george"), Vector2i(0, 0))
	var fragile_brigand := UnitState.from_unit_data(DataRegistry.get_unit_data("brigand_grunt"), Vector2i(0, 1), "enemy")
	fragile_george.item_uses[0] = 1
	resolver.resolve_battle(fragile_george, fragile_brigand, plains, plains)
	_assert_true(fragile_george.get_equipped_weapon_id().is_empty(), "weapon should break when its last use is spent", failures)
	var fragile_hale := UnitState.from_unit_data(DataRegistry.get_unit_data("brother_hale"), Vector2i(0, 0))
	var wounded_rowan := UnitState.from_unit_data(DataRegistry.get_unit_data("rowan"), Vector2i(0, 1))
	wounded_rowan.set_current_hp(10)
	fragile_hale.item_uses[0] = 1
	resolver.resolve_staff(fragile_hale, wounded_rowan)
	_assert_true(fragile_hale.get_equipped_weapon_id().is_empty(), "staff should break after its last use", failures)
	return failures


func _assert_true(condition: bool, message: String, failures: PackedStringArray) -> void:
	if not condition:
		failures.append(message)
