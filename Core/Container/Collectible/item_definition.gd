class_name ItemDefinition
extends Resource

@export var id: StringName
@export var display_name: String
@export var description: String
@export var icon: Texture2D
@export var auto_despawns: bool = true


func create_instance() -> ItemInstance:
	var instance := ItemInstance.new()
	instance.definition = self
	return instance


func create_world_item(parent: Node, pos: Vector3) -> WorldItem:
	var item := preload("res://Game/World/WorldItem.tscn").instantiate()
	item.instance = create_instance()

	parent.add_child(item)
	item.global_position = pos
	return item
