extends Control

signal tutorial_finished

var _pages: Array[Dictionary] = []
var _page_index: int = 0

@onready var _title_label: Label = $Panel/PanelMargin/PanelVBox/TitleLabel
@onready var _body_label: Label = $Panel/PanelMargin/PanelVBox/BodyLabel
@onready var _page_label: Label = $Panel/PanelMargin/PanelVBox/FooterRow/PageLabel
@onready var _previous_button: Button = $Panel/PanelMargin/PanelVBox/FooterRow/PreviousButton
@onready var _continue_button: Button = $Panel/PanelMargin/PanelVBox/FooterRow/ContinueButton


func setup(pages: Array) -> void:
	_pages.clear()
	for page_value in pages:
		if typeof(page_value) != TYPE_DICTIONARY:
			continue
		_pages.append((page_value as Dictionary).duplicate(true))


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_previous_button.pressed.connect(Callable(self, "_go_previous_page"))
	_continue_button.pressed.connect(Callable(self, "_on_continue_pressed"))
	_previous_button.focus_neighbor_right = _continue_button.get_path()
	_continue_button.focus_neighbor_left = _previous_button.get_path()
	_continue_button.grab_focus()
	_render_page()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_left") or event.is_action_pressed("ui_up"):
		get_viewport().set_input_as_handled()
		_go_previous_page()
		return
	if event.is_action_pressed("ui_right") or event.is_action_pressed("ui_down"):
		get_viewport().set_input_as_handled()
		_go_next_page()
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		tutorial_finished.emit()
		return


func _on_continue_pressed() -> void:
	_go_next_page()


func _go_previous_page() -> void:
	if _page_index <= 0:
		return
	AudioDirector.play_sfx("cursor_tick")
	_page_index -= 1
	_render_page()


func _go_next_page() -> void:
	AudioDirector.play_sfx("menu_confirm")
	if _page_index + 1 < _pages.size():
		_page_index += 1
		_render_page()
		return
	tutorial_finished.emit()


func _render_page() -> void:
	if _pages.is_empty():
		tutorial_finished.emit()
		return
	var page: Dictionary = _pages[_page_index]
	_title_label.text = str(page.get("title", "Tutorial"))
	_body_label.text = str(page.get("body", ""))
	if _pages.size() <= 1:
		_page_label.text = "Tutorial  |  Use Space to close"
		_previous_button.disabled = true
		_previous_button.visible = false
		_continue_button.text = "Close"
		return
	_previous_button.visible = true
	_previous_button.disabled = _page_index <= 0
	_page_label.text = "Page %d / %d  |  Arrow keys change pages" % [_page_index + 1, _pages.size()]
	if _page_index == _pages.size() - 1:
		_continue_button.text = "Close"
	else:
		_continue_button.text = "Next"
