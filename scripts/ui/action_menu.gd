extends PanelContainer

signal action_selected(action_name: String)

@onready var _buttons: Dictionary = {
	"attack": $Margin/Buttons/AttackButton,
	"staff": $Margin/Buttons/StaffButton,
	"item": $Margin/Buttons/ItemButton,
	"visit": $Margin/Buttons/VisitButton,
	"wait": $Margin/Buttons/WaitButton,
	"cancel": $Margin/Buttons/CancelButton,
}


func _ready() -> void:
	for action_name in _buttons.keys():
		var button := _buttons[action_name] as Button
		button.pressed.connect(_on_button_pressed.bind(action_name))


func show_actions(action_states: Dictionary) -> void:
	visible = true
	for action_name in _buttons.keys():
		var button := _buttons[action_name] as Button
		var is_enabled = bool(action_states.get(action_name, false))
		button.visible = action_name == "cancel" or action_states.has(action_name)
		button.disabled = not is_enabled and action_name != "cancel"
	var focus_name := _get_first_focusable_action(action_states)
	var focus_button := _buttons.get(focus_name, _buttons["wait"]) as Button
	focus_button.grab_focus()


func hide_menu() -> void:
	visible = false


func _get_first_focusable_action(action_states: Dictionary) -> String:
	for action_name in ["attack", "staff", "item", "visit", "wait", "cancel"]:
		if action_name == "cancel":
			return action_name
		if action_states.get(action_name, false):
			return action_name
	return "cancel"


func _on_button_pressed(action_name: String) -> void:
	action_selected.emit(action_name)
