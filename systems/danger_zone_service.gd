extends RefCounted
class_name DangerZoneService

var _grid: GridService = GridService.new()
var _pathfinding: PathfindingService = PathfindingService.new()


func build_enemy_threat_tiles(units: Array[UnitState], terrain_grid: Array) -> Dictionary:
	return build_threat_tiles_for_faction(units, terrain_grid, "enemy")


func build_threat_tiles_for_faction(units: Array[UnitState], terrain_grid: Array, threat_faction: String) -> Dictionary:
	var threatened_tiles: Dictionary = {}
	if terrain_grid.is_empty() or terrain_grid[0].is_empty():
		return threatened_tiles
	var grid_size: Vector2i = Vector2i(terrain_grid[0].size(), terrain_grid.size())
	for unit in units:
		if unit == null or unit.faction != threat_faction or not unit.is_alive() or not unit.has_joined:
			continue
		var weapon: WeaponData = DataRegistry.get_weapon_data(unit.get_equipped_weapon_id())
		if weapon == null or weapon.weapon_type == "staff" or unit.get_equipped_weapon_uses() <= 0:
			continue
		var class_data: ClassData = DataRegistry.get_class_data(unit.class_id)
		if class_data == null:
			continue
		var occupied_tiles: Dictionary = _build_occupied_lookup(units, unit)
		var reachable: Dictionary = _pathfinding.compute_reachable(
			unit.position,
			class_data.move_range,
			terrain_grid,
			class_data.move_type,
			occupied_tiles,
			unit.faction
		)
		for tile_value in reachable.get("costs", {}).keys():
			var origin: Vector2i = tile_value
			_add_attack_tiles_from_origin(threatened_tiles, origin, weapon.min_range, weapon.max_range, grid_size)
	return threatened_tiles


func _build_occupied_lookup(units: Array[UnitState], excluded: UnitState) -> Dictionary:
	var occupied_tiles: Dictionary = {}
	for unit in units:
		if unit == null or unit == excluded or not unit.is_alive() or not unit.has_joined:
			continue
		occupied_tiles[unit.position] = unit
	return occupied_tiles


func _add_attack_tiles_from_origin(threatened_tiles: Dictionary, origin: Vector2i, min_range: int, max_range: int, grid_size: Vector2i) -> void:
	for y in range(grid_size.y):
		for x in range(grid_size.x):
			var tile := Vector2i(x, y)
			var distance: int = _grid.manhattan(origin, tile)
			if distance < min_range or distance > max_range:
				continue
			threatened_tiles[tile] = int(threatened_tiles.get(tile, 0)) + 1
