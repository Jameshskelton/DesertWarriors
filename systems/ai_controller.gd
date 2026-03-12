extends RefCounted
class_name AIController

var _grid := GridService.new()
var _pathfinding := PathfindingService.new()
var _combat := CombatResolver.new()


func choose_action(enemy: UnitState, units: Array[UnitState], terrain_grid: Array) -> Dictionary:
	var players: Array[UnitState] = []
	var occupied: Dictionary = {}
	for unit in units:
		if not unit.is_alive():
			continue
		occupied[unit.position] = unit
		if unit.faction == "player":
			players.append(unit)
	if players.is_empty():
		return {"type": "wait"}
	var enemy_class: ClassData = DataRegistry.get_class_data(enemy.class_id)
	var reachable := _pathfinding.compute_reachable(
		enemy.position,
		enemy_class.move_range,
		terrain_grid,
		enemy_class.move_type,
		occupied,
		enemy.faction
	)
	var best_attack: Dictionary = {}
	for tile in reachable.get("costs", {}).keys():
		for player in players:
			if not _combat.can_unit_attack_from_tile(enemy, player, tile):
				continue
			var score := _score_attack(enemy, player)
			if best_attack.is_empty() or score > best_attack.get("score", -999):
				best_attack = {
					"type": "move_attack",
					"score": score,
					"destination": tile,
					"target": player,
					"path": _pathfinding.build_path(enemy.position, tile, reachable),
				}
	if not best_attack.is_empty():
		return best_attack
	var nearest := players[0]
	var nearest_distance := _grid.manhattan(enemy.position, nearest.position)
	for player in players:
		var distance := _grid.manhattan(enemy.position, player.position)
		if distance < nearest_distance:
			nearest = player
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


func _score_attack(attacker: UnitState, defender: UnitState) -> int:
	var score: int = 0
	score += max(0, defender.get_max_hp() - defender.get_current_hp())
	if defender.has_flag("lord") or defender.unit_id == "george":
		score += 30
	if defender.class_id == "priest":
		score += 10
	return score
