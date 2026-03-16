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
