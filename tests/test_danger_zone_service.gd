extends RefCounted


func run() -> PackedStringArray:
	var failures := PackedStringArray()
	var service := DangerZoneService.new()
	DataRegistry.reload_all()
	var terrain_grid := [["plains", "plains", "plains", "plains"]]
	var brigand := UnitState.from_unit_data(DataRegistry.get_unit_data("brigand_grunt"), Vector2i(0, 0), "enemy")
	var open_units: Array[UnitState] = [brigand]
	var open_threats: Dictionary = service.build_enemy_threat_tiles(open_units, terrain_grid)
	_assert_true(open_threats.has(Vector2i(2, 0)), "enemy threat range should extend through open movement space", failures)
	var george := UnitState.from_unit_data(DataRegistry.get_unit_data("george"), Vector2i(1, 0))
	var blocked_units: Array[UnitState] = [brigand, george]
	var blocked_threats: Dictionary = service.build_enemy_threat_tiles(blocked_units, terrain_grid)
	_assert_true(blocked_threats.has(Vector2i(1, 0)), "adjacent tiles should still be threatened", failures)
	_assert_true(not blocked_threats.has(Vector2i(2, 0)), "opposing units should block farther threat reach", failures)
	var hale_enemy := UnitState.from_unit_data(DataRegistry.get_unit_data("brother_hale"), Vector2i(0, 0), "enemy")
	var staff_units: Array[UnitState] = [hale_enemy]
	var staff_threats: Dictionary = service.build_enemy_threat_tiles(staff_units, terrain_grid)
	_assert_true(staff_threats.is_empty(), "staff users should not contribute to the danger zone", failures)
	return failures


func _assert_true(condition: bool, message: String, failures: PackedStringArray) -> void:
	if not condition:
		failures.append(message)
