extends Node
class_name BattleTransitionController

signal battle_overlay_requested(payload: Dictionary)

const FADE_TIME := 0.18


func begin_battle(payload: Dictionary) -> void:
	battle_overlay_requested.emit(payload)
