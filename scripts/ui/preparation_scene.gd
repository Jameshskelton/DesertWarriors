extends Control

signal battle_requested(chapter_id: String)
signal return_to_title

const PORTRAIT_DIR := "res://assets/portraits"
const TUTORIAL_OVERLAY_SCENE := preload("res://scenes/shared/tutorial_overlay.tscn")

var _chapter_id: String = ""
var _chapter: ChapterData
var _units: Array[UnitState] = []
var _deployment_slots: Array[Vector2i] = []
var _deployment_assignments: Dictionary = {}
var _selected_unit_index: int = 0
var _selected_item_index: int = -1
var _selected_deployment_index: int = 0
var _selected_target_index: int = 0
var _selected_convoy_unit_item_index: int = -1
var _selected_convoy_index: int = -1
var _trade_target_indices: Array[int] = []
var _active_tutorial: Control

@onready var _title_label: Label = $MainMargin/MainVBox/HeaderPanel/HeaderMargin/HeaderVBox/TitleLabel
@onready var _subtitle_label: Label = $MainMargin/MainVBox/HeaderPanel/HeaderMargin/HeaderVBox/SubtitleLabel
@onready var _status_label: Label = $MainMargin/MainVBox/HeaderPanel/HeaderMargin/HeaderVBox/StatusLabel
@onready var _gold_label: Label = $MainMargin/MainVBox/HeaderPanel/HeaderMargin/HeaderVBox/GoldLabel
@onready var _unit_list: ItemList = $MainMargin/MainVBox/BodyHBox/RosterPanel/RosterMargin/RosterVBox/UnitList
@onready var _unit_portrait_texture: TextureRect = $MainMargin/MainVBox/BodyHBox/RosterPanel/RosterMargin/RosterVBox/UnitDetailRow/UnitPortraitPanel/UnitPortraitMargin/UnitPortraitFrame/UnitPortraitTexture
@onready var _unit_portrait_fallback: Label = $MainMargin/MainVBox/BodyHBox/RosterPanel/RosterMargin/RosterVBox/UnitDetailRow/UnitPortraitPanel/UnitPortraitMargin/UnitPortraitFrame/UnitPortraitFallback
@onready var _unit_summary: Label = $MainMargin/MainVBox/BodyHBox/RosterPanel/RosterMargin/RosterVBox/UnitDetailRow/UnitSummary
@onready var _inventory_list: ItemList = $MainMargin/MainVBox/BodyHBox/InventoryPanel/InventoryMargin/InventoryVBox/InventoryList
@onready var _item_details: Label = $MainMargin/MainVBox/BodyHBox/InventoryPanel/InventoryMargin/InventoryVBox/ItemDetails
@onready var _move_up_button: Button = $MainMargin/MainVBox/BodyHBox/InventoryPanel/InventoryMargin/InventoryVBox/ButtonRow/MoveUpButton
@onready var _move_down_button: Button = $MainMargin/MainVBox/BodyHBox/InventoryPanel/InventoryMargin/InventoryVBox/ButtonRow/MoveDownButton
@onready var _transfer_button: Button = $MainMargin/MainVBox/BodyHBox/InventoryPanel/InventoryMargin/InventoryVBox/ButtonRow/TransferButton
@onready var _convoy_button: Button = $MainMargin/MainVBox/BodyHBox/InventoryPanel/InventoryMargin/InventoryVBox/ButtonRow/ConvoyButton
@onready var _deployment_list: ItemList = $MainMargin/MainVBox/BodyHBox/TransferPanel/TransferMargin/TransferVBox/TargetList
@onready var _deployment_details: Label = $MainMargin/MainVBox/BodyHBox/TransferPanel/TransferMargin/TransferVBox/TargetDetails
@onready var _assign_button: Button = $MainMargin/MainVBox/BodyHBox/TransferPanel/TransferMargin/TransferVBox/DeploymentButtonRow/AssignButton
@onready var _begin_button: Button = $MainMargin/MainVBox/FooterPanel/FooterMargin/FooterRow/BeginButton
@onready var _return_button: Button = $MainMargin/MainVBox/FooterPanel/FooterMargin/FooterRow/ReturnButton
@onready var _trade_modal: PanelContainer = $TradeModal
@onready var _trade_title: Label = $TradeModal/TradeMargin/TradeVBox/TradeTitle
@onready var _trade_description: Label = $TradeModal/TradeMargin/TradeVBox/TradeDescription
@onready var _trade_source_name: Label = $TradeModal/TradeMargin/TradeVBox/TradePortraitRow/TradeSourceVBox/TradeSourceName
@onready var _trade_source_portrait_texture: TextureRect = $TradeModal/TradeMargin/TradeVBox/TradePortraitRow/TradeSourceVBox/TradeSourcePortraitPanel/TradeSourcePortraitMargin/TradeSourcePortraitFrame/TradeSourcePortraitTexture
@onready var _trade_source_portrait_fallback: Label = $TradeModal/TradeMargin/TradeVBox/TradePortraitRow/TradeSourceVBox/TradeSourcePortraitPanel/TradeSourcePortraitMargin/TradeSourcePortraitFrame/TradeSourcePortraitFallback
@onready var _trade_target_name: Label = $TradeModal/TradeMargin/TradeVBox/TradePortraitRow/TradeTargetVBox/TradeTargetName
@onready var _trade_target_portrait_texture: TextureRect = $TradeModal/TradeMargin/TradeVBox/TradePortraitRow/TradeTargetVBox/TradeTargetPortraitPanel/TradeTargetPortraitMargin/TradeTargetPortraitFrame/TradeTargetPortraitTexture
@onready var _trade_target_portrait_fallback: Label = $TradeModal/TradeMargin/TradeVBox/TradePortraitRow/TradeTargetVBox/TradeTargetPortraitPanel/TradeTargetPortraitMargin/TradeTargetPortraitFrame/TradeTargetPortraitFallback
@onready var _trade_target_list: ItemList = $TradeModal/TradeMargin/TradeVBox/TradeTargetList
@onready var _trade_target_details: Label = $TradeModal/TradeMargin/TradeVBox/TradeTargetDetails
@onready var _trade_confirm_button: Button = $TradeModal/TradeMargin/TradeVBox/TradeButtonRow/TradeConfirmButton
@onready var _trade_cancel_button: Button = $TradeModal/TradeMargin/TradeVBox/TradeButtonRow/TradeCancelButton
@onready var _convoy_modal: PanelContainer = $ConvoyModal
@onready var _convoy_title: Label = $ConvoyModal/ConvoyMargin/ConvoyVBox/ConvoyTitle
@onready var _convoy_description: Label = $ConvoyModal/ConvoyMargin/ConvoyVBox/ConvoyDescription
@onready var _convoy_unit_name: Label = $ConvoyModal/ConvoyMargin/ConvoyVBox/ConvoyTopRow/ConvoyUnitVBox/ConvoyUnitName
@onready var _convoy_unit_portrait_texture: TextureRect = $ConvoyModal/ConvoyMargin/ConvoyVBox/ConvoyTopRow/ConvoyUnitVBox/ConvoyUnitPortraitPanel/ConvoyUnitPortraitMargin/ConvoyUnitPortraitFrame/ConvoyUnitPortraitTexture
@onready var _convoy_unit_portrait_fallback: Label = $ConvoyModal/ConvoyMargin/ConvoyVBox/ConvoyTopRow/ConvoyUnitVBox/ConvoyUnitPortraitPanel/ConvoyUnitPortraitMargin/ConvoyUnitPortraitFrame/ConvoyUnitPortraitFallback
@onready var _convoy_unit_inventory_list: ItemList = $ConvoyModal/ConvoyMargin/ConvoyVBox/ConvoyTopRow/ConvoyUnitVBox/ConvoyUnitInventoryList
@onready var _convoy_list: ItemList = $ConvoyModal/ConvoyMargin/ConvoyVBox/ConvoyTopRow/ConvoyStorageVBox/ConvoyList
@onready var _convoy_details: Label = $ConvoyModal/ConvoyMargin/ConvoyVBox/ConvoyDetails
@onready var _convoy_deposit_button: Button = $ConvoyModal/ConvoyMargin/ConvoyVBox/ConvoyButtonRow/ConvoyDepositButton
@onready var _convoy_withdraw_button: Button = $ConvoyModal/ConvoyMargin/ConvoyVBox/ConvoyButtonRow/ConvoyWithdrawButton
@onready var _convoy_close_button: Button = $ConvoyModal/ConvoyMargin/ConvoyVBox/ConvoyButtonRow/ConvoyCloseButton


