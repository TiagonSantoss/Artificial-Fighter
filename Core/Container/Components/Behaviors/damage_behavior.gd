class_name DamageBehavior
extends BehaviorDefinition

@export var multiplier := 1.5

func before_attack(context: WeaponAttackContext, _instance: ItemInstance):
	for shot in context.shots:
		shot.damage_multiplier *= multiplier
