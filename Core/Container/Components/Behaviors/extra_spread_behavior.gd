class_name ExtraSpreadBehavior
extends BehaviorDefinition

@export_range(0.0, 45.0)
var spread := 10.0

func before_attack(context: WeaponAttackContext, _instance: ItemInstance):
	for shot in context.shots:
		var angle := deg_to_rad(
			randf_range(-spread, spread)
		)
		
		shot.direction = shot.direction.rotated(
			Vector3.UP,
			angle
		).normalized()
