extends RefCounted
class_name GridService


func in_bounds(tile: Vector2i, grid_size: Vector2i) -> bool:
	return tile.x >= 0 and tile.y >= 0 and tile.x < grid_size.x and tile.y < grid_size.y


func neighbors(tile: Vector2i, grid_size: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var offsets: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
	for offset in offsets:
		var next_tile: Vector2i = tile + offset
		if in_bounds(next_tile, grid_size):
			result.append(next_tile)
	return result


func manhattan(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)


func ring(center: Vector2i, min_range: int, max_range: int, grid_size: Vector2i) -> Array[Vector2i]:
	var positions: Array[Vector2i] = []
	for y in range(grid_size.y):
		for x in range(grid_size.x):
			var tile := Vector2i(x, y)
			var distance := manhattan(center, tile)
			if distance >= min_range and distance <= max_range:
				positions.append(tile)
	return positions
