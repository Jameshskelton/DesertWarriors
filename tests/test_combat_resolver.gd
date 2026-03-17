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
	_assert_true(str(outcome.get("weapon_name", "")) == "Heal Staff", "staff outcomes should report the weapon used", failures)
	var balt := UnitState.from_unit_data(DataRegistry.get_unit_data("balt"), Vector2i(0, 1))
	var ranged_brigand := UnitState.from_unit_data(DataRegistry.get_unit_data("brigand_grunt"), Vector2i(0, 2), "enemy")
	var ranged_forecast: CombatForecast = resolver.build_forecast_for_tile(balt, ranged_brigand, Vector2i(0, 0), plains, plains)
	_assert_true(not ranged_forecast.counter_allowed, "hypothetical-tile forecasts should respect counter range from the chosen attack tile", failures)
	var durable_george := UnitState.from_unit_data(DataRegistry.get_unit_data("george"), Vector2i(0, 0))
	var durable_brigand := UnitState.from_unit_data(DataRegistry.get_unit_data("brigand_grunt"), Vector2i(0, 1), "enemy")
	var george_start_uses: int = durable_george.get_equipped_weapon_uses()
	resolver.resolve_battle(durable_george, durable_brigand, plains, plains)
	_assert_true(durable_george.get_equipped_weapon_uses() == george_start_uses - 1, "attacking should spend one weapon use", failures)
	var lance_george := UnitState.from_unit_data(DataRegistry.get_unit_data("george"), Vector2i(0, 0))
	lance_george.inventory = PackedStringArray(["iron_lance"])
	lance_george.item_uses.clear()
	lance_george.item_uses.append(45)
	_assert_true(lance_george.get_equipped_weapon_id().is_empty(), "George should not be able to equip lances", failures)
	_assert_true(not resolver.can_unit_attack_from_tile(lance_george, durable_brigand, lance_george.position), "units should not attack with weapons outside their allowed type", failures)
	var sword_bram := UnitState.from_unit_data(DataRegistry.get_unit_data("bram"), Vector2i(0, 0))
	sword_bram.inventory = PackedStringArray(["bronze_sword"])
	sword_bram.item_uses.clear()
	sword_bram.item_uses.append(45)
	_assert_true(sword_bram.get_equipped_weapon_id().is_empty(), "Bram should not be able to equip swords", failures)
	var fragile_george := UnitState.from_unit_data(DataRegistry.get_unit_data("george"), Vector2i(0, 0))
	var fragile_brigand := UnitState.from_unit_data(DataRegistry.get_unit_data("brigand_grunt"), Vector2i(0, 1), "enemy")
	fragile_george.item_uses[0] = 1
	var fragile_result: BattleResult = resolver.resolve_battle(fragile_george, fragile_brigand, plains, plains)
	_assert_true(fragile_george.get_equipped_weapon_id().is_empty(), "weapon should break when its last use is spent", failures)
	_assert_true(not fragile_result.strikes.is_empty() and bool(fragile_result.strikes[0].get("weapon_broke", false)), "battle strikes should note when a weapon breaks", failures)
	var fragile_hale := UnitState.from_unit_data(DataRegistry.get_unit_data("brother_hale"), Vector2i(0, 0))
	var wounded_rowan := UnitState.from_unit_data(DataRegistry.get_unit_data("rowan"), Vector2i(0, 1))
	wounded_rowan.set_current_hp(10)
	fragile_hale.item_uses[0] = 1
	var fragile_staff_outcome: Dictionary = resolver.resolve_staff(fragile_hale, wounded_rowan)
	_assert_true(fragile_hale.get_equipped_weapon_id().is_empty(), "staff should break after its last use", failures)
	_assert_true(bool(fragile_staff_outcome.get("weapon_broke", false)), "staff outcomes should note when the staff breaks", failures)
	var rich_george := UnitState.from_unit_data(DataRegistry.get_unit_data("george"), Vector2i(0, 0))
	rich_george.stats["str"] = 99
	rich_george.stats["skl"] = 99
	rich_george.stats["lck"] = 99
	var doomed_brigand := UnitState.from_unit_data(DataRegistry.get_unit_data("brigand_grunt"), Vector2i(0, 1), "enemy")
	doomed_brigand.set_current_hp(1)
	doomed_brigand.stats["spd"] = 0
	doomed_brigand.stats["lck"] = 0
	var regular_result: BattleResult = resolver.resolve_battle(rich_george, doomed_brigand, plains, plains)
	_assert_true(regular_result.gold_awarded == 5, "regular enemies should award 5 gold on defeat", failures)
	var doomed_captain := UnitState.from_unit_data(DataRegistry.get_unit_data("captain"), Vector2i(0, 1), "enemy")
	doomed_captain.set_current_hp(1)
	doomed_captain.stats["spd"] = 0
	doomed_captain.stats["lck"] = 0
	var miniboss_result: BattleResult = resolver.resolve_battle(rich_george, doomed_captain, plains, plains)
	_assert_true(miniboss_result.gold_awarded == 10, "minibosses should award 10 gold on defeat", failures)
	var doomed_briar := UnitState.from_unit_data(DataRegistry.get_unit_data("captain_briar"), Vector2i(0, 1), "enemy")
	doomed_briar.set_current_hp(1)
	doomed_briar.stats["spd"] = 0
	doomed_briar.stats["lck"] = 0
	var boss_result: BattleResult = resolver.resolve_battle(rich_george, doomed_briar, plains, plains)
	_assert_true(boss_result.gold_awarded == 25, "bosses should award 25 gold on defeat", failures)
	_assert_true(DataRegistry.get_weapon_data("steel_sword") != null, "Steel Sword should be registered as an upgraded hero weapon", failures)
	_assert_true(DataRegistry.get_weapon_data("steel_lance") != null, "Steel Lance should be registered as an upgraded hero weapon", failures)
	_assert_true(DataRegistry.get_weapon_data("steel_bow") != null, "Steel Bow should be registered as an upgraded hero weapon", failures)
	_assert_true(DataRegistry.get_weapon_data("flare_tome") != null, "Flare Tome should be registered as an upgraded hero weapon", failures)
	_assert_true(DataRegistry.get_weapon_data("mend_staff") != null, "Mend Staff should be registered as an upgraded hero weapon", failures)
	return failures


func _assert_true(condition: bool, message: String, failures: PackedStringArray) -> void:
	if not condition:
		failures.append(message)
