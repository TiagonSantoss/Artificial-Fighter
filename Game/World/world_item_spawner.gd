class_name WorldItemSpawner


static func drop(
	instance: ItemInstance, position: Vector3, parent: Node = null, impulse: Vector3 = Vector3.ZERO
) -> WorldItem:
	var scene := load("res://Game/World/WorldItem.tscn") as PackedScene
	if scene == null:
		push_error("WorldItemSpawner: Could not load WorldItem.tscn")
		return null

	var item := scene.instantiate() as WorldItem
	if item == null:
		push_error("WorldItemSpawner: Failed to instantiate WorldItem")
		return null

	var target_parent := parent
	if target_parent == null:
		target_parent = Engine.get_main_loop().root.get_child(0)

	target_parent.add_child(item)
	item.global_position = position
	item.set_instance(instance)

	if impulse == Vector3.ZERO:
		impulse = Vector3(randf_range(-1.5, 1.5), randf_range(3.0, 5.0), randf_range(-1.5, 1.5))

	item.push_item(impulse)

	return item