func setup(chapter_id: String) -> void:
	_chapter_id = chapter_id


func _ready() -> void:
	_connect_signals()
	_connect_ui_audio()
	_configure_focus_navigation()
	_trade_modal.visible = false
	_convoy_modal.visible = false
	_load_preparation_data()
	_refresh_view()
	_maybe_show_preparation_tutorial()
	if _units.is_empty():
		_begin_button.grab_focus()
	else:
		_unit_list.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if _active_tutorial != null:
		return
	if event.is_action_pressed("ui_cancel"):
		if _convoy_modal.visible:
			_close_convoy_modal()
			return
		if _trade_modal.visible:
			_close_trade_modal()
			return
		AudioDirector.play_sfx("menu_cancel")
		return_to_title.emit()
	if not _trade_modal.visible and event.is_action_pressed("ui_accept") and _inventory_list.has_focus() and _selected_item_index >= 0:
		_on_inventory_activated(_selected_item_index)
		get_viewport().set_input_as_handled()


func _connect_signals() -> void:
	_unit_list.item_selected.connect(Callable(self, "_on_unit_selected"))
	_inventory_list.item_selected.connect(Callable(self, "_on_inventory_selected"))
	_inventory_list.item_activated.connect(Callable(self, "_on_inventory_activated"))
	_deployment_list.item_selected.connect(Callable(self, "_on_deployment_selected"))
	_deployment_list.item_activated.connect(Callable(self, "_on_deployment_activated"))
	_move_up_button.pressed.connect(Callable(self, "_on_move_up_pressed"))
	_move_down_button.pressed.connect(Callable(self, "_on_move_down_pressed"))
	_transfer_button.pressed.connect(Callable(self, "_on_transfer_pressed"))
	_convoy_button.pressed.connect(Callable(self, "_on_convoy_pressed"))
	_assign_button.pressed.connect(Callable(self, "_on_assign_pressed"))
	_begin_button.pressed.connect(Callable(self, "_on_begin_pressed"))
	_return_button.pressed.connect(Callable(self, "_on_return_pressed"))
	_trade_target_list.item_selected.connect(Callable(self, "_on_trade_target_selected"))
	_trade_confirm_button.pressed.connect(Callable(self, "_on_trade_confirm_pressed"))
	_trade_cancel_button.pressed.connect(Callable(self, "_on_trade_cancel_pressed"))
	_convoy_unit_inventory_list.item_selected.connect(Callable(self, "_on_convoy_unit_item_selected"))
	_convoy_unit_inventory_list.item_activated.connect(Callable(self, "_on_convoy_unit_item_activated"))
	_convoy_list.item_selected.connect(Callable(self, "_on_convoy_item_selected"))
	_convoy_list.item_activated.connect(Callable(self, "_on_convoy_item_activated"))
	_convoy_deposit_button.pressed.connect(Callable(self, "_on_convoy_deposit_pressed"))
	_convoy_withdraw_button.pressed.connect(Callable(self, "_on_convoy_withdraw_pressed"))
	_convoy_close_button.pressed.connect(Callable(self, "_on_convoy_close_pressed"))


func _connect_ui_audio() -> void:
	for button in [
		_move_up_button,
		_move_down_button,
		_transfer_button,
		_convoy_button,
		_assign_button,
		_begin_button,
		_return_button,
		_trade_confirm_button,
		_trade_cancel_button,
		_convoy_deposit_button,
		_convoy_withdraw_button,
		_convoy_close_button,
	]:
		if button == null:
			continue
		button.focus_entered.connect(Callable(self, "_play_cursor_sound"))
	for item_list in [
		_unit_list,
		_inventory_list,
		_deployment_list,
		_trade_target_list,
		_convoy_unit_inventory_list,
		_convoy_list,
	]:
		if item_list == null:
			continue
		item_list.item_selected.connect(Callable(self, "_on_ui_list_item_selected"))


func _play_cursor_sound() -> void:
	AudioDirector.play_sfx("cursor_tick")


func _on_ui_list_item_selected(_index: int) -> void:
	AudioDirector.play_sfx("cursor_tick")


