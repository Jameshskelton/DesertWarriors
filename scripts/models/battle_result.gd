extends RefCounted
class_name BattleResult

var strikes: Array[Dictionary] = []
var attacker_hp_delta: int = 0
var defender_hp_delta: int = 0
var attacker_ko: bool = false
var defender_ko: bool = false
var xp_awards: Dictionary = {}
var level_ups: Array[Dictionary] = []
var triggered_events: PackedStringArray = PackedStringArray()


func to_dictionary() -> Dictionary:
	return {
		"strikes": strikes,
		"attacker_hp_delta": attacker_hp_delta,
		"defender_hp_delta": defender_hp_delta,
		"attacker_ko": attacker_ko,
		"defender_ko": defender_ko,
		"xp_awards": xp_awards,
		"level_ups": level_ups,
		"triggered_events": triggered_events,
	}
