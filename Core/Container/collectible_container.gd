class_name CollectibleContainer
extends RefCounted
##Base Class for the Container Sytem.

signal added(instance: ItemInstance)
signal removed(instance: ItemInstance)

var max_size := 999

var contents: Array[ItemInstance] = []


func _init(containerSize := 999):
	max_size = containerSize


func add(instance: ItemInstance) -> bool:
	if is_full():
		return false

	contents.append(instance)
	added.emit(instance)

	return true


func remove(instance: ItemInstance) -> bool:
	var index := contents.find(instance)

	if index == -1:
		return false

	contents.remove_at(index)
	removed.emit(instance)

	return true


func is_full() -> bool:
	return contents.size() >= max_size


func size() -> int:
	return contents.size()


func is_empty() -> bool:
	return contents.is_empty()


func clear() -> void:
	for instance in contents:
		removed.emit(instance)

	contents.clear()


func contains(instance: ItemInstance) -> bool:
	return contents.has(instance)


func get_at(index: int) -> ItemInstance:
	if index < 0 or index >= contents.size():
		return null

	return contents[index]


func remove_at(index: int) -> ItemInstance:
	if index < 0 or index >= contents.size():
		return null

	var instance := contents[index]

	contents.remove_at(index)
	removed.emit(instance)

	return instance


func remove_definition(definition: ItemDefinition) -> bool:
	for instance in contents:
		if instance.definition == definition:
			return remove(instance)

	return false


func remove_first_definition(definition: ItemDefinition) -> ItemInstance:
	for instance in contents:
		if instance.definition == definition:
			remove(instance)
			return instance

	return null


func get_all(definition: ItemDefinition) -> Array[ItemInstance]:
	var result: Array[ItemInstance] = []

	for instance in contents:
		if instance.definition == definition:
			result.append(instance)
	return result


func contains_definition(definition: ItemDefinition) -> bool:
	for instance in contents:
		if instance.definition == definition:
			return true

	return false


func count_definition(definition: ItemDefinition) -> int:
	var total := 0

	for instance in contents:
		if instance.definition == definition:
			total += instance.stacks

	return total


func get_contents() -> Array[ItemInstance]:
	return contents.duplicate()


func get_random() -> ItemInstance:
	if contents.is_empty():
		return null

	return contents.pick_random()


func take_random() -> ItemInstance:
	if contents.is_empty():
		return null

	var instance = contents.pick_random()

	remove(instance)

	return instance


func transfer_to(instance: ItemInstance, other: CollectibleContainer) -> bool:
	if other == self:
		return true

	if not contains(instance):
		return false

	if not other.add(instance):
		return false

	remove(instance)

	return true
