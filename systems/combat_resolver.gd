extends RefCounted
class_name CombatResolver

const WEAPON_TRIANGLE := {
	"sword": {"advantage": "axe", "disadvantage": "lance"},
	"axe": {"advantage": "lance", "disadvantage": "sword"},
	"lance": {"advantage": "sword", "disadvantage": "axe"},
}


func can_unit_attack_from_tile(attacker: UnitState, defender: UnitState, tile: Vector2i) -> bool:
	if not attacker.is_alive() or not defender.is_alive():
		return false
	if attacker.is_allied_with(defender.faction):
		return false
	var weapon: WeaponData = _get_usable_weapon(attacker)
	if weapon == null or weapon.weapon_type == "staff":
		return false
	var distance := absi(tile.x - defender.position.x) + absi(tile.y - defender.position.y)
	return distance >= weapon.min_range and distance <= weapon.max_range


func can_unit_heal_from_tile(healer: UnitState, target: UnitState, tile: Vector2i) -> bool:
	if not healer.is_allied_with(target.faction) or not healer.is_alive() or not target.is_alive():
		return false
	var weapon: WeaponData = _get_usable_weapon(healer)
	if weapon == null or weapon.weapon_type != "staff":
		return false
	var distance := absi(tile.x - target.position.x) + absi(tile.y - target.position.y)
	return distance >= weapon.min_range and distance <= weapon.max_range and target.get_current_hp() < target.get_max_hp()


func build_forecast(attacker: UnitState, defender: UnitState, attacker_terrain: TerrainData, defender_terrain: TerrainData) -> CombatForecast:
	return build_forecast_for_tile(attacker, defender, attacker.position, attacker_terrain, defender_terrain)


func build_forecast_for_tile(attacker: UnitState, defender: UnitState, attacker_tile: Vector2i, attacker_terrain: TerrainData, defender_terrain: TerrainData) -> CombatForecast:
	var forecast := CombatForecast.new()
	var attacker_weapon: WeaponData = _get_usable_weapon(attacker)
	var defender_weapon: WeaponData = _get_usable_weapon(defender)
	if attacker_weapon == null or attacker_weapon.weapon_type == "staff":
		return forecast
	forecast.attacker_triangle_state = get_triangle_state(attacker_weapon.weapon_type, _get_weapon_type(defender_weapon))
	forecast.attacker_triangle_text = get_triangle_text(forecast.attacker_triangle_state)
	forecast.defender_triangle_state = get_triangle_state(_get_weapon_type(defender_weapon), attacker_weapon.weapon_type)
	forecast.defender_triangle_text = get_triangle_text(forecast.defender_triangle_state)
	forecast.attacker_damage = _calculate_damage(attacker, defender, attacker_weapon, defender_terrain)
	forecast.attacker_hit = _calculate_hit(attacker, defender, attacker_weapon, defender_terrain)
	forecast.attacker_crit = _calculate_crit(attacker, defender, attacker_weapon)
	forecast.counter_allowed = _can_counter_for_tiles(attacker_tile, defender.position, defender_weapon)
	if forecast.counter_allowed:
		forecast.defender_damage = _calculate_damage(defender, attacker, defender_weapon, attacker_terrain)
		forecast.defender_hit = _calculate_hit(defender, attacker, defender_weapon, attacker_terrain)
		forecast.defender_crit = _calculate_crit(defender, attacker, defender_weapon)
	forecast.attacker_follow_up = _attack_speed(attacker, attacker_weapon) - _attack_speed(defender, defender_weapon) >= 4
	forecast.defender_follow_up = forecast.counter_allowed and _attack_speed(defender, defender_weapon) - _attack_speed(attacker, attacker_weapon) >= 4
	return forecast


