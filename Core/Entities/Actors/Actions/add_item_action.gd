class_name AddItemAction
extends Action

var definition: ItemDefinition
var container: CollectibleContainer

func _init(p_definition: ItemDefinition, p_container: CollectibleContainer) -> void:
	definition = p_definition
	container = p_container

func execute(_actor: Entity, _delta: float) -> void:
	var instance := definition.create_instance()
	
	container.add(instance)
	print("added:", definition)
