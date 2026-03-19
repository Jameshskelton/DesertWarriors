extends RefCounted
class_name TurnController

var turn_number := 1
var phase := "player"


func begin_battle(units: Array[UnitState]) -> void:
	turn_number = 1
	phase = "player"
	reset_allied_units(units)


func reset_allied_units(units: Array[UnitState]) -> void:
	for unit in units:
		if unit.is_alive() and (unit.is_player_controlled() or unit.faction == "neutral"):
			unit.reset_turn_state()


func enter_neutral_phase() -> void:
	phase = "neutral"


func enter_enemy_phase() -> void:
	phase = "enemy"


func enter_player_phase(units: Array[UnitState]) -> void:
	turn_number += 1
	phase = "player"
	reset_allied_units(units)