func resolve_battle(attacker: UnitState, defender: UnitState, attacker_terrain: TerrainData, defender_terrain: TerrainData) -> BattleResult:
	var result := BattleResult.new()
	if attacker == null or defender == null or attacker.is_allied_with(defender.faction):
		return result
	var attacker_weapon: WeaponData = _get_usable_weapon(attacker)
	if attacker_weapon == null or attacker_weapon.weapon_type == "staff":
		return result
	var forecast := build_forecast(attacker, defender, attacker_terrain, defender_terrain)
	var sequence: Array[Dictionary] = []
	sequence.append({"source": attacker, "target": defender, "damage": forecast.attacker_damage, "hit": forecast.attacker_hit, "crit": forecast.attacker_crit})
	if forecast.counter_allowed:
		sequence.append({"source": defender, "target": attacker, "damage": forecast.defender_damage, "hit": forecast.defender_hit, "crit": forecast.defender_crit})
	if forecast.attacker_follow_up and attacker.is_alive() and defender.is_alive():
		sequence.append({"source": attacker, "target": defender, "damage": forecast.attacker_damage, "hit": forecast.attacker_hit, "crit": forecast.attacker_crit})
	elif forecast.defender_follow_up and attacker.is_alive() and defender.is_alive():
		sequence.append({"source": defender, "target": attacker, "damage": forecast.defender_damage, "hit": forecast.defender_hit, "crit": forecast.defender_crit})
	for strike in sequence:
		var source: UnitState = strike["source"]
		var target: UnitState = strike["target"]
		if not source.is_alive() or not target.is_alive() or not source.has_usable_equipped_weapon():
			continue
		var weapon_id: String = source.get_equipped_weapon_id()
		var weapon_name: String = weapon_id
		var weapon_uses_before: int = source.get_equipped_weapon_uses()
		var source_weapon: WeaponData = DataRegistry.get_weapon_data(weapon_id)
		if source_weapon != null:
			weapon_name = source_weapon.name
		var triangle_state: int = get_triangle_state(_get_weapon_type(source_weapon), _get_target_weapon_type(target))
		var triangle_text: String = get_triangle_text(triangle_state)
		if not source.consume_equipped_weapon_use():
			continue
		var weapon_broke: bool = weapon_uses_before == 1
		var did_hit := GameState.roll_percent(float(strike["hit"]))
		var damage := 0
		var did_crit := false
		if did_hit:
			did_crit = GameState.roll_percent(float(strike["crit"]))
			damage = int(strike["damage"]) * (3 if did_crit else 1)
			target.set_current_hp(target.get_current_hp() - damage)
		result.strikes.append({
			"attacker_name": source.display_name,
			"defender_name": target.display_name,
			"damage": damage,
			"hit": did_hit,
			"crit": did_crit,
			"weapon_name": weapon_name,
			"weapon_type": _get_weapon_type(source_weapon),
			"weapon_broke": weapon_broke,
			"triangle_state": triangle_state,
			"triangle_text": triangle_text,
			"target_hp": target.get_current_hp(),
			"target_max_hp": target.get_max_hp(),
		})
	result.attacker_ko = not attacker.is_alive()
	result.defender_ko = not defender.is_alive()
	_award_gold(attacker, defender, result)
	_update_xp(attacker, defender, result)
	result.attacker_hp_delta = attacker.get_current_hp()
	result.defender_hp_delta = defender.get_current_hp()
	return result


func resolve_staff(user: UnitState, target: UnitState) -> Dictionary:
	if user == null or target == null or not user.is_allied_with(target.faction):
		return {}
	var weapon: WeaponData = _get_usable_weapon(user)
	if weapon == null or weapon.weapon_type != "staff":
		return {}
	var weapon_name: String = weapon.name
	var weapon_broke: bool = user.get_equipped_weapon_uses() == 1
	var xp_awarded: int = 15
	if not user.consume_equipped_weapon_use():
		return {}
	var heal_amount: int = int(weapon.heal_power) + int(user.stats.get("mag", 0))
	var previous_hp := target.get_current_hp()
	target.set_current_hp(target.get_current_hp() + heal_amount)
	var actual_heal := target.get_current_hp() - previous_hp
	var level_up := _grant_xp(user, xp_awarded)
	return {
		"heal_amount": actual_heal,
		"target_name": target.display_name,
		"user_name": user.display_name,
		"xp_awarded": xp_awarded,
		"weapon_name": weapon_name,
		"weapon_broke": weapon_broke,
		"level_up": level_up,
	}


func _update_xp(attacker: UnitState, defender: UnitState, result: BattleResult) -> void:
	var attacker_xp := 10
	if result.defender_ko:
		attacker_xp += 20
	var defender_xp := 0
	if result.attacker_ko:
		defender_xp += 20
	var attacker_level_up := _grant_xp(attacker, attacker_xp)
	var defender_level_up := _grant_xp(defender, defender_xp)
	result.xp_awards = {
		attacker.unit_id: attacker_xp,
		defender.unit_id: defender_xp,
	}
	if not attacker_level_up.is_empty():
		result.level_ups.append(attacker_level_up)
	if not defender_level_up.is_empty():
		result.level_ups.append(defender_level_up)


func _award_gold(attacker: UnitState, defender: UnitState, result: BattleResult) -> void:
	for unit in [attacker, defender]:
		if unit == null or unit.faction != "enemy" or unit.is_alive():
			continue
		result.gold_awarded += unit.get_gold_drop()
		result.gold_sources.append(unit.display_name)


func _grant_xp(unit: UnitState, amount: int) -> Dictionary:
	if amount <= 0 or not unit.is_player_controlled():
		return {}
	var previous_level: int = unit.level
	unit.xp += amount
	if unit.xp < 100:
		return {}
	unit.xp -= 100
	unit.level += 1
	var class_data: ClassData = DataRegistry.get_class_data(unit.class_id)
	if class_data == null:
		return {}
	var gains: Dictionary = {}
	for stat_name in class_data.growth_rates.keys():
		var growth := int(class_data.growth_rates[stat_name])
		if GameState.roll_percent(growth):
			var old_value := int(unit.stats.get(stat_name, 0))
			unit.stats[stat_name] = old_value + 1
			gains[stat_name] = 1
			if stat_name == "max_hp":
				unit.set_current_hp(unit.get_current_hp() + 1)
	return {
		"unit_id": unit.base_unit_id if not unit.base_unit_id.is_empty() else unit.unit_id,
		"unit_name": unit.display_name,
		"portrait_id": unit.portrait_id,
		"class_id": unit.class_id,
		"previous_level": previous_level,
		"level": unit.level,
		"gains": gains,
	}


