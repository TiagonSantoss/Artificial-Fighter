class_name DamageCardDefinition
extends EffectDefinition

@export var damage_mult := 1.5

func on_added(entity: Entity, _instace: ItemInstance):
	entity.weapon_component.equipped_weapon.damage_multiplier *= damage_mult

func on_removed(entity: Entity, _instance: ItemInstance) -> void:
	entity.weapon_component.equipped_weapon.damage_multiplier /= damage_mult
