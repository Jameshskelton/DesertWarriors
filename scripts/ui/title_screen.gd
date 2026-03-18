extends Control

signal new_game_requested(permadeath_enabled: bool)
signal continue_requested(chapter_id: String)
signal chapter_select_requested
signal options_requested

var _menu_visible: bool = false

@onready var _menu_panel: PanelContainer = $MenuPanel
@onready var _options_panel: PanelContainer = $OptionsPanel
@onready var _chapter_select_panel: PanelContainer = $ChapterSelectPanel
@onready var _permadeath_panel: PanelContainer = $PermadeathPanel
@onready var _start_prompt: Label = $StartPrompt
@onready var _new_game_button: Button = $MenuPanel/MenuMargin/MenuVBox/NewGameButton
@onready var _continue_button: Button = $MenuPanel/MenuMargin/MenuVBox/ContinueButton
@onready var _chapter_select_button: Button = $MenuPanel/MenuMargin/MenuVBox/ChapterSelectButton
@onready var _options_button: Button = $MenuPanel/MenuMargin/MenuVBox/OptionsButton
@onready var _quit_button: Button = $MenuPanel/MenuMargin/MenuVBox/QuitButton
@onready var _chapter_1_button: Button = $ChapterSelectPanel/ChapterSelectMargin/ChapterSelectVBox/ChaptersContainer/Chapter1Button
@onready var _chapter_2_button: Button = $ChapterSelectPanel/ChapterSelectMargin/ChapterSelectVBox/ChaptersContainer/Chapter2Button
@onready var _chapter_3_button: Button = $ChapterSelectPanel/ChapterSelectMargin/ChapterSelectVBox/ChaptersContainer/Chapter3Button
@onready var _chapter_4_button: Button = $ChapterSelectPanel/ChapterSelectMargin/ChapterSelectVBox/ChaptersContainer/Chapter4Button
@onready var _chapter_5_button: Button = $ChapterSelectPanel/ChapterSelectMargin/ChapterSelectVBox/ChaptersContainer/Chapter5Button
@onready var _chapter_select_back_button: Button = $ChapterSelectPanel/ChapterSelectMargin/ChapterSelectVBox/BackButton2
@onready var _music_slider: HSlider = $OptionsPanel/OptionsMargin/OptionsVBox/MusicSlider
@onready var _sfx_slider: HSlider = $OptionsPanel/OptionsMargin/OptionsVBox/SFXSlider
@onready var _speed_slider: HSlider = $OptionsPanel/OptionsMargin/OptionsVBox/SpeedSlider


func _ready() -> void:
	AudioDirector.play_track("title_theme")
	_connect_signals()
	_connect_button_audio()
	_configure_chapter_select_navigation()
	_apply_settings()
	_menu_visible = false
	_menu_panel.visible = false
	_permadeath_panel.visible = false
	_start_prompt.visible = true


func _connect_signals() -> void:
	_new_game_button.pressed.connect(_on_new_game_pressed)
	_continue_button.pressed.connect(_on_continue_pressed)
	_chapter_select_button.pressed.connect(_on_chapter_select_pressed)
	_options_button.pressed.connect(_on_options_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)
	_music_slider.value_changed.connect(_on_music_changed)
	_sfx_slider.value_changed.connect(_on_sfx_changed)
	_speed_slider.value_changed.connect(_on_speed_changed)
	$OptionsPanel/OptionsMargin/OptionsVBox/BackButton.pressed.connect(_on_options_back)
	_chapter_select_back_button.pressed.connect(_on_chapter_select_back)
	_chapter_1_button.pressed.connect(_on_chapter_1_selected)
	_chapter_2_button.pressed.connect(_on_chapter_2_selected)
	_chapter_3_button.pressed.connect(_on_chapter_3_selected)
	_chapter_4_button.pressed.connect(_on_chapter_4_selected)
	_chapter_5_button.pressed.connect(_on_chapter_5_selected)
	$PermadeathPanel/PermadeathMargin/PermadeathVBox/ButtonRow/YesButton.pressed.connect(_on_permadeath_yes_pressed)
	$PermadeathPanel/PermadeathMargin/PermadeathVBox/ButtonRow/NoButton.pressed.connect(_on_permadeath_no_pressed)


func _connect_button_audio() -> void:
	for button in [
		_new_game_button,
		_continue_button,
		_chapter_select_button,
		_options_button,
		_quit_button,
		_chapter_1_button,
		_chapter_2_button,
		_chapter_3_button,
		_chapter_4_button,
		_chapter_5_button,
		_chapter_select_back_button,
		$OptionsPanel/OptionsMargin/OptionsVBox/BackButton,
		$PermadeathPanel/PermadeathMargin/PermadeathVBox/ButtonRow/YesButton,
		$PermadeathPanel/PermadeathMargin/PermadeathVBox/ButtonRow/NoButton,
	]:
		if button == null:
			continue
		button.focus_entered.connect(func() -> void:
			AudioDirector.play_sfx("cursor_tick")
		)