func _configure_focus_navigation() -> void:
	_move_up_button.focus_neighbor_top = _inventory_list.get_path()
	_move_down_button.focus_neighbor_top = _inventory_list.get_path()
	_transfer_button.focus_neighbor_top = _inventory_list.get_path()
	_inventory_list.focus_neighbor_bottom = _transfer_button.get_path()
	_move_up_button.focus_neighbor_right = _move_down_button.get_path()
	_move_down_button.focus_neighbor_left = _move_up_button.get_path()
	_move_down_button.focus_neighbor_right = _transfer_button.get_path()
	_transfer_button.focus_neighbor_left = _move_down_button.get_path()
	_transfer_button.focus_neighbor_right = _convoy_button.get_path()
	_convoy_button.focus_neighbor_left = _transfer_button.get_path()
	_inventory_list.focus_neighbor_right = _deployment_list.get_path()
	_deployment_list.focus_neighbor_left = _inventory_list.get_path()
	_deployment_list.focus_neighbor_bottom = _assign_button.get_path()
	_assign_button.focus_neighbor_top = _deployment_list.get_path()
	_assign_button.focus_neighbor_left = _inventory_list.get_path()
	_trade_target_list.focus_neighbor_bottom = _trade_confirm_button.get_path()
	_trade_confirm_button.focus_neighbor_top = _trade_target_list.get_path()
	_trade_cancel_button.focus_neighbor_top = _trade_target_list.get_path()
	_trade_confirm_button.focus_neighbor_right = _trade_cancel_button.get_path()
	_trade_cancel_button.focus_neighbor_left = _trade_confirm_button.get_path()
	_convoy_unit_inventory_list.focus_neighbor_right = _convoy_list.get_path()
	_convoy_list.focus_neighbor_left = _convoy_unit_inventory_list.get_path()
	_convoy_unit_inventory_list.focus_neighbor_bottom = _convoy_deposit_button.get_path()
	_convoy_list.focus_neighbor_bottom = _convoy_withdraw_button.get_path()
	_convoy_deposit_button.focus_neighbor_top = _convoy_unit_inventory_list.get_path()
	_convoy_withdraw_button.focus_neighbor_top = _convoy_list.get_path()
	_convoy_close_button.focus_neighbor_top = _convoy_list.get_path()
	_convoy_deposit_button.focus_neighbor_right = _convoy_withdraw_button.get_path()
	_convoy_withdraw_button.focus_neighbor_left = _convoy_deposit_button.get_path()
	_convoy_withdraw_button.focus_neighbor_right = _convoy_close_button.get_path()
	_convoy_close_button.focus_neighbor_left = _convoy_withdraw_button.get_path()


func _load_preparation_data() -> void:
	_chapter = DataRegistry.get_chapter_data(_chapter_id)
	_units = GameState.build_preparation_roster(_chapter_id)
	_deployment_slots = GameState.get_chapter_deployment_slots(_chapter_id)
	_deployment_assignments = GameState.build_preparation_assignments(_chapter_id, _units)
	_selected_unit_index = clampi(_selected_unit_index, 0, maxi(0, _units.size() - 1))
	_selected_item_index = -1
	_selected_deployment_index = clampi(_selected_deployment_index, 0, maxi(0, _deployment_slots.size() - 1))
	_selected_target_index = clampi(_selected_target_index, 0, maxi(0, _units.size() - 1))
	_selected_convoy_unit_item_index = -1
	_selected_convoy_index = -1
	_trade_target_indices.clear()
	_ensure_valid_target_selection()


func _refresh_view() -> void:
	var chapter_name: String = _chapter_id
	if _chapter != null:
		chapter_name = _chapter.display_name
	_title_label.text = "Preparation"
	_subtitle_label.text = "%s\n%s" % [chapter_name, _build_objective_text()]
	_gold_label.text = "Gold: %d" % GameState.gold
	_refresh_unit_list()
	_refresh_inventory_list()
	_refresh_unit_summary()
	_refresh_unit_portrait()
	_refresh_item_details()
	_refresh_deployment_panel()
	_refresh_buttons()
	if _trade_modal.visible:
		_refresh_trade_modal()
	if _convoy_modal.visible:
		_refresh_convoy_modal()
	if _units.is_empty():
		_status_label.text = "No allied units are available for this chapter."
	else:
		_status_label.text = _default_status_text()


func _refresh_unit_list() -> void:
	_unit_list.clear()
	for unit in _units:
		var deployment_text: String = _format_deployment_tag(unit.unit_id)
		_unit_list.add_item("%s  Lv.%d  HP %d/%d%s" % [
			unit.display_name,
			unit.level,
			unit.get_current_hp(),
			unit.get_max_hp(),
			deployment_text,
		])
	if _units.is_empty():
		return
	_selected_unit_index = clampi(_selected_unit_index, 0, _units.size() - 1)
	_unit_list.select(_selected_unit_index)


func _refresh_inventory_list() -> void:
	_inventory_list.clear()
	var unit: UnitState = _get_selected_unit()
	if unit == null:
		return
	var equipped_index: int = unit.get_equipped_weapon_index()
	for item_index in range(unit.inventory.size()):
		var prefix: String = ""
		if item_index == equipped_index:
			prefix = "[E] "
		_inventory_list.add_item(prefix + _format_inventory_entry(unit, item_index))
	if unit.inventory.is_empty():
		_selected_item_index = -1
		return
	_selected_item_index = clampi(_selected_item_index, 0, unit.inventory.size() - 1)
	if _selected_item_index >= 0:
		_inventory_list.select(_selected_item_index)


func _refresh_unit_summary() -> void:
	var unit: UnitState = _get_selected_unit()
	if unit == null:
		_unit_summary.text = "No unit selected."
		return
	var equipped_weapon: String = "--"
	var equipped_weapon_id: String = unit.get_equipped_weapon_id()
	var weapon: WeaponData = DataRegistry.get_weapon_data(equipped_weapon_id)
	if weapon != null:
		equipped_weapon = "%s (%d uses)" % [weapon.name, unit.get_equipped_weapon_uses()]
	var potion_count: int = unit.get_available_item_count("health_potion")
	_unit_summary.text = "Class: %s\nLevel: %d\nHP: %d / %d\nDeploy: %s\nEquipped: %s\nPotions: %d" % [
		unit.class_id.capitalize(),
		unit.level,
		unit.get_current_hp(),
		unit.get_max_hp(),
		_format_deployment_label(unit.unit_id),
		equipped_weapon,
		potion_count,
	]


