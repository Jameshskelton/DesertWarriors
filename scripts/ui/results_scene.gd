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
	_return_button.grab_focus()
	
	var success: bool = bool(_summary.get("success", false))
	var survivors: PackedStringArray = PackedStringArray()
	var survivors_value = _summary.get("survivors", PackedStringArray())
	if survivors_value is PackedStringArray:
		survivors = survivors_value
	elif survivors_value is Array:
		for entry in survivors_value:
			survivors.append(str(entry))
	
	_title_label.text = "Chapter Clear" if success else "Battle Lost"
	_summary_label.text = "Turns: %d\nObjective: %s\nChapter: %s" % [
		int(_summary.get("turns", 0)),
		str(_summary.get("objective", "")),
		str(_summary.get("chapter_name", "")),
	]
	_roster_label.text = "Survivors: %s" % [", ".join(survivors)]
	
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
	return_to_title.emit()


func _on_continue_pressed() -> void:
	var next_chapter_id: String = _get_next_chapter_id()
	if not next_chapter_id.is_empty():
		continue_to_next_chapter.emit(next_chapter_id)


func _get_next_chapter_id() -> String:
	var value = _summary.get("next_chapter_id", "")
	if value == null:
		return ""
	var next_chapter_id: String = str(value)
	if next_chapter_id == "null" or next_chapter_id == "<null>":
		return ""
	return next_chapter_id
