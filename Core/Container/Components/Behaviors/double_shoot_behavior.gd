class_name DoubleShotBehavior
extends BehaviorDefinition

@export_range(-180.0, 180.0)
var angle := 10.0

func before_attack(context: WeaponAttackContext, _instance: ItemInstance):
	var extra: Array[AttackShot] = []
	
	for shot in context.shots:
		var clone = shot.clone()
		
		clone.direction = clone.direction.rotated(
			Vector3.UP,
			deg_to_rad(angle)
		).normalized()
		
		extra.append(clone)
	
	for shot in extra:
		context.add_shot(shot)
