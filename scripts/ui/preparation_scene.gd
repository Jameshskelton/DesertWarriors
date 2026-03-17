extends Control

signal battle_requested(chapter_id: String)
signal return_to_title

const PORTRAIT_DIR := "res://assets/portraits"

var _chapter_id: String = ""
var _chapter: ChapterData
var _units: Array[UnitState] = []
var _selected_unit_index: int = 0
var _selected_item_index: int = -1
var _selected_target_index: int = 0
var _trade_target_indices: Array[int] = []

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


func setup(chapter_id: String) -> void:
	_chapter_id = chapter_id


func _ready() -> void:
	_connect_signals()
	_configure_focus_navigation()
	_trade_modal.visible = false
	_load_preparation_data()
	_refresh_view()
	if _units.is_empty():
		_begin_button.grab_focus()
	else:
		_unit_list.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if _trade_modal.visible:
			_close_trade_modal()
			return
		return_to_title.emit()
	if not _trade_modal.visible and event.is_action_pressed("ui_accept") and _inventory_list.has_focus() and _selected_item_index >= 0:
		_on_inventory_activated(_selected_item_index)
		get_viewport().set_input_as_handled()


func _connect_signals() -> void:
	_unit_list.item_selected.connect(Callable(self, "_on_unit_selected"))
	_inventory_list.item_selected.connect(Callable(self, "_on_inventory_selected"))
	_inventory_list.item_activated.connect(Callable(self, "_on_inventory_activated"))
	_move_up_button.pressed.connect(Callable(self, "_on_move_up_pressed"))
	_move_down_button.pressed.connect(Callable(self, "_on_move_down_pressed"))
	_transfer_button.pressed.connect(Callable(self, "_on_transfer_pressed"))
	_begin_button.pressed.connect(Callable(self, "_on_begin_pressed"))
	_return_button.pressed.connect(Callable(self, "_on_return_pressed"))
	_trade_target_list.item_selected.connect(Callable(self, "_on_trade_target_selected"))
	_trade_confirm_button.pressed.connect(Callable(self, "_on_trade_confirm_pressed"))
	_trade_cancel_button.pressed.connect(Callable(self, "_on_trade_cancel_pressed"))


func _configure_focus_navigation() -> void:
	_move_up_button.focus_neighbor_top = _inventory_list.get_path()
	_move_down_button.focus_neighbor_top = _inventory_list.get_path()
	_transfer_button.focus_neighbor_top = _inventory_list.get_path()
	_inventory_list.focus_neighbor_bottom = _transfer_button.get_path()
	_move_up_button.focus_neighbor_right = _move_down_button.get_path()
	_move_down_button.focus_neighbor_left = _move_up_button.get_path()
	_move_down_button.focus_neighbor_right = _transfer_button.get_path()
	_transfer_button.focus_neighbor_left = _move_down_button.get_path()
	_trade_target_list.focus_neighbor_bottom = _trade_confirm_button.get_path()
	_trade_confirm_button.focus_neighbor_top = _trade_target_list.get_path()
	_trade_cancel_button.focus_neighbor_top = _trade_target_list.get_path()
	_trade_confirm_button.focus_neighbor_right = _trade_cancel_button.get_path()
	_trade_cancel_button.focus_neighbor_left = _trade_confirm_button.get_path()


func _load_preparation_data() -> void:
	_chapter = DataRegistry.get_chapter_data(_chapter_id)
	_units = GameState.build_preparation_roster(_chapter_id)
	_selected_unit_index = clampi(_selected_unit_index, 0, maxi(0, _units.size() - 1))
	_selected_item_index = -1
	_selected_target_index = clampi(_selected_target_index, 0, maxi(0, _units.size() - 1))
	_trade_target_indices.clear()
	_ensure_valid_target_selection()


