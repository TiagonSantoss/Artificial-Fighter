class_name AccessoriesComponent
extends EntityComponent

var accessories := CollectibleContainer.new(15)


func _ready() -> void:
	accessories.added.connect(_on_accessory_added)
	accessories.removed.connect(_on_accessory_removed)


func _on_accessory_added(instance: ItemInstance) -> void:
	var accessory := instance.definition as AccessoryDefinition
	if accessory != null:
		accessory.on_equip(entity, instance)


func _on_accessory_removed(instance: ItemInstance) -> void:
	var accessory := instance.definition as AccessoryDefinition
	if accessory != null:
		accessory.on_unequip(entity, instance)


func equip_accessory(instance: ItemInstance) -> bool:
	if instance == null or not (instance.definition is AccessoryDefinition):
		return false

	if accessories.is_full():
		return false

	return accessories.add(instance)


func unequip_accessory(instance: ItemInstance) -> bool:
	if instance == null:
		return false

	return accessories.remove(instance)