func _configure_chapter_select_navigation() -> void:
	var chapter_buttons: Array[Button] = [
		_chapter_1_button,
		_chapter_2_button,
		_chapter_3_button,
		_chapter_4_button,
		_chapter_5_button,
	]
	for index in range(chapter_buttons.size()):
		var current_button: Button = chapter_buttons[index]
		var up_target: Control = _chapter_select_back_button if index == 0 else chapter_buttons[index - 1]
		var down_target: Control = _chapter_select_back_button if index == chapter_buttons.size() - 1 else chapter_buttons[index + 1]
		current_button.focus_mode = Control.FOCUS_ALL
		current_button.set_focus_neighbor(SIDE_TOP, current_button.get_path_to(up_target))
		current_button.set_focus_neighbor(SIDE_BOTTOM, current_button.get_path_to(down_target))
	_chapter_select_back_button.focus_mode = Control.FOCUS_ALL
	_chapter_select_back_button.set_focus_neighbor(SIDE_TOP, _chapter_select_back_button.get_path_to(_chapter_5_button))
	_chapter_select_back_button.set_focus_neighbor(SIDE_BOTTOM, _chapter_select_back_button.get_path_to(_chapter_1_button))


func _apply_settings() -> void:
	var settings = GameState.settings
	_music_slider.value = settings.get("music_volume", 0.8)
	_sfx_slider.value = settings.get("sfx_volume", 0.9)
	_speed_slider.value = settings.get("battle_speed", 1.0)
	AudioDirector.set_music_volume(_music_slider.value)
	AudioDirector.set_sfx_volume(_sfx_slider.value)


func _unhandled_input(event: InputEvent) -> void:
	if not _menu_visible and (event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT)):
		_show_menu()
	elif event.is_action_pressed("ui_cancel"):
		if _permadeath_panel.visible:
			_close_permadeath_prompt()
		elif _options_panel.visible:
			_on_options_back()
		elif _chapter_select_panel.visible:
			_on_chapter_select_back()
		elif _menu_visible:
			_hide_menu()


func _show_menu() -> void:
	_menu_visible = true
	_start_prompt.visible = false
	_menu_panel.visible = true
	AudioDirector.play_sfx("menu_confirm")
	_continue_button.disabled = not SaveSystem.has_save()
	_continue_button.text = "Resume Suspend" if SaveSystem.has_suspend_save() else "Continue"
	_chapter_select_button.disabled = false
	_new_game_button.grab_focus()


func _hide_menu() -> void:
	_menu_visible = false
	_menu_panel.visible = false
	_permadeath_panel.visible = false
	_start_prompt.visible = true
	AudioDirector.play_sfx("menu_cancel")


func _on_new_game_pressed() -> void:
	AudioDirector.play_sfx("menu_confirm")
	_permadeath_panel.visible = true
	$PermadeathPanel/PermadeathMargin/PermadeathVBox/ButtonRow/NoButton.grab_focus()


func _on_continue_pressed() -> void:
	if GameState.continue_game():
		AudioDirector.play_sfx("menu_confirm")
		continue_requested.emit(GameState.current_chapter_id)


func _on_chapter_select_pressed() -> void:
	AudioDirector.play_sfx("menu_confirm")
	_chapter_select_panel.visible = true
	_chapter_1_button.grab_focus()


func _on_options_pressed() -> void:
	AudioDirector.play_sfx("menu_confirm")
	_options_panel.visible = true
	$OptionsPanel/OptionsMargin/OptionsVBox/BackButton.grab_focus()


func _on_quit_pressed() -> void:
	AudioDirector.play_sfx("menu_confirm")
	get_tree().quit()


func _on_music_changed(value: float) -> void:
	GameState.settings["music_volume"] = value
	AudioDirector.set_music_volume(value)
	_save_settings()


func _on_sfx_changed(value: float) -> void:
	GameState.settings["sfx_volume"] = value
	AudioDirector.set_sfx_volume(value)
	_save_settings()


func _on_speed_changed(value: float) -> void:
	GameState.settings["battle_speed"] = value
	_save_settings()


func _save_settings() -> void:
	var payload = GameState.build_save_payload()
	SaveSystem.save_game(payload)


func _on_options_back() -> void:
	_options_panel.visible = false
	AudioDirector.play_sfx("menu_cancel")
	_options_button.grab_focus()


func _on_chapter_select_back() -> void:
	_chapter_select_panel.visible = false
	AudioDirector.play_sfx("menu_cancel")
	_chapter_select_button.grab_focus()


func _on_chapter_1_selected() -> void:
	GameState.prepare_chapter_select_game("chapter_1")
	AudioDirector.play_sfx("menu_confirm")
	continue_requested.emit("chapter_1")


func _on_chapter_2_selected() -> void:
	GameState.prepare_chapter_select_game("chapter_2")
	AudioDirector.play_sfx("menu_confirm")
	continue_requested.emit("chapter_2")


func _on_chapter_3_selected() -> void:
	GameState.prepare_chapter_select_game("chapter_3")
	AudioDirector.play_sfx("menu_confirm")
	continue_requested.emit("chapter_3")


func _on_chapter_4_selected() -> void:
	GameState.prepare_chapter_select_game("chapter_4")
	AudioDirector.play_sfx("menu_confirm")
	continue_requested.emit("chapter_4")


func _on_chapter_5_selected() -> void:
	GameState.prepare_chapter_select_game("chapter_5")
	AudioDirector.play_sfx("menu_confirm")
	continue_requested.emit("chapter_5")


func _close_permadeath_prompt() -> void:
	_permadeath_panel.visible = false
	AudioDirector.play_sfx("menu_cancel")
	_new_game_button.grab_focus()


func _on_permadeath_yes_pressed() -> void:
	_permadeath_panel.visible = false
	AudioDirector.play_sfx("menu_confirm")
	new_game_requested.emit(true)


func _on_permadeath_no_pressed() -> void:
	_permadeath_panel.visible = false
	AudioDirector.play_sfx("menu_confirm")
	new_game_requested.emit(false)
