extends RefCounted
class_name ObjectiveController


func check_victory(units: Array[UnitState], chapter: ChapterData, turn_number: int = 0) -> bool:
	if chapter.objective_type == "defeat_boss":
		for unit in units:
			if unit.faction == "enemy" and unit.is_alive() and unit.has_flag("boss"):
				return false
		return true
	if chapter.objective_type == "survive_turns":
		if chapter.objective_turns > 0 and turn_number > chapter.objective_turns:
			return true
		return _has_defeated_spawned_chapter_boss(units, chapter)
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


func get_objective_text(chapter: ChapterData) -> String:
	if chapter == null:
		return ""
	if chapter.objective_type == "survive_turns" and chapter.objective_turns > 0:
		if not _get_chapter_boss_unit_ids(chapter).is_empty():
			return "Survive %d Turns or Defeat Boss" % chapter.objective_turns
		return "Survive %d Turns" % chapter.objective_turns
	return "Defeat Boss"


func _has_defeated_spawned_chapter_boss(units: Array[UnitState], chapter: ChapterData) -> bool:
	var boss_unit_ids: PackedStringArray = _get_chapter_boss_unit_ids(chapter)
	if boss_unit_ids.is_empty():
		return false
	var boss_spawned: bool = false
	for unit in units:
		if unit == null or unit.faction != "enemy":
			continue
		if not boss_unit_ids.has(unit.unit_id) and not boss_unit_ids.has(unit.base_unit_id):
			continue
		boss_spawned = true
		if unit.is_alive():
			return false
	return boss_spawned


func _get_chapter_boss_unit_ids(chapter: ChapterData) -> PackedStringArray:
	var boss_unit_ids: PackedStringArray = PackedStringArray()
	if chapter == null:
		return boss_unit_ids
	for entry in chapter.enemy_units:
		_append_boss_unit_id(entry, boss_unit_ids)
	for entry in chapter.reinforcements:
		_append_boss_unit_id(entry, boss_unit_ids)
	return boss_unit_ids


func _append_boss_unit_id(entry: Dictionary, boss_unit_ids: PackedStringArray) -> void:
	var unit_id: String = str(entry.get("unit_id", ""))
	if unit_id.is_empty() or boss_unit_ids.has(unit_id):
		return
	var unit_data: UnitData = DataRegistry.get_unit_data(unit_id)
	if unit_data == null:
		return
	if unit_data.story_flags.has("boss"):
		boss_unit_ids.append(unit_id)
