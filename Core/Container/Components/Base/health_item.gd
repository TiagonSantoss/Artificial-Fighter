class_name HealItemDefinition
extends ItemDefinition

@export var heal_amount := 25.0
@export_range(0.0, 1.0) var heal_percent := 0.0  # extra, as a fraction of max health


# Returns true if the item was used up and should disappear
func on_pickup(entity: Entity, _instance: ItemInstance) -> bool:
	var health := entity.health_component
	if health == null:
		return false

	var amount := heal_amount + health.max_health * heal_percent
	return health.heal(amount) > 0.0