func _refresh_unit_portrait() -> void:
	var unit: UnitState = _get_selected_unit()
	var fallback_text: String = "Portrait"
	if unit != null:
		fallback_text = unit.display_name
	_apply_portrait(unit, _unit_portrait_texture, _unit_portrait_fallback, fallback_text)


func _refresh_item_details() -> void:
	var unit: UnitState = _get_selected_unit()
	if unit == null or _selected_item_index < 0 or _selected_item_index >= unit.inventory.size():
		_item_details.text = "Select an item to reorder it or hand it to another ally."
		return
	var item_id: String = str(unit.inventory[_selected_item_index])
	var uses: int = unit.get_item_uses_at(_selected_item_index)
	var weapon: WeaponData = DataRegistry.get_weapon_data(item_id)
	if weapon != null:
		var equipped_tag: String = "Carried weapon"
		if _selected_item_index == unit.get_equipped_weapon_index():
			equipped_tag = "Equipped weapon"
		_item_details.text = "%s\n%s" % [_build_item_detail_text(item_id, uses), equipped_tag]
		return
	var item: ItemData = DataRegistry.get_item_data(item_id)
	if item != null:
		_item_details.text = _build_item_detail_text(item_id, uses)
		return
	_item_details.text = _build_item_detail_text(item_id, uses)


func _refresh_deployment_panel() -> void:
	_deployment_list.clear()
	if _deployment_slots.is_empty():
		_deployment_details.text = "This chapter has fixed starting positions."
		_assign_button.disabled = true
		return
	for slot_index in range(_deployment_slots.size()):
		var slot_position: Vector2i = _deployment_slots[slot_index]
		var assigned_unit: UnitState = _get_unit_assigned_to_slot(slot_position)
		var assigned_name: String = "Open"
		if assigned_unit != null:
			assigned_name = assigned_unit.display_name
		_deployment_list.add_item("Slot %d  (%d, %d)  %s" % [
			slot_index + 1,
			slot_position.x,
			slot_position.y,
			assigned_name,
		])
	if not _deployment_slots.is_empty():
		_selected_deployment_index = clampi(_selected_deployment_index, 0, _deployment_slots.size() - 1)
		_deployment_list.select(_selected_deployment_index)
	_refresh_deployment_details()


func _refresh_buttons() -> void:
	var unit: UnitState = _get_selected_unit()
	var inventory_size: int = 0
	if unit != null:
		inventory_size = unit.inventory.size()
	_move_up_button.disabled = unit == null or _selected_item_index <= 0 or _selected_item_index >= inventory_size
	_move_down_button.disabled = unit == null or _selected_item_index < 0 or _selected_item_index >= inventory_size - 1
	var transfer_ready: bool = _can_open_trade_modal()
	_transfer_button.disabled = not transfer_ready
	_transfer_button.text = "Trade"
	_convoy_button.disabled = unit == null
	_assign_button.disabled = unit == null or _deployment_slots.is_empty()
	_begin_button.disabled = _units.is_empty()


func _on_unit_selected(index: int) -> void:
	_selected_unit_index = clampi(index, 0, maxi(0, _units.size() - 1))
	_selected_item_index = -1
	_ensure_valid_target_selection()
	_refresh_view()


func _on_inventory_selected(index: int) -> void:
	var unit: UnitState = _get_selected_unit()
	if unit == null:
		return
	_selected_item_index = clampi(index, 0, unit.inventory.size() - 1)
	_refresh_item_details()
	_refresh_buttons()


func _on_deployment_selected(index: int) -> void:
	_selected_deployment_index = clampi(index, 0, maxi(0, _deployment_slots.size() - 1))
	_refresh_deployment_details()
	_refresh_buttons()


func _on_deployment_activated(index: int) -> void:
	_selected_deployment_index = clampi(index, 0, maxi(0, _deployment_slots.size() - 1))
	_assign_selected_unit_to_slot()


func _on_inventory_activated(index: int) -> void:
	var unit: UnitState = _get_selected_unit()
	if unit == null or unit.inventory.is_empty():
		return
	_selected_item_index = clampi(index, 0, unit.inventory.size() - 1)
	_refresh_item_details()
	_refresh_buttons()
	if not _transfer_button.disabled:
		AudioDirector.play_sfx("menu_confirm")
		_transfer_button.grab_focus()
		_status_label.text = "Trade ready. Press Space or Enter on Trade to choose a partner."
	elif not _move_down_button.disabled:
		AudioDirector.play_sfx("menu_confirm")
		_move_down_button.grab_focus()
	elif not _move_up_button.disabled:
		AudioDirector.play_sfx("menu_confirm")
		_move_up_button.grab_focus()


func _on_move_up_pressed() -> void:
	var unit: UnitState = _get_selected_unit()
	if unit == null:
		return
	if not unit.move_item(_selected_item_index, _selected_item_index - 1):
		return
	AudioDirector.play_sfx("menu_confirm")
	_selected_item_index -= 1
	_commit_roster()
	_refresh_view()
	_status_label.text = "%s reorganizes their pack." % unit.display_name


func _on_move_down_pressed() -> void:
	var unit: UnitState = _get_selected_unit()
	if unit == null:
		return
	if not unit.move_item(_selected_item_index, _selected_item_index + 1):
		return
	AudioDirector.play_sfx("menu_confirm")
	_selected_item_index += 1
	_commit_roster()
	_refresh_view()
	_status_label.text = "%s reorganizes their pack." % unit.display_name


func _on_transfer_pressed() -> void:
	_open_trade_modal()


func _on_convoy_pressed() -> void:
	_open_convoy_modal()


func _on_assign_pressed() -> void:
	_assign_selected_unit_to_slot()


func _on_trade_target_selected(index: int) -> void:
	if index < 0 or index >= _trade_target_indices.size():
		return
	_selected_target_index = _trade_target_indices[index]
	_refresh_trade_target_details()


