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
