class_name WorldItemSpawner

static func drop(instance: ItemInstance, position: Vector3, parent: Node) -> WorldItem:
	var scene := preload("res://Game/World/WorldItem.tscn")
	
	var item := scene.instantiate() as WorldItem
	
	parent.add_child(item)
	item.global_position = position
	
	item.set_instance(instance)
	
	return item