func _on_trade_confirm_pressed() -> void:
	var unit: UnitState = _get_selected_unit()
	var target: UnitState = _get_selected_target()
	if unit == null or target == null:
		return
	if _selected_item_index < 0 or _selected_item_index >= unit.inventory.size():
		return
	var previous_item_index: int = _selected_item_index
	var item_name: String = _get_item_name(str(unit.inventory[_selected_item_index]))
	if not unit.transfer_item_to(_selected_item_index, target):
		_status_label.text = "%s cannot take that item." % target.display_name
		_refresh_trade_modal()
		return
	AudioDirector.play_sfx("menu_confirm")
	if unit.inventory.is_empty():
		_selected_item_index = -1
	else:
		_selected_item_index = clampi(previous_item_index, 0, unit.inventory.size() - 1)
	_close_trade_modal(false)
	_commit_roster()
	_refresh_view()
	_status_label.text = "%s hands %s to %s." % [unit.display_name, item_name, target.display_name]
	if _selected_item_index >= 0:
		_inventory_list.grab_focus()
	else:
		_unit_list.grab_focus()


func _on_trade_cancel_pressed() -> void:
	_close_trade_modal()


func _on_begin_pressed() -> void:
	_commit_roster()
	AudioDirector.play_sfx("menu_confirm")
	battle_requested.emit(_chapter_id)


func _on_return_pressed() -> void:
	AudioDirector.play_sfx("menu_confirm")
	return_to_title.emit()


func _commit_roster() -> void:
	GameState.store_preparation_roster(_units)
	GameState.store_preparation_assignments(_chapter_id, _deployment_assignments, _units)
	SaveSystem.save_game(GameState.build_save_payload())


func _assign_selected_unit_to_slot() -> void:
	var unit: UnitState = _get_selected_unit()
	if unit == null or _deployment_slots.is_empty():
		return
	var slot_index: int = clampi(_selected_deployment_index, 0, _deployment_slots.size() - 1)
	var destination_slot: Vector2i = _deployment_slots[slot_index]
	var current_slot: Vector2i = _get_assigned_slot_for_unit(unit.unit_id)
	var occupying_unit: UnitState = _get_unit_assigned_to_slot(destination_slot)
	var status_message: String = ""
	if current_slot == destination_slot:
		_status_label.text = "%s is already assigned there." % unit.display_name
		return
	AudioDirector.play_sfx("menu_confirm")
	_deployment_assignments[unit.unit_id] = _serialize_vector2i(destination_slot)
	if occupying_unit != null:
		if current_slot != Vector2i(-1, -1):
			_deployment_assignments[occupying_unit.unit_id] = _serialize_vector2i(current_slot)
		else:
			_deployment_assignments.erase(occupying_unit.unit_id)
		status_message = "%s swaps starting positions with %s." % [unit.display_name, occupying_unit.display_name]
	else:
		status_message = "%s deploys to Slot %d." % [unit.display_name, slot_index + 1]
	_commit_roster()
	_refresh_view()
	_status_label.text = status_message
	_deployment_list.grab_focus()


func _open_trade_modal() -> void:
	if not _can_open_trade_modal():
		return
	AudioDirector.play_sfx("menu_confirm")
	_trade_modal.visible = true
	_refresh_trade_modal()
	_trade_target_list.grab_focus()
	_status_label.text = "Choose which ally should receive the selected item."


func _close_trade_modal(restore_status: bool = true) -> void:
	_trade_modal.visible = false
	if restore_status:
		AudioDirector.play_sfx("menu_cancel")
	_trade_target_indices.clear()
	_trade_target_list.clear()
	if restore_status:
		_status_label.text = _default_status_text()
		_inventory_list.grab_focus()


func _refresh_trade_modal() -> void:
	var source: UnitState = _get_selected_unit()
	if source == null or _selected_item_index < 0 or _selected_item_index >= source.inventory.size():
		_trade_title.text = "Trade"
		_trade_description.text = "Select an item first."
		_trade_source_name.text = "Source"
		_trade_target_name.text = "Target"
		_apply_portrait(null, _trade_source_portrait_texture, _trade_source_portrait_fallback, "Source")
		_apply_portrait(null, _trade_target_portrait_texture, _trade_target_portrait_fallback, "Target")
		_trade_target_details.text = "No item is selected."
		_trade_confirm_button.disabled = true
		return
	var item_id: String = str(source.inventory[_selected_item_index])
	var item_name: String = _get_item_name(item_id)
	_trade_title.text = "Trade %s" % item_name
	_trade_description.text = "Choose who should receive %s from %s." % [item_name, source.display_name]
	_trade_source_name.text = source.display_name
	_apply_portrait(source, _trade_source_portrait_texture, _trade_source_portrait_fallback, source.display_name)
	_trade_target_indices.clear()
	_trade_target_list.clear()
	var preferred_target_index: int = _selected_target_index
	var preferred_list_index: int = -1
	var first_valid_list_index: int = -1
	for index in range(_units.size()):
		if index == _selected_unit_index:
			continue
		var target: UnitState = _units[index]
		var can_receive: bool = target.can_receive_item(item_id)
		var suffix: String = ""
		if not can_receive:
			suffix = " (Can't carry)"
		var list_index: int = _trade_target_indices.size()
		_trade_target_indices.append(index)
		_trade_target_list.add_item("%s%s" % [target.display_name, suffix])
		if not can_receive:
			_trade_target_list.set_item_custom_fg_color(list_index, Color(0.68, 0.63, 0.58, 1.0))
		if can_receive and first_valid_list_index == -1:
			first_valid_list_index = list_index
		if index == preferred_target_index:
			preferred_list_index = list_index
	if preferred_list_index == -1:
		preferred_list_index = first_valid_list_index
	if preferred_list_index == -1 and not _trade_target_indices.is_empty():
		preferred_list_index = 0
	if preferred_list_index != -1:
		_trade_target_list.select(preferred_list_index)
		_selected_target_index = _trade_target_indices[preferred_list_index]
	_refresh_trade_target_details()