func _refresh_view() -> void:
	var chapter_name: String = _chapter.display_name if _chapter != null else _chapter_id
	_title_label.text = "Preparation"
	_subtitle_label.text = "%s\n%s" % [chapter_name, _build_objective_text()]
	_gold_label.text = "Gold: %d" % GameState.gold
	_refresh_unit_list()
	_refresh_inventory_list()
	_refresh_unit_summary()
	_refresh_unit_portrait()
	_refresh_item_details()
	_refresh_buttons()
	if _trade_modal.visible:
		_refresh_trade_modal()
	if _units.is_empty():
		_status_label.text = "No allied units are available for this chapter."
	else:
		_status_label.text = _default_status_text()


func _refresh_unit_list() -> void:
	_unit_list.clear()
	for unit in _units:
		_unit_list.add_item("%s  Lv.%d  HP %d/%d" % [
			unit.display_name,
			unit.level,
			unit.get_current_hp(),
			unit.get_max_hp(),
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
	_unit_summary.text = "Class: %s\nLevel: %d\nHP: %d / %d\nEquipped: %s\nPotions: %d" % [
		unit.class_id.capitalize(),
		unit.level,
		unit.get_current_hp(),
		unit.get_max_hp(),
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
		var equipped_tag: String = "Equipped weapon" if _selected_item_index == unit.get_equipped_weapon_index() else "Carried weapon"
		_item_details.text = "%s\nType: %s\nUses: %d\n%s" % [
			weapon.name,
			weapon.weapon_type.capitalize(),
			uses,
			equipped_tag,
		]
		return
	var item: ItemData = DataRegistry.get_item_data(item_id)
	if item != null:
		_item_details.text = "%s\nType: %s\nUses: %d" % [
			item.name,
			item.item_type.capitalize(),
			uses,
		]
		return
	_item_details.text = "%s\nUses: %d" % [item_id, uses]


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


func _on_inventory_activated(index: int) -> void:
	var unit: UnitState = _get_selected_unit()
	if unit == null or unit.inventory.is_empty():
		return
	_selected_item_index = clampi(index, 0, unit.inventory.size() - 1)
	_refresh_item_details()
	_refresh_buttons()
	if not _transfer_button.disabled:
		_transfer_button.grab_focus()
		_status_label.text = "Trade ready. Press Space or Enter on Trade to choose a partner."
	elif not _move_down_button.disabled:
		_move_down_button.grab_focus()
	elif not _move_up_button.disabled:
		_move_up_button.grab_focus()


func _on_move_up_pressed() -> void:
	var unit: UnitState = _get_selected_unit()
	if unit == null:
		return
	if not unit.move_item(_selected_item_index, _selected_item_index - 1):
		return
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
	_selected_item_index += 1
	_commit_roster()
	_refresh_view()
	_status_label.text = "%s reorganizes their pack." % unit.display_name


func _on_transfer_pressed() -> void:
	_open_trade_modal()


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
	battle_requested.emit(_chapter_id)


func _on_return_pressed() -> void:
	return_to_title.emit()


func _commit_roster() -> void:
	GameState.store_preparation_roster(_units)
	SaveSystem.save_game(GameState.build_save_payload())


func _open_trade_modal() -> void:
	if not _can_open_trade_modal():
		return
	_trade_modal.visible = true
	_refresh_trade_modal()
	_trade_target_list.grab_focus()
	_status_label.text = "Choose which ally should receive the selected item."


func _close_trade_modal(restore_status: bool = true) -> void:
	_trade_modal.visible = false
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
		var suffix: String = "" if can_receive else " (Can't carry)"
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


func _format_inventory_entry(unit: UnitState, item_index: int) -> String:
	var item_id: String = str(unit.inventory[item_index])
	var uses: int = unit.get_item_uses_at(item_index)
	return "%s (%d uses)" % [_get_item_name(item_id), uses]


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
	if _chapter.objective_type == "survive_turns":
		return "Objective: Survive %d turns or defeat the boss." % _chapter.objective_turns
	return "Objective: %s." % _chapter.objective_type.replace("_", " ").capitalize()


func _default_status_text() -> String:
	return "Review gear, press Space on an item to reach Trade, then click Begin Battle."


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
