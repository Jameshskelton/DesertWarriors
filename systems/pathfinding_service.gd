extends RefCounted
class_name PathfindingService

var _grid: GridService = GridService.new()


func compute_reachable(
	start: Vector2i,
	move_points: int,
	terrain_grid: Array,
	move_type: String,
	occupied_tiles: Dictionary
) -> Dictionary:
	var grid_size: Vector2i = Vector2i(terrain_grid[0].size(), terrain_grid.size())
	var frontier: Array[Vector2i] = [start]
	var cost_so_far: Dictionary = {start: 0}
	var came_from: Dictionary = {start: start}
	var head: int = 0
	while head < frontier.size():
		var current: Vector2i = frontier[head]
		head += 1
		for next_tile in _grid.neighbors(current, grid_size):
			if occupied_tiles.has(next_tile) and next_tile != start:
				continue
			var terrain_id: String = terrain_grid[next_tile.y][next_tile.x]
			var terrain: TerrainData = DataRegistry.get_terrain_data(terrain_id)
			if terrain == null or terrain.is_blocking:
				continue
			var move_cost: int = int(terrain.move_cost_by_type.get(move_type, 99))
			var new_cost: int = int(cost_so_far[current]) + move_cost
			if new_cost > move_points:
				continue
			if not cost_so_far.has(next_tile) or new_cost < int(cost_so_far[next_tile]):
				cost_so_far[next_tile] = new_cost
				came_from[next_tile] = current
				frontier.append(next_tile)
	return {
		"costs": cost_so_far,
		"came_from": came_from,
	}


func build_path(start: Vector2i, destination: Vector2i, reachability: Dictionary) -> Array[Vector2i]:
	var costs = reachability.get("costs", {})
	var came_from = reachability.get("came_from", {})
	if not costs.has(destination):
		return [start]
	var cursor: Vector2i = destination
	var path: Array[Vector2i] = [cursor]
	while cursor != start:
		cursor = came_from.get(cursor, start)
		path.push_front(cursor)
	return path