func _refresh_trade_target_details() -> void:
	var source: UnitState = _get_selected_unit()
	var target: UnitState = _get_selected_target()
	if source == null or target == null or _selected_item_index < 0 or _selected_item_index >= source.inventory.size():
		_trade_target_name.text = "Target"
		_apply_portrait(null, _trade_target_portrait_texture, _trade_target_portrait_fallback, "Target")
		_trade_target_details.text = "Select a trade partner."
		_trade_confirm_button.disabled = true
		return
	var item_id: String = str(source.inventory[_selected_item_index])
	_trade_target_name.text = target.display_name
	_apply_portrait(target, _trade_target_portrait_texture, _trade_target_portrait_fallback, target.display_name)
	var equipped_weapon: String = "--"
	var weapon: WeaponData = DataRegistry.get_weapon_data(target.get_equipped_weapon_id())
	if weapon != null:
		equipped_weapon = weapon.name
	var can_receive: bool = target.can_receive_item(item_id)
	var status_line: String = "Ready to receive this item."
	if not can_receive:
		status_line = "This unit cannot carry that weapon type."
	_trade_target_details.text = "Target: %s\nClass: %s\nEquipped: %s\nPotions: %d\n%s" % [
		target.display_name,
		target.class_id.capitalize(),
		equipped_weapon,
		target.get_available_item_count("health_potion"),
		status_line,
	]
	_trade_confirm_button.disabled = not can_receive


func _on_convoy_unit_item_selected(index: int) -> void:
	var unit: UnitState = _get_selected_unit()
	if unit == null or unit.inventory.is_empty():
		_selected_convoy_unit_item_index = -1
		return
	_selected_convoy_unit_item_index = clampi(index, 0, unit.inventory.size() - 1)
	_refresh_convoy_details()
	_refresh_convoy_buttons()


func _on_convoy_unit_item_activated(index: int) -> void:
	_on_convoy_unit_item_selected(index)
	if not _convoy_deposit_button.disabled:
		_on_convoy_deposit_pressed()


func _on_convoy_item_selected(index: int) -> void:
	var convoy_entries: Array = GameState.get_convoy_items()
	if convoy_entries.is_empty():
		_selected_convoy_index = -1
		return
	_selected_convoy_index = clampi(index, 0, convoy_entries.size() - 1)
	_refresh_convoy_details()
	_refresh_convoy_buttons()


func _on_convoy_item_activated(index: int) -> void:
	_on_convoy_item_selected(index)
	if not _convoy_withdraw_button.disabled:
		_on_convoy_withdraw_pressed()


func _on_convoy_deposit_pressed() -> void:
	var unit: UnitState = _get_selected_unit()
	if unit == null:
		return
	var extracted_item: Dictionary = unit.extract_item_at(_selected_convoy_unit_item_index)
	if extracted_item.is_empty():
		return
	AudioDirector.play_sfx("menu_confirm")
	var item_id: String = str(extracted_item.get("item_id", ""))
	var uses: int = int(extracted_item.get("uses", 0))
	GameState.add_convoy_item(item_id, uses)
	if unit.inventory.is_empty():
		_selected_item_index = -1
		_selected_convoy_unit_item_index = -1
	else:
		_selected_item_index = clampi(_selected_convoy_unit_item_index, 0, unit.inventory.size() - 1)
		_selected_convoy_unit_item_index = _selected_item_index
	_selected_convoy_index = maxi(0, GameState.get_convoy_items().size() - 1)
	_commit_roster()
	_refresh_view()
	_refresh_convoy_modal()
	_status_label.text = "%s stores %s in the convoy." % [unit.display_name, _get_item_name(item_id)]
	if unit.inventory.is_empty():
		if not GameState.get_convoy_items().is_empty():
			_convoy_list.grab_focus()
		else:
			_convoy_close_button.grab_focus()
	else:
		_convoy_unit_inventory_list.grab_focus()


func _on_convoy_withdraw_pressed() -> void:
	var unit: UnitState = _get_selected_unit()
	if unit == null:
		return
	var convoy_entries: Array = GameState.get_convoy_items()
	if _selected_convoy_index < 0 or _selected_convoy_index >= convoy_entries.size():
		return
	var entry: Dictionary = convoy_entries[_selected_convoy_index]
	var item_id: String = str(entry.get("item_id", ""))
	if not unit.can_receive_item(item_id):
		_status_label.text = "%s cannot use that weapon type." % unit.display_name
		_refresh_convoy_modal()
		return
	var removed_entry: Dictionary = GameState.remove_convoy_item(_selected_convoy_index)
	if removed_entry.is_empty():
		return
	AudioDirector.play_sfx("menu_confirm")
	unit.add_item(item_id, int(removed_entry.get("uses", 0)))
	_selected_item_index = unit.inventory.size() - 1
	_selected_convoy_unit_item_index = _selected_item_index
	var updated_convoy_size: int = GameState.get_convoy_items().size()
	if updated_convoy_size <= 0:
		_selected_convoy_index = -1
	else:
		_selected_convoy_index = clampi(_selected_convoy_index, 0, updated_convoy_size - 1)
	_commit_roster()
	_refresh_view()
	_refresh_convoy_modal()
	_status_label.text = "%s withdraws %s from the convoy." % [unit.display_name, _get_item_name(item_id)]
	_convoy_unit_inventory_list.grab_focus()


func _on_convoy_close_pressed() -> void:
	_close_convoy_modal()


func _open_convoy_modal() -> void:
	if _get_selected_unit() == null:
		return
	AudioDirector.play_sfx("menu_confirm")
	_trade_modal.visible = false
	_convoy_modal.visible = true
	var unit: UnitState = _get_selected_unit()
	if unit == null or unit.inventory.is_empty():
		_selected_convoy_unit_item_index = -1
	else:
		var preferred_unit_index: int = _selected_item_index
		if preferred_unit_index < 0 or preferred_unit_index >= unit.inventory.size():
			preferred_unit_index = 0
		_selected_convoy_unit_item_index = preferred_unit_index
	var convoy_entries: Array = GameState.get_convoy_items()
	if convoy_entries.is_empty():
		_selected_convoy_index = -1
	else:
		_selected_convoy_index = clampi(_selected_convoy_index, 0, convoy_entries.size() - 1)
	_refresh_convoy_modal()
	if _selected_convoy_unit_item_index >= 0:
		_convoy_unit_inventory_list.grab_focus()
	elif _selected_convoy_index >= 0:
		_convoy_list.grab_focus()
	else:
		_convoy_close_button.grab_focus()
	_status_label.text = "Store extra gear or withdraw items for the selected ally."


func _close_convoy_modal(restore_status: bool = true) -> void:
	_convoy_modal.visible = false
	AudioDirector.play_sfx("menu_cancel")
	_selected_item_index = _selected_convoy_unit_item_index
	_refresh_inventory_list()
	_refresh_item_details()
	_refresh_buttons()
	if restore_status:
		_status_label.text = _default_status_text()
		_inventory_list.grab_focus()


