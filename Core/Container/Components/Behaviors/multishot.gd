class_name MultishotBehavior
extends BehaviorDefinition

@export_category("Multishot Settings")
@export var extra_bullets: int = 1
@export var spread_angle: float = 15.0


func before_attack(context: WeaponAttackContext, _instance: ItemInstance) -> void:
	if context.shots.is_empty():
		return

	var original_shots = context.shots.duplicate()
	context.shots.clear()

	var angle_step = deg_to_rad(spread_angle)

	for base_shot in original_shots:
		var total_shots = 1 + extra_bullets

		var total_spread_arc = angle_step * (total_shots - 1)

		var start_angle = -(total_spread_arc / 2.0)

		for i in range(total_shots):
			var clone = base_shot.clone()
			var current_angle = start_angle + (angle_step * i)
			clone.direction = base_shot.direction.rotated(Vector3.UP, current_angle).normalized()
			context.add_shot(clone)
