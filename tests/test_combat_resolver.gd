extends RefCounted


func run() -> PackedStringArray:
	var failures := PackedStringArray()
	var resolver := CombatResolver.new()
	DataRegistry.reload_all()
	GameState.reset_runtime()
	var woody := UnitState.from_unit_data(DataRegistry.get_unit_data("woody"), Vector2i(0, 0))
	var brigand := UnitState.from_unit_data(DataRegistry.get_unit_data("brigand_grunt"), Vector2i(0, 1), "enemy")
	var plains: TerrainData = DataRegistry.get_terrain_data("plains")
	var forest: TerrainData = DataRegistry.get_terrain_data("forest")
	var plains_forecast: CombatForecast = resolver.build_forecast(brigand, woody, plains, plains)
	var forest_forecast: CombatForecast = resolver.build_forecast(brigand, woody, plains, forest)
	_assert_true(forest_forecast.attacker_hit < plains_forecast.attacker_hit, "forest should reduce incoming hit chance", failures)
	_assert_true(forest_forecast.attacker_damage <= plains_forecast.attacker_damage, "forest should not increase incoming damage", failures)
	var rowan := UnitState.from_unit_data(DataRegistry.get_unit_data("rowan"), Vector2i(0, 0))
	var pursuer := UnitState.from_unit_data(DataRegistry.get_unit_data("pursuer_armor"), Vector2i(0, 1), "enemy")
	var forecast: CombatForecast = resolver.build_forecast(rowan, pursuer, DataRegistry.get_terrain_data("plains"), DataRegistry.get_terrain_data("plains"))
	_assert_true(forecast.attacker_follow_up, "speed advantage should trigger a follow-up attack", failures)
	var hale := UnitState.from_unit_data(DataRegistry.get_unit_data("brother_hale"), Vector2i(0, 0))
	var wounded_woody := UnitState.from_unit_data(DataRegistry.get_unit_data("woody"), Vector2i(0, 1))
	wounded_woody.set_current_hp(8)
	var outcome: Dictionary = resolver.resolve_staff(hale, wounded_woody)
	_assert_true(int(outcome.get("heal_amount", 0)) > 0, "staff healing should restore HP", failures)
	_assert_true(wounded_woody.get_current_hp() > 8, "healed unit HP should increase", failures)
	_assert_true(hale.xp == 15, "staff use should grant 15 XP", failures)
	return failures


func _assert_true(condition: bool, message: String, failures: PackedStringArray) -> void:
	if not condition:
		failures.append(message)
