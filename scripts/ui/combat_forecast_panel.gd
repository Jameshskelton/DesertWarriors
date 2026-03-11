extends PanelContainer

@onready var _title: Label = $Margin/VBox/TitleLabel
@onready var _attacker: Label = $Margin/VBox/AttackerLabel
@onready var _defender: Label = $Margin/VBox/DefenderLabel
@onready var _terrain: Label = $Margin/VBox/TerrainLabel


func show_battle_forecast(attacker: UnitState, defender: UnitState, forecast: CombatForecast, terrain: TerrainData) -> void:
	visible = true
	_title.text = "Forecast"
	_attacker.text = "%s  DMG %d  HIT %d  CRT %d" % [attacker.display_name, forecast.attacker_damage, forecast.attacker_hit, forecast.attacker_crit]
	_defender.text = "%s  DMG %d  HIT %d  CRT %d" % [defender.display_name, forecast.defender_damage, forecast.defender_hit, forecast.defender_crit]
	_terrain.text = "%s  AVO +%d  DEF +%d" % [terrain.name, terrain.avoid_bonus, terrain.def_bonus]


func show_heal_preview(healer: UnitState, target: UnitState, amount: int) -> void:
	visible = true
	_title.text = "Staff"
	_attacker.text = "%s heals %s" % [healer.display_name, target.display_name]
	_defender.text = "Heal %d  HP %d/%d" % [amount, target.get_current_hp(), target.get_max_hp()]
	_terrain.text = "Support action"


func hide_panel() -> void:
	visible = false
