extends RefCounted
class_name ObjectiveController


func check_victory(units: Array[UnitState], chapter: ChapterData) -> bool:
	if chapter.objective_type == "defeat_boss":
		for unit in units:
			if unit.faction == "enemy" and unit.is_alive() and unit.has_flag("boss"):
				return false
		return true
	return false


func check_defeat(units: Array[UnitState]) -> bool:
	var george_alive := false
	var any_player_alive := false
	for unit in units:
		if unit.faction != "player":
			continue
		if unit.is_alive():
			any_player_alive = true
		if unit.unit_id == "george" and unit.is_alive():
			george_alive = true
	return not george_alive or not any_player_alive
