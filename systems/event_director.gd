extends RefCounted
class_name EventDirector

var handled_events: PackedStringArray = PackedStringArray()


func reset() -> void:
	handled_events.clear()


func consume_turn_events(turn_number: int, chapter: ChapterData) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for event in chapter.event_triggers:
		if event.get("trigger", "") != "turn":
			continue
		var event_id: String = str(event.get("id", ""))
		if handled_events.has(event_id):
			continue
		if int(event.get("turn", -1)) == turn_number:
			handled_events.append(event_id)
			result.append(event)
	return result


func consume_tile_events(unit_id: String, tile: Vector2i, chapter: ChapterData) -> Array[Dictionary]:
	var result := peek_tile_events(unit_id, tile, chapter)
	for event in result:
		var event_id: String = str(event.get("id", ""))
		if not event_id.is_empty() and not handled_events.has(event_id):
			handled_events.append(event_id)
	return result


func peek_tile_events(unit_id: String, tile: Vector2i, chapter: ChapterData) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for event in chapter.event_triggers:
		if event.get("trigger", "") != "tile":
			continue
		var event_id: String = str(event.get("id", ""))
		if handled_events.has(event_id):
			continue
		var event_tile = event.get("position", Vector2i(-1, -1))
		var allowed_unit: String = str(event.get("unit_id", ""))
		if event_tile == tile and (allowed_unit.is_empty() or allowed_unit == unit_id):
			result.append(event)
	return result


func peek_talk_event(source: UnitState, target: UnitState, chapter: ChapterData) -> Dictionary:
	if source == null or target == null:
		return {}
	for event in chapter.event_triggers:
		if event.get("trigger", "") != "talk":
			continue
		var event_id: String = str(event.get("id", ""))
		if handled_events.has(event_id):
			continue
		var unit_a_id: String = str(event.get("unit_a_id", ""))
		var unit_b_id: String = str(event.get("unit_b_id", ""))
		var source_matches_a: bool = _unit_matches_id(source, unit_a_id)
		var source_matches_b: bool = _unit_matches_id(source, unit_b_id)
		var target_matches_a: bool = _unit_matches_id(target, unit_a_id)
		var target_matches_b: bool = _unit_matches_id(target, unit_b_id)
		if (source_matches_a and target_matches_b) or (source_matches_b and target_matches_a):
			return event
	return {}


func consume_talk_event(source: UnitState, target: UnitState, chapter: ChapterData) -> Dictionary:
	var event: Dictionary = peek_talk_event(source, target, chapter)
	if event.is_empty():
		return {}
	var event_id: String = str(event.get("id", ""))
	if not event_id.is_empty() and not handled_events.has(event_id):
		handled_events.append(event_id)
	return event


func consume_boss_confront_event(attacker: UnitState, defender: UnitState, chapter: ChapterData) -> Dictionary:
	var george: UnitState = null
	var boss: UnitState = null
	for unit in [attacker, defender]:
		if unit == null:
			continue
		if unit.unit_id == "george" or unit.base_unit_id == "george":
			george = unit
		if unit.has_flag("boss"):
			boss = unit
	if george == null or boss == null:
		return {}
	for event in chapter.event_triggers:
		if event.get("trigger", "") != "boss_confront":
			continue
		var event_id: String = str(event.get("id", ""))
		if handled_events.has(event_id):
			continue
		var allowed_unit: String = str(event.get("unit_id", ""))
		if not allowed_unit.is_empty() and allowed_unit != george.unit_id and allowed_unit != george.base_unit_id:
			continue
		var boss_id: String = str(event.get("boss_id", ""))
		if not boss_id.is_empty() and boss_id != boss.unit_id and boss_id != boss.base_unit_id:
			continue
		if not event_id.is_empty():
			handled_events.append(event_id)
		return event
	return {}


func _unit_matches_id(unit: UnitState, expected_id: String) -> bool:
	if unit == null:
		return false
	if expected_id.is_empty():
		return false
	return expected_id == unit.unit_id or expected_id == unit.base_unit_id
