extends Control

signal return_to_title
signal continue_to_next_chapter(next_chapter_id: String)

var _summary: Dictionary = {}

@onready var _title_label: Label = $Center/Panel/Margin/VBox/TitleLabel
@onready var _summary_label: Label = $Center/Panel/Margin/VBox/SummaryLabel
@onready var _roster_label: Label = $Center/Panel/Margin/VBox/RosterLabel
@onready var _continue_button: Button = $Center/Panel/Margin/VBox/ContinueButton
@onready var _return_button: Button = $Center/Panel/Margin/VBox/ReturnButton


func setup(summary: Dictionary) -> void:
	_summary = summary


func _ready() -> void:
	_return_button.pressed.connect(_on_return_pressed)
	_continue_button.pressed.connect(_on_continue_pressed)
	_return_button.focus_entered.connect(func() -> void:
		AudioDirector.play_sfx("cursor_tick")
	)
	_continue_button.focus_entered.connect(func() -> void:
		AudioDirector.play_sfx("cursor_tick")
	)
	_return_button.grab_focus()
	
	var success: bool = bool(_summary.get("success", false))
	if success:
		AudioDirector.play_sfx("chapter_clear")
	else:
		AudioDirector.play_sfx("battle_loss")
	_title_label.text = "Chapter Clear" if success else "Battle Lost"
	_summary_label.text = _build_summary_text(success)
	_roster_label.text = _build_roster_text()
	
	# Show continue button if there's a next chapter
	var next_chapter_id: String = _get_next_chapter_id()
	if success and not next_chapter_id.is_empty():
		_continue_button.visible = true
		_return_button.text = "Return to Title"
		_continue_button.grab_focus()
	else:
		_continue_button.visible = false
		_return_button.text = "Return to Title"
	
	var payload := GameState.build_save_payload()
	SaveSystem.save_game(payload)


func _on_return_pressed() -> void:
	AudioDirector.play_sfx("menu_confirm")
	return_to_title.emit()


func _on_continue_pressed() -> void:
	var next_chapter_id: String = _get_next_chapter_id()
	if not next_chapter_id.is_empty():
		AudioDirector.play_sfx("menu_confirm")
		continue_to_next_chapter.emit(next_chapter_id)


func _get_next_chapter_id() -> String:
	var value = _summary.get("next_chapter_id", "")
	if value == null:
		return ""
	var next_chapter_id: String = str(value)
	if next_chapter_id == "null" or next_chapter_id == "<null>":
		return ""
	return next_chapter_id


func _build_summary_text(success: bool) -> String:
	var lines: Array[String] = []
	lines.append("Battle Report")
	lines.append("Outcome: %s" % ("Victory" if success else "Defeat"))
	lines.append("Chapter: %s" % str(_summary.get("chapter_name", "")))
	lines.append("Objective: %s" % str(_summary.get("objective", "")))
	lines.append("Turns: %d" % int(_summary.get("turns", 0)))
	lines.append("EXP Gained: %s" % _format_xp_gains(_summary.get("xp_gains", {})))
	lines.append("Gold Earned: %s" % _format_gold_earned())
	lines.append("Party Gold: %d" % GameState.gold)
	lines.append("Recruits Obtained: %s" % _format_entry_counts(_summary.get("recruits", PackedStringArray()), "None"))
	lines.append("Weapon Breaks: %s" % _format_entry_counts(_summary.get("weapon_breaks", PackedStringArray()), "None"))
	lines.append("Used Items: %s" % _format_entry_counts(_summary.get("used_items", PackedStringArray()), "None"))
	return "\n".join(lines)


func _build_roster_text() -> String:
	var lines: Array[String] = []
	lines.append("Roster Status")
	lines.append("Survivors: %s" % _format_name_list(_summary.get("survivors", PackedStringArray()), "None"))
	lines.append("Fallen: %s" % _format_name_list(_summary.get("fallen", PackedStringArray()), "None"))
	return "\n".join(lines)


func _format_gold_earned() -> String:
	var gold_earned: int = int(_summary.get("gold_earned", 0))
	var sources_text: String = _format_entry_counts(_summary.get("gold_sources", PackedStringArray()), "")
	if gold_earned <= 0 or sources_text.is_empty():
		return str(gold_earned)
	return "%d (%s)" % [gold_earned, sources_text]


func _format_xp_gains(value: Variant) -> String:
	if typeof(value) != TYPE_DICTIONARY:
		return "None"
	var gains: Dictionary = value
	if gains.is_empty():
		return "None"
	var unit_names: Array[String] = []
	for unit_name_value in gains.keys():
		unit_names.append(str(unit_name_value))
	unit_names.sort()
	var parts: Array[String] = []
	for unit_name in unit_names:
		var amount: int = int(gains.get(unit_name, 0))
		if amount <= 0:
			continue
		parts.append("%s +%d" % [unit_name, amount])
	if parts.is_empty():
		return "None"
	return ", ".join(parts)


func _format_entry_counts(value: Variant, empty_text: String) -> String:
	var counts: Dictionary = {}
	if value is PackedStringArray:
		for entry in value:
			var entry_name: String = str(entry)
			counts[entry_name] = int(counts.get(entry_name, 0)) + 1
	elif value is Array:
		for entry in value:
			var entry_name: String = str(entry)
			counts[entry_name] = int(counts.get(entry_name, 0)) + 1
	if counts.is_empty():
		return empty_text
	var entry_names: Array[String] = []
	for entry_name_value in counts.keys():
		entry_names.append(str(entry_name_value))
	entry_names.sort()
	var parts: Array[String] = []
	for entry_name in entry_names:
		var count: int = int(counts.get(entry_name, 0))
		if count <= 1:
			parts.append(entry_name)
		else:
			parts.append("%s x%d" % [entry_name, count])
	return ", ".join(parts)


func _format_name_list(value: Variant, empty_text: String) -> String:
	var names: PackedStringArray = PackedStringArray()
	if value is PackedStringArray:
		names = value
	elif value is Array:
		for entry in value:
			names.append(str(entry))
	if names.is_empty():
		return empty_text
	var sorted_names: Array[String] = []
	for entry in names:
		sorted_names.append(str(entry))
	sorted_names.sort()
	return ", ".join(sorted_names)
