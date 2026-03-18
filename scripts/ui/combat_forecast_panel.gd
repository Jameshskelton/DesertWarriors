extends PanelContainer

@onready var _title: Label = $Margin/VBox/TitleLabel
@onready var _attacker: Label = $Margin/VBox/AttackerLabel
@onready var _defender: Label = $Margin/VBox/DefenderLabel
@onready var _terrain: Label = $Margin/VBox/TerrainLabel
@onready var _warning: Label = $Margin/VBox/WarningLabel


func show_battle_forecast(attacker: UnitState, defender: UnitState, forecast: CombatForecast, terrain: TerrainData) -> void:
	visible = true
	_title.text = "Forecast"
	_attacker.text = "%s  DMG %d  HIT %d  CRT %d\n%s\n%s\n%s" % [
		attacker.display_name,
		forecast.attacker_damage,
		forecast.attacker_hit,
		forecast.attacker_crit,
		_format_weapon_status(attacker),
		_format_potion_status(attacker),
		_format_triangle_status(forecast.attacker_triangle_text),
	]
	_defender.text = "%s  DMG %d  HIT %d  CRT %d\n%s\n%s\n%s" % [
		defender.display_name,
		forecast.defender_damage,
		forecast.defender_hit,
		forecast.defender_crit,
		_format_weapon_status(defender),
		_format_potion_status(defender),
		_format_triangle_status(forecast.defender_triangle_text),
	]
	_terrain.text = "%s  AVO +%d  DEF +%d" % [terrain.name, terrain.avoid_bonus, terrain.def_bonus]
	_set_warning_text(_build_battle_warning(attacker, defender, forecast))


func show_heal_preview(healer: UnitState, target: UnitState, amount: int) -> void:
	visible = true
	_title.text = "Staff"
	_attacker.text = "%s heals %s\n%s\n%s" % [
		healer.display_name,
		target.display_name,
		_format_weapon_status(healer),
		_format_potion_status(healer),
	]
	_defender.text = "Heal %d  HP %d/%d\n%s" % [amount, target.get_current_hp(), target.get_max_hp(), _format_potion_status(target)]
	_terrain.text = "Support action"
	_set_warning_text(_build_next_use_warning(healer, "use"))


func hide_panel() -> void:
	visible = false
	_warning.visible = false


func _format_weapon_status(unit: UnitState) -> String:
	var weapon: WeaponData = DataRegistry.get_weapon_data(unit.get_equipped_weapon_id())
	if weapon == null:
		return "Weapon: Broken"
	return "Weapon: %s  %d/%d" % [weapon.name, unit.get_equipped_weapon_uses(), int(weapon.uses)]


func _format_potion_status(unit: UnitState) -> String:
	var potion_count: int = unit.get_available_item_count("health_potion")
	if potion_count <= 0:
		return "Potions: 0"
	if potion_count == 1:
		return "Potion: 1"
	return "Potions: %d" % potion_count


func _format_triangle_status(text: String) -> String:
	if text.is_empty():
		return "Triangle: Neutral"
	return "Triangle: %s" % text


func _build_battle_warning(attacker: UnitState, defender: UnitState, forecast: CombatForecast) -> String:
	var warnings: PackedStringArray = PackedStringArray()
	var attacker_warning: String = _build_next_use_warning(attacker, "attack")
	if not attacker_warning.is_empty():
		warnings.append("%s: %s" % [attacker.display_name, attacker_warning])
	if forecast.counter_allowed:
		var defender_warning: String = _build_next_use_warning(defender, "counter")
		if not defender_warning.is_empty():
			warnings.append("%s: %s" % [defender.display_name, defender_warning])
	return "\n".join(warnings)


func _build_next_use_warning(unit: UnitState, action_name: String) -> String:
	var weapon: WeaponData = DataRegistry.get_weapon_data(unit.get_equipped_weapon_id())
	if weapon == null or unit.get_equipped_weapon_uses() != 1:
		return ""
	return "%s breaks after this %s." % [weapon.name, action_name]


func _set_warning_text(text: String) -> void:
	_warning.text = text
	_warning.visible = not text.is_empty()
