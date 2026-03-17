extends RefCounted


func run() -> PackedStringArray:
	var failures := PackedStringArray()
	DataRegistry.reload_all()
	var boss_ids := PackedStringArray([
		"captain_briar",
		"abbot_vermis",
		"sir_aldric",
		"lysandra_quill",
	])
	for boss_id in boss_ids:
		var unit_data: UnitData = DataRegistry.get_unit_data(boss_id)
		_assert_true(unit_data != null, "%s should exist" % boss_id, failures)
		if unit_data == null:
			continue
		_assert_true(unit_data.story_flags.has("boss"), "%s should still be flagged as a boss" % boss_id, failures)
		_assert_true(not unit_data.boss_title.is_empty(), "%s should have a boss title for battle framing" % boss_id, failures)
	return failures


func _assert_true(condition: bool, message: String, failures: PackedStringArray) -> void:
	if not condition:
		failures.append(message)
