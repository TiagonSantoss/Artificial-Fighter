class_name RadialMultishotBehavior
extends BehaviorDefinition

@export_category("Radial Settings")
@export var total_directions: int = 2

@export var offset_degrees: float = 0.0


func before_attack(context: WeaponAttackContext, _instance: ItemInstance) -> void:
	if context.shots.is_empty():
		return

	var original_shots = context.shots.duplicate()
	context.shots.clear()

	# 2 * PI is exactly 360 degrees in radians.
	var angle_step = (2.0 * PI) / float(total_directions)
	var starting_offset = deg_to_rad(offset_degrees)

	for base_shot in original_shots:
		for i in range(total_directions):
			var clone = base_shot.clone()

			var current_angle = starting_offset + (angle_step * i)

			clone.direction = base_shot.direction.rotated(Vector3.UP, current_angle).normalized()

			context.add_shot(clone)
