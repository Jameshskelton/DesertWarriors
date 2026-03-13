extends Control

signal new_game_requested
signal continue_requested(chapter_id: String)
signal chapter_select_requested
signal options_requested

var _menu_visible: bool = false

@onready var _menu_panel: PanelContainer = $MenuPanel
@onready var _options_panel: PanelContainer = $OptionsPanel
@onready var _chapter_select_panel: PanelContainer = $ChapterSelectPanel
@onready var _new_game_button: Button = $MenuPanel/MenuMargin/MenuVBox/NewGameButton
@onready var _continue_button: Button = $MenuPanel/MenuMargin/MenuVBox/ContinueButton
@onready var _chapter_select_button: Button = $MenuPanel/MenuMargin/MenuVBox/ChapterSelectButton
@onready var _options_button: Button = $MenuPanel/MenuMargin/MenuVBox/OptionsButton
@onready var _quit_button: Button = $MenuPanel/MenuMargin/MenuVBox/QuitButton
@onready var _music_slider: HSlider = $OptionsPanel/OptionsMargin/OptionsVBox/MusicSlider
@onready var _sfx_slider: HSlider = $OptionsPanel/OptionsMargin/OptionsVBox/SFXSlider
@onready var _speed_slider: HSlider = $OptionsPanel/OptionsMargin/OptionsVBox/SpeedSlider


func _ready() -> void:
	AudioDirector.play_track("title_theme")
	_connect_signals()
	_apply_settings()
	_menu_visible = false
	_menu_panel.visible = false


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
	$ChapterSelectPanel/ChapterSelectMargin/ChapterSelectVBox/BackButton2.pressed.connect(_on_chapter_select_back)
	$ChapterSelectPanel/ChapterSelectMargin/ChapterSelectVBox/ChaptersContainer/Chapter1Button.pressed.connect(_on_chapter_1_selected)
	$ChapterSelectPanel/ChapterSelectMargin/ChapterSelectVBox/ChaptersContainer/Chapter2Button.pressed.connect(_on_chapter_2_selected)
	$ChapterSelectPanel/ChapterSelectMargin/ChapterSelectVBox/ChaptersContainer/Chapter3Button.pressed.connect(_on_chapter_3_selected)


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
		if _options_panel.visible:
			_on_options_back()
		elif _chapter_select_panel.visible:
			_on_chapter_select_back()
		elif _menu_visible:
			_hide_menu()


func _show_menu() -> void:
	_menu_visible = true
	_menu_panel.visible = true
	_continue_button.disabled = not SaveSystem.has_save()
	_continue_button.text = "Resume Suspend" if SaveSystem.has_suspend_save() else "Continue"
	var has_chapters = not GameState.cleared_chapters.is_empty()
	_chapter_select_button.disabled = not has_chapters
	_new_game_button.grab_focus()


func _hide_menu() -> void:
	_menu_visible = false
	_menu_panel.visible = false


func _on_new_game_pressed() -> void:
	GameState.start_new_game()
	GameState.is_continuing = false
	new_game_requested.emit()


func _on_continue_pressed() -> void:
	if GameState.continue_game():
		continue_requested.emit(GameState.current_chapter_id)


func _on_chapter_select_pressed() -> void:
	_chapter_select_panel.visible = true
	$ChapterSelectPanel/ChapterSelectMargin/ChapterSelectVBox/ChaptersContainer/Chapter1Button.grab_focus()


func _on_options_pressed() -> void:
	_options_panel.visible = true
	$OptionsPanel/OptionsMargin/OptionsVBox/BackButton.grab_focus()


func _on_quit_pressed() -> void:
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
	_options_button.grab_focus()


func _on_chapter_select_back() -> void:
	_chapter_select_panel.visible = false
	_chapter_select_button.grab_focus()


func _on_chapter_1_selected() -> void:
	GameState.start_new_game()
	GameState.current_chapter_id = "chapter_1"
	# Mark chapters 1 as available
	GameState.cleared_chapters.clear()
	continue_requested.emit("chapter_1")


func _on_chapter_2_selected() -> void:
	GameState.start_new_game()
	GameState.current_chapter_id = "chapter_2"
	GameState.cleared_chapters = PackedStringArray(["chapter_1"])
	continue_requested.emit("chapter_2")


func _on_chapter_3_selected() -> void:
	GameState.start_new_game()
	GameState.current_chapter_id = "chapter_3"
	GameState.cleared_chapters = PackedStringArray(["chapter_1", "chapter_2"])
	continue_requested.emit("chapter_3")
