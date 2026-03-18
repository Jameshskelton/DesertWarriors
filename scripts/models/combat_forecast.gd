extends RefCounted
class_name CombatForecast

var attacker_damage := 0
var attacker_hit := 0
var attacker_crit := 0
var defender_damage := 0
var defender_hit := 0
var defender_crit := 0
var counter_allowed := false
var attacker_follow_up := false
var defender_follow_up := false
var attacker_triangle_state := 0
var defender_triangle_state := 0
var attacker_triangle_text := ""
var defender_triangle_text := ""


func to_dictionary() -> Dictionary:
	return {
		"attacker_damage": attacker_damage,
		"attacker_hit": attacker_hit,
		"attacker_crit": attacker_crit,
		"defender_damage": defender_damage,
		"defender_hit": defender_hit,
		"defender_crit": defender_crit,
		"counter_allowed": counter_allowed,
		"attacker_follow_up": attacker_follow_up,
		"defender_follow_up": defender_follow_up,
		"attacker_triangle_state": attacker_triangle_state,
		"defender_triangle_state": defender_triangle_state,
		"attacker_triangle_text": attacker_triangle_text,
		"defender_triangle_text": defender_triangle_text,
	}