func _can_counter(attacker: UnitState, defender: UnitState, defender_weapon: WeaponData) -> bool:
	return _can_counter_for_tiles(attacker.position, defender.position, defender_weapon)


func _can_counter_for_tiles(attacker_tile: Vector2i, defender_tile: Vector2i, defender_weapon: WeaponData) -> bool:
	if defender_weapon == null or defender_weapon.weapon_type == "staff":
		return false
	var distance := absi(attacker_tile.x - defender_tile.x) + absi(attacker_tile.y - defender_tile.y)
	return distance >= defender_weapon.min_range and distance <= defender_weapon.max_range


func _calculate_damage(attacker: UnitState, defender: UnitState, weapon: WeaponData, target_terrain: TerrainData) -> int:
	if weapon == null:
		return 0
	var attack_stat := "mag" if weapon.damage_type == "magic" else "str"
	var defense_stat := "res" if weapon.damage_type == "magic" else "def"
	var triangle_damage := _triangle_bonus_damage(weapon.weapon_type, _get_target_weapon_type(defender))
	var raw := int(attacker.stats.get(attack_stat, 0)) + weapon.might + triangle_damage
	var terrain_def := 0 if target_terrain == null else target_terrain.def_bonus
	var reduced := int(defender.stats.get(defense_stat, 0)) + terrain_def
	return maxi(0, raw - reduced)


func _calculate_hit(attacker: UnitState, defender: UnitState, weapon: WeaponData, target_terrain: TerrainData) -> int:
	if weapon == null:
		return 0
	var triangle_hit := _triangle_bonus_hit(weapon.weapon_type, _get_target_weapon_type(defender))
	var hit_value := weapon.hit + int(attacker.stats.get("skl", 0)) * 2 + int(int(attacker.stats.get("lck", 0)) / 2) + triangle_hit
	var terrain_avoid := 0 if target_terrain == null else target_terrain.avoid_bonus
	var avoid := int(defender.stats.get("spd", 0)) * 2 + int(defender.stats.get("lck", 0)) + terrain_avoid
	return clampi(hit_value - avoid, 0, 100)


func _calculate_crit(attacker: UnitState, defender: UnitState, weapon: WeaponData) -> int:
	if weapon == null:
		return 0
	var crit_value := weapon.crit + int(int(attacker.stats.get("skl", 0)) / 2) - int(defender.stats.get("lck", 0))
	return clampi(crit_value, 0, 100)


func _attack_speed(unit: UnitState, weapon: WeaponData) -> int:
	if weapon == null:
		return int(unit.stats.get("spd", 0))
	return int(unit.stats.get("spd", 0)) - maxi(0, weapon.weight - int(unit.stats.get("str", 0)))


func _get_target_weapon_type(unit: UnitState) -> String:
	var weapon: WeaponData = _get_usable_weapon(unit)
	return _get_weapon_type(weapon)


func _get_weapon_type(weapon: WeaponData) -> String:
	if weapon == null:
		return "neutral"
	return weapon.weapon_type


func _get_usable_weapon(unit: UnitState) -> WeaponData:
	if unit == null or not unit.has_usable_equipped_weapon():
		return null
	var weapon_id: String = unit.get_equipped_weapon_id()
	if weapon_id.is_empty():
		return null
	return DataRegistry.get_weapon_data(weapon_id)


func _triangle_bonus_hit(attacker_type: String, defender_type: String) -> int:
	var triangle_state: int = get_triangle_state(attacker_type, defender_type)
	if triangle_state > 0:
		return 15
	if triangle_state < 0:
		return -15
	return 0


func _triangle_bonus_damage(attacker_type: String, defender_type: String) -> int:
	var triangle_state: int = get_triangle_state(attacker_type, defender_type)
	if triangle_state > 0:
		return 1
	if triangle_state < 0:
		return -1
	return 0


func get_triangle_state(attacker_type: String, defender_type: String) -> int:
	if not WEAPON_TRIANGLE.has(attacker_type):
		return 0
	if WEAPON_TRIANGLE[attacker_type]["advantage"] == defender_type:
		return 1
	if WEAPON_TRIANGLE[attacker_type]["disadvantage"] == defender_type:
		return -1
	return 0


func get_triangle_text(triangle_state: int) -> String:
	if triangle_state > 0:
		return "Weapon Advantage"
	if triangle_state < 0:
		return "Weapon Disadvantage"
	return ""
