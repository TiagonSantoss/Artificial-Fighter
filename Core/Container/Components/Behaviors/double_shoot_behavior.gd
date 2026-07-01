class_name FlowerShotBehavior
extends BehaviorDefinition

@export var points_per_layer: int = 6 # 🟢 Reduced from 8 to 6 for larger physical gaps
@export var spin_speed: float = 2.0 # 🟢 Slowed down rotation by half to make tracking easier
@export var layer_radius_spacing: float = 1.5 # 🟢 Pushes the spawn points outward from the center

func before_attack(context: WeaponAttackContext, _instance: ItemInstance):
	if context.shots.is_empty():
		return
		
	var base_shot = context.shots[0]
	var extra: Array[AttackShot] = []
	var angle_step := (2.0 * PI) / float(points_per_layer)
	
	# Get a global time offset to animate the spin over time
	var time_offset = Time.get_ticks_msec() / 1000.0 * spin_speed
	
	# Layer 1: Clockwise Ring
	for i in range(points_per_layer):
		var clone = base_shot.clone()
		var current_angle = (angle_step * i) + time_offset
		
		var target_dir = base_shot.direction.rotated(Vector3.UP, current_angle).normalized()
		clone.direction = target_dir
		clone.speed_multiplier = base_shot.speed_multiplier * 0.75 # 🟢 25% slower base speed
		
		# If your AttackShot setup has a position or offset property, use it here:
		if "spawn_offset" in clone:
			clone.spawn_offset = target_dir * layer_radius_spacing
			
		extra.append(clone)
		
	# Layer 2: Counter-Clockwise Ring
	var half_step := angle_step / 2.0
	for i in range(points_per_layer):
		var clone = base_shot.clone()
		var current_angle = (angle_step * i) + half_step - time_offset
		
		var target_dir = base_shot.direction.rotated(Vector3.UP, current_angle).normalized()
		clone.direction = target_dir
		clone.speed_multiplier = base_shot.speed_multiplier * 0.5 # 🟢 50% slower tracking layer
		
		# Pushes layer 2 even further out so they don't block the same lane instantly
		if "spawn_offset" in clone:
			clone.spawn_offset = target_dir * (layer_radius_spacing * 1.8)
			
		extra.append(clone)
		
	context.shots.clear()
	for shot in extra:
		context.add_shot(shot)
