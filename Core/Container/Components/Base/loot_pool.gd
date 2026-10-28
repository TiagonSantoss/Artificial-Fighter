class_name LootTable
extends Resource

@export var possible_items: Array[ItemDefinition] = []


func get_random_item() -> ItemDefinition:
	if possible_items.is_empty():
		return null
	return possible_items.pick_random()
