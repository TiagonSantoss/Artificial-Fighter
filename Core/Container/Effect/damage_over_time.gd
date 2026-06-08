class_name DamageOverTimeEffect
extends EffectDefinition

@export var damage_per_second: float

func update(entity: Entity, _instance: ItemInstance, delta: float) -> void:
	entity.health_component.damage(damage_per_second * delta)
	entity.visual_effects_component.flash_red(damage_per_second * delta)
