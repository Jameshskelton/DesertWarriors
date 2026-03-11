extends RefCounted
class_name TurnController

var turn_number := 1
var phase := "player"


func begin_battle(units: Array[UnitState]) -> void:
	turn_number = 1
	phase = "player"
	reset_player_units(units)


func reset_player_units(units: Array[UnitState]) -> void:
	for unit in units:
		if unit.faction == "player" and unit.is_alive():
			unit.reset_turn_state()


func enter_enemy_phase() -> void:
	phase = "enemy"


func enter_player_phase(units: Array[UnitState]) -> void:
	turn_number += 1
	phase = "player"
	reset_player_units(units)
