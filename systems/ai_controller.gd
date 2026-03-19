extends RefCounted
class_name AIController

var _grid := GridService.new()
var _pathfinding := PathfindingService.new()
var _combat := CombatResolver.new()


func choose_action(enemy: UnitState, units: Array[UnitState], terrain_grid: Array) -> Dictionary:
	var hostile_units: Array[UnitState] = []
	var occupied: Dictionary = {}
	for unit in units:
		if not unit.is_alive():
			continue
		occupied[unit.position] = unit
		if unit.is_hostile_to(enemy.faction):
			hostile_units.append(unit)
	if hostile_units.is_empty():
		return {"type": "wait"}
	if enemy.ai_profile == "castle_guard":
		return _choose_castle_guard_action(enemy, hostile_units)
	var enemy_class: ClassData = DataRegistry.get_class_data(enemy.class_id)
	var reachable := _pathfinding.compute_reachable(
		enemy.position,
		enemy_class.move_range,
		terrain_grid,
		enemy_class.move_type,
		occupied,
		enemy.faction
	)
	if GameState.is_easy_difficulty():
		return _choose_easy_action(enemy, hostile_units, reachable)
	var best_attack: Dictionary = {}
	for tile in reachable.get("costs", {}).keys():
		for hostile_unit in hostile_units:
			if not _combat.can_unit_attack_from_tile(enemy, hostile_unit, tile):
				continue
			var score := _score_attack(enemy, hostile_unit)
			if best_attack.is_empty() or score > best_attack.get("score", -999):
				best_attack = {
					"type": "move_attack",
					"score": score,
					"destination": tile,
					"target": hostile_unit,
					"path": _pathfinding.build_path(enemy.position, tile, reachable),
				}
	if not best_attack.is_empty():
		return best_attack
	var nearest := hostile_units[0]
	var nearest_distance := _grid.manhattan(enemy.position, nearest.position)
	for hostile_unit in hostile_units:
		var distance := _grid.manhattan(enemy.position, hostile_unit.position)
		if distance < nearest_distance:
			nearest = hostile_unit
			nearest_distance = distance
	var best_tile := enemy.position
	var best_distance := nearest_distance
	for tile in reachable.get("costs", {}).keys():
		var distance := _grid.manhattan(tile, nearest.position)
		if distance < best_distance:
			best_distance = distance
			best_tile = tile
	return {
		"type": "move_wait",
		"destination": best_tile,
		"path": _pathfinding.build_path(enemy.position, best_tile, reachable),
	}


func _choose_easy_action(enemy: UnitState, hostile_units: Array[UnitState], reachable: Dictionary) -> Dictionary:
	var nearest: UnitState = _find_nearest_hostile(enemy, hostile_units)
	if nearest == null:
		return {"type": "wait"}
	if _combat.can_unit_attack_from_tile(enemy, nearest, enemy.position):
		return {
			"type": "move_attack",
			"destination": enemy.position,
			"target": nearest,
			"path": [enemy.position],
		}
	var reachable_costs: Dictionary = reachable.get("costs", {})
	var best_attack_tile: Vector2i = enemy.position
	var best_attack_cost: int = 999999
	var best_attack_distance: int = 999999
	for tile_value in reachable_costs.keys():
		var tile: Vector2i = tile_value
		if not _combat.can_unit_attack_from_tile(enemy, nearest, tile):
			continue
		var path_cost: int = int(reachable_costs.get(tile_value, 999999))
		var tile_distance: int = _grid.manhattan(tile, nearest.position)
		if path_cost < best_attack_cost or (path_cost == best_attack_cost and tile_distance < best_attack_distance):
			best_attack_tile = tile
			best_attack_cost = path_cost
			best_attack_distance = tile_distance
	if best_attack_cost < 999999:
		return {
			"type": "move_attack",
			"destination": best_attack_tile,
			"target": nearest,
			"path": _pathfinding.build_path(enemy.position, best_attack_tile, reachable),
		}
	var best_tile: Vector2i = enemy.position
	var best_distance: int = _grid.manhattan(enemy.position, nearest.position)
	var best_move_cost: int = 999999
	for tile_value in reachable_costs.keys():
		var tile: Vector2i = tile_value
		var distance: int = _grid.manhattan(tile, nearest.position)
		var move_cost: int = int(reachable_costs.get(tile_value, 999999))
		if distance < best_distance or (distance == best_distance and move_cost < best_move_cost):
			best_distance = distance
			best_move_cost = move_cost
			best_tile = tile
	return {
		"type": "move_wait",
		"destination": best_tile,
		"path": _pathfinding.build_path(enemy.position, best_tile, reachable),
	}


func _choose_castle_guard_action(enemy: UnitState, hostile_units: Array[UnitState]) -> Dictionary:
	var best_attack: Dictionary = {}
	for hostile_unit in hostile_units:
		if not _combat.can_unit_attack_from_tile(enemy, hostile_unit, enemy.position):
			continue
		var score: int = _score_attack(enemy, hostile_unit)
		if best_attack.is_empty() or score > best_attack.get("score", -999):
			best_attack = {
				"type": "move_attack",
				"score": score,
				"destination": enemy.position,
				"target": hostile_unit,
				"path": [enemy.position],
			}
	if not best_attack.is_empty():
		return best_attack
	return {
		"type": "move_wait",
		"destination": enemy.position,
		"path": [enemy.position],
	}


func _find_nearest_hostile(enemy: UnitState, hostile_units: Array[UnitState]) -> UnitState:
	if hostile_units.is_empty():
		return null
	var nearest: UnitState = hostile_units[0]
	var nearest_distance: int = _grid.manhattan(enemy.position, nearest.position)
	for hostile_unit in hostile_units:
		var distance: int = _grid.manhattan(enemy.position, hostile_unit.position)
		if distance < nearest_distance:
			nearest = hostile_unit
			nearest_distance = distance
	return nearest


func _score_attack(attacker: UnitState, defender: UnitState) -> int:
	var score: int = 0
	score += max(0, defender.get_max_hp() - defender.get_current_hp())
	if defender.has_flag("vanguard") or defender.unit_id == "george":
		score += 30
	if defender.class_id == "priest":
		score += 10
	return score
