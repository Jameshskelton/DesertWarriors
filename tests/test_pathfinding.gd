extends RefCounted


func run() -> PackedStringArray:
	var failures := PackedStringArray()
	var pathfinding := PathfindingService.new()
	DataRegistry.reload_all()
	var terrain_grid := [
		["forest", "forest", "forest"],
		["forest", "forest", "forest"],
		["forest", "forest", "forest"],
	]
	var occupied: Dictionary = {}
	var infantry: Dictionary = pathfinding.compute_reachable(Vector2i(1, 1), 4, terrain_grid, "infantry", occupied)
	var cavalry: Dictionary = pathfinding.compute_reachable(Vector2i(1, 1), 4, terrain_grid, "cavalry", occupied)
	_assert_true(infantry.get("costs", {}).size() > cavalry.get("costs", {}).size(), "cavalry should have less reach in forest terrain", failures)
	var plains_grid := [
		["plains", "plains", "plains"],
		["plains", "plains", "plains"],
		["plains", "plains", "plains"],
	]
	var blocked_occupied: Dictionary = {Vector2i(1, 0): true}
	var result: Dictionary = pathfinding.compute_reachable(Vector2i(0, 0), 3, plains_grid, "infantry", blocked_occupied)
	_assert_true(not result.get("costs", {}).has(Vector2i(1, 0)), "occupied tiles should not be reachable", failures)
	return failures


func _assert_true(condition: bool, message: String, failures: PackedStringArray) -> void:
	if not condition:
		failures.append(message)
