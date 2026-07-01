class_name FlowerShotBehavior
extends BehaviorDefinition

@export var points_per_layer: int = 8
@export var spin_speed: float = 4.0

func before_attack(context: WeaponAttackContext, _instance: ItemInstance):
	if context.shots.is_empty():
		return
		
	var base_shot = context.shots[0]
	var extra: Array[AttackShot] = []
	var angle_step := (2.0 * PI) / float(points_per_layer)
	
	# Get a global time offset to animate the spin over time
	var time_offset = Time.get_ticks_msec() / 1000.0 * spin_speed
	
	# Layer 1: Clockwise Ring (Fast)
	for i in range(points_per_layer):
		var clone = base_shot.clone()
		# Add the positive time offset to rotate clockwise
		var current_angle = (angle_step * i) + time_offset
		
		clone.direction = base_shot.direction.rotated(Vector3.UP, current_angle).normalized()
		clone.speed_multiplier = base_shot.speed_multiplier * 1.0 # Normal speed
		extra.append(clone)
		
	# Layer 2: Counter-Clockwise Ring (Slower)
	var half_step := angle_step / 2.0
	for i in range(points_per_layer):
		var clone = base_shot.clone()
		# Subtract the time offset to force it to rotate counter-clockwise
		var current_angle = (angle_step * i) + half_step - time_offset
		
		clone.direction = base_shot.direction.rotated(Vector3.UP, current_angle).normalized()
		clone.speed_multiplier = base_shot.speed_multiplier * 0.65 # 35% Slower
		extra.append(clone)
		
	# Overwrite the base layout with our custom counter-rotating rings
	context.shots.clear()
	for shot in extra:
		context.add_shot(shot)
