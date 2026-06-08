class_name ItemDefinition
extends Resource

@export var id: StringName
@export var display_name: String
@export var description: String
@export var icon: Texture2D

func create_instance() -> ItemInstance:
	var instance := ItemInstance.new()
	instance.definition = self
	return instance
