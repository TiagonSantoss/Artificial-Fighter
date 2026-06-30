class_name TripleShotBehavior
extends BehaviorDefinition

@export var angle := 15.0

func before_attack(context: WeaponAttackContext,_instance: ItemInstance):
	var extra: Array[AttackShot] = []
	
	for shot in context.shots:
		var left = shot.duplicate()
		left.direction = left.direction.rotated(
			Vector3.UP,
			deg_to_rad(-angle)
		).normalized()
		
		var right = shot.duplicate()
		right.direction = right.direction.rotated(
			Vector3.UP,
			deg_to_rad(angle)
		).normalized()
		
		extra.append(left)
		extra.append(right)
	
	for shot in extra:
		context.add_shot(shot)
