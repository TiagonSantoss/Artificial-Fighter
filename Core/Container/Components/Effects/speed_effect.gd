class_name SpeedEffect
extends EffectDefinition

@export var speed_multiplier := 1.15


func on_added(entity: Entity, _instance: ItemInstance) -> void:
	if entity.movement_component:
		entity.movement_component.move_speed *= speed_multiplier
		entity.movement_component.max_speed *= speed_multiplier


func on_removed(entity: Entity, _instance: ItemInstance) -> void:
	if entity.movement_component:
		entity.movement_component.move_speed /= speed_multiplier
		entity.movement_component.max_speed /= speed_multiplier