func _refresh_convoy_modal() -> void:
	var unit: UnitState = _get_selected_unit()
	var convoy_entries: Array = GameState.get_convoy_items()
	_convoy_title.text = "Convoy"
	_convoy_description.text = "Shared storage between chapters. Stored items: %d" % convoy_entries.size()
	if unit == null:
		_convoy_unit_name.text = "No Ally Selected"
		_apply_portrait(null, _convoy_unit_portrait_texture, _convoy_unit_portrait_fallback, "No Ally")
		_convoy_unit_inventory_list.clear()
		_convoy_list.clear()
		_convoy_details.text = "Select an ally before using the convoy."
		_refresh_convoy_buttons()
		return
	_convoy_unit_name.text = unit.display_name
	_apply_portrait(unit, _convoy_unit_portrait_texture, _convoy_unit_portrait_fallback, unit.display_name)
	_convoy_unit_inventory_list.clear()
	for item_index in range(unit.inventory.size()):
		_convoy_unit_inventory_list.add_item(_format_inventory_entry(unit, item_index))
	if unit.inventory.is_empty():
		_selected_convoy_unit_item_index = -1
	else:
		_selected_convoy_unit_item_index = clampi(_selected_convoy_unit_item_index, 0, unit.inventory.size() - 1)
		_convoy_unit_inventory_list.select(_selected_convoy_unit_item_index)
	_convoy_list.clear()
	for entry in convoy_entries:
		var entry_item_id: String = str(entry.get("item_id", ""))
		var entry_uses: int = int(entry.get("uses", 0))
		_convoy_list.add_item("%s (%d uses)" % [_get_item_name(entry_item_id), entry_uses])
	if convoy_entries.is_empty():
		_selected_convoy_index = -1
	else:
		_selected_convoy_index = clampi(_selected_convoy_index, 0, convoy_entries.size() - 1)
		_convoy_list.select(_selected_convoy_index)
	_refresh_convoy_details()
	_refresh_convoy_buttons()


func _refresh_convoy_buttons() -> void:
	var unit: UnitState = _get_selected_unit()
	var convoy_entries: Array = GameState.get_convoy_items()
	_convoy_deposit_button.disabled = unit == null or _selected_convoy_unit_item_index < 0 or _selected_convoy_unit_item_index >= unit.inventory.size()
	var can_withdraw: bool = false
	if unit != null and _selected_convoy_index >= 0 and _selected_convoy_index < convoy_entries.size():
		can_withdraw = unit.can_receive_item(str(convoy_entries[_selected_convoy_index].get("item_id", "")))
	_convoy_withdraw_button.disabled = not can_withdraw


func _refresh_convoy_details() -> void:
	var unit: UnitState = _get_selected_unit()
	if unit == null:
		_convoy_details.text = "Select an ally before using the convoy."
		return
	var unit_entry_text: String = "No unit item selected."
	if _selected_convoy_unit_item_index >= 0 and _selected_convoy_unit_item_index < unit.inventory.size():
		unit_entry_text = "Store: %s" % _build_item_detail_text(str(unit.inventory[_selected_convoy_unit_item_index]), unit.get_item_uses_at(_selected_convoy_unit_item_index))
	var convoy_entry_text: String = "No convoy item selected."
	var convoy_entries: Array = GameState.get_convoy_items()
	if _selected_convoy_index >= 0 and _selected_convoy_index < convoy_entries.size():
		var convoy_entry: Dictionary = convoy_entries[_selected_convoy_index]
		var convoy_item_id: String = str(convoy_entry.get("item_id", ""))
		var convoy_uses: int = int(convoy_entry.get("uses", 0))
		var withdraw_note: String = "Ready to withdraw."
		if not unit.can_receive_item(convoy_item_id):
			withdraw_note = "This ally cannot carry that weapon type."
		convoy_entry_text = "Withdraw: %s\n%s" % [_build_item_detail_text(convoy_item_id, convoy_uses), withdraw_note]
	_convoy_details.text = "%s\n\n%s" % [unit_entry_text, convoy_entry_text]


func _get_selected_unit() -> UnitState:
	if _selected_unit_index < 0 or _selected_unit_index >= _units.size():
		return null
	return _units[_selected_unit_index]


func _get_selected_target() -> UnitState:
	if _selected_target_index < 0 or _selected_target_index >= _units.size():
		return null
	return _units[_selected_target_index]


func _can_open_trade_modal() -> bool:
	var unit: UnitState = _get_selected_unit()
	if unit == null or _selected_item_index < 0 or _selected_item_index >= unit.inventory.size():
		return false
	for index in range(_units.size()):
		if index == _selected_unit_index:
			continue
		if _units[index].can_receive_item(str(unit.inventory[_selected_item_index])):
			return true
	return false


func _ensure_valid_target_selection() -> void:
	if _units.is_empty():
		_selected_target_index = 0
		return
	_selected_target_index = clampi(_selected_target_index, 0, _units.size() - 1)
	if _units.size() == 1:
		return
	if _selected_target_index == _selected_unit_index:
		_selected_target_index = (_selected_unit_index + 1) % _units.size()


func _refresh_deployment_details() -> void:
	var unit: UnitState = _get_selected_unit()
	if _deployment_slots.is_empty():
		_deployment_details.text = "This chapter has fixed starting positions."
		return
	var slot_index: int = clampi(_selected_deployment_index, 0, _deployment_slots.size() - 1)
	var slot_position: Vector2i = _deployment_slots[slot_index]
	var occupying_unit: UnitState = _get_unit_assigned_to_slot(slot_position)
	var occupant_name: String = "Open"
	if occupying_unit != null:
		occupant_name = occupying_unit.display_name
	var selected_name: String = "No unit selected"
	if unit != null:
		selected_name = unit.display_name
	_deployment_details.text = "Selected ally: %s\nChosen slot: (%d, %d)\nCurrent occupant: %s\nPress Assign Selected to move or swap the start position." % [
		selected_name,
		slot_position.x,
		slot_position.y,
		occupant_name,
	]


