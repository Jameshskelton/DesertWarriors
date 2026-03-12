extends RefCounted
class_name ItemService


func can_use_any_item(unit: UnitState) -> bool:
	return get_first_usable_item_index(unit) != -1


func get_first_usable_item_index(unit: UnitState) -> int:
	if unit == null or not unit.is_alive():
		return -1
	for item_index in range(unit.inventory.size()):
		var item_id: String = str(unit.inventory[item_index])
		if DataRegistry.get_weapon_data(item_id) != null:
			continue
		if _can_use_item(unit, item_index):
			return item_index
	return -1


func use_first_item(unit: UnitState) -> Dictionary:
	var item_index: int = get_first_usable_item_index(unit)
	if item_index == -1:
		return {}
	return use_item(unit, item_index)


func use_item(unit: UnitState, item_index: int) -> Dictionary:
	if unit == null or not unit.is_alive():
		return {}
	if item_index < 0 or item_index >= unit.inventory.size():
		return {}
	var item_id: String = str(unit.inventory[item_index])
	var item: ItemData = DataRegistry.get_item_data(item_id)
	if item == null:
		return {}
	if item.item_type == "healing":
		var previous_hp: int = unit.get_current_hp()
		unit.set_current_hp(unit.get_current_hp() + int(item.heal_amount))
		var actual_heal: int = unit.get_current_hp() - previous_hp
		if actual_heal <= 0:
			return {}
		if not unit.consume_item_use(item_index):
			return {}
		return {
			"item_id": item.id,
			"item_name": item.name,
			"user_name": unit.display_name,
			"heal_amount": actual_heal,
		}
	return {}


func _can_use_item(unit: UnitState, item_index: int) -> bool:
	if item_index < 0 or item_index >= unit.inventory.size():
		return false
	var item_id: String = str(unit.inventory[item_index])
	var item: ItemData = DataRegistry.get_item_data(item_id)
	if item == null or unit.get_item_uses_at(item_index) <= 0:
		return false
	if item.item_type == "healing":
		return unit.get_current_hp() < unit.get_max_hp()
	return false