func _get_assigned_slot_for_unit(unit_id: String) -> Vector2i:
	if not _deployment_assignments.has(unit_id):
		return Vector2i(-1, -1)
	return _vector2i_from_variant(_deployment_assignments.get(unit_id, Vector2i(-1, -1)))


func _get_unit_assigned_to_slot(slot_position: Vector2i) -> UnitState:
	for unit in _units:
		if unit == null:
			continue
		if _get_assigned_slot_for_unit(unit.unit_id) == slot_position:
			return unit
	return null


func _format_deployment_tag(unit_id: String) -> String:
	var slot: Vector2i = _get_assigned_slot_for_unit(unit_id)
	if slot == Vector2i(-1, -1):
		return "  [Bench]"
	return "  @ (%d,%d)" % [slot.x, slot.y]


func _format_deployment_label(unit_id: String) -> String:
	var slot: Vector2i = _get_assigned_slot_for_unit(unit_id)
	if slot == Vector2i(-1, -1):
		return "Bench"
	return "(%d, %d)" % [slot.x, slot.y]


func _format_inventory_entry(unit: UnitState, item_index: int) -> String:
	var item_id: String = str(unit.inventory[item_index])
	var uses: int = unit.get_item_uses_at(item_index)
	return "%s (%d uses)" % [_get_item_name(item_id), uses]


func _build_item_detail_text(item_id: String, uses: int) -> String:
	var weapon: WeaponData = DataRegistry.get_weapon_data(item_id)
	if weapon != null:
		return "%s\nType: %s\nRange: %d-%d\nUses: %d" % [
			weapon.name,
			weapon.weapon_type.capitalize(),
			weapon.min_range,
			weapon.max_range,
			uses,
		]
	var item: ItemData = DataRegistry.get_item_data(item_id)
	if item != null:
		return "%s\nType: %s\nUses: %d" % [
			item.name,
			item.item_type.capitalize(),
			uses,
		]
	return "%s\nUses: %d" % [item_id.capitalize(), uses]


func _get_item_name(item_id: String) -> String:
	var weapon: WeaponData = DataRegistry.get_weapon_data(item_id)
	if weapon != null:
		return weapon.name
	var item: ItemData = DataRegistry.get_item_data(item_id)
	if item != null:
		return item.name
	return item_id.capitalize()


func _build_objective_text() -> String:
	if _chapter == null:
		return "Prepare for battle."
	var deployment_limit: int = int(_chapter.deployment_unit_limit)
	var deployment_text: String = ""
	if deployment_limit > 0:
		deployment_text = "\nDeploy up to %d allies." % deployment_limit
	if _chapter.objective_type == "survive_turns":
		return "Objective: Survive %d turns or defeat the boss.%s" % [_chapter.objective_turns, deployment_text]
	return "Objective: %s.%s" % [_chapter.objective_type.replace("_", " ").capitalize(), deployment_text]


func _default_status_text() -> String:
	return "Set gear, use trade or convoy storage, and assign starting positions before you begin the battle."


func _maybe_show_preparation_tutorial() -> void:
	if _chapter_id != "chapter_1":
		return
	if not GameState.should_show_tutorial("prep_basics"):
		return
	GameState.mark_tutorial_seen("prep_basics")
	_show_tutorial_overlay([
		{
			"title": "Preparation Basics",
			"body": "This screen is your staging ground before battle.\n\n- Reorder weapons to change what a unit equips.\n- Trade passes the selected item directly to another ally.\n- Assign starting positions here when the map allows it.",
		},
		{
			"title": "Convoy, Shops, and Durability",
			"body": "Convoy stores spare weapons and items between chapters.\n\nWeapons, tomes, and staves lose 1 use when they are used. If their uses hit 0, they break.\n\nLater maps have Store tiles where your army spends shared gold on potions and weapon upgrades.",
		},
	])


func _show_tutorial_overlay(pages: Array[Dictionary]) -> void:
	if _active_tutorial != null:
		return
	var tutorial_overlay = TUTORIAL_OVERLAY_SCENE.instantiate()
	tutorial_overlay.setup(pages)
	tutorial_overlay.tutorial_finished.connect(Callable(self, "_on_tutorial_overlay_finished"))
	_active_tutorial = tutorial_overlay
	add_child(tutorial_overlay)


func _on_tutorial_overlay_finished() -> void:
	if _active_tutorial != null:
		_active_tutorial.queue_free()
		_active_tutorial = null
	if _units.is_empty():
		_begin_button.grab_focus()
	else:
		_unit_list.grab_focus()


func _apply_portrait(unit: UnitState, texture_rect: TextureRect, fallback_label: Label, fallback_text: String) -> void:
	if texture_rect == null or fallback_label == null:
		return
	var portrait: Texture2D = _load_portrait_for_unit(unit)
	texture_rect.texture = portrait
	texture_rect.visible = portrait != null
	fallback_label.text = fallback_text
	fallback_label.visible = portrait == null


func _load_portrait_for_unit(unit: UnitState) -> Texture2D:
	if unit == null:
		return null
	if not unit.portrait_id.is_empty():
		var portrait: Texture2D = _load_portrait_by_id(unit.portrait_id)
		if portrait != null:
			return portrait
	return _load_portrait_by_id(unit.unit_id)


func _load_portrait_by_id(portrait_id: String) -> Texture2D:
	if portrait_id.is_empty():
		return null
	var path: String = _resolve_portrait_path(portrait_id)
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


func _resolve_portrait_path(portrait_id: String) -> String:
	var exact_path: String = "%s/%s.png" % [PORTRAIT_DIR, portrait_id]
	if ResourceLoader.exists(exact_path):
		return exact_path
	var portrait_key: String = portrait_id.to_lower()
	for file_name in DirAccess.get_files_at(PORTRAIT_DIR):
		if file_name.get_extension().to_lower() != "png":
			continue
		if file_name.get_basename().to_lower() == portrait_key:
			return "%s/%s" % [PORTRAIT_DIR, file_name]
	return exact_path


func _vector2i_from_variant(value: Variant) -> Vector2i:
	if value is Vector2i:
		return value
	if typeof(value) == TYPE_DICTIONARY:
		var dictionary: Dictionary = value
		return Vector2i(int(dictionary.get("x", 0)), int(dictionary.get("y", 0)))
	return Vector2i.ZERO


func _serialize_vector2i(value: Vector2i) -> Dictionary:
	return {
		"x": value.x,
		"y": value.y,
	}
