class_name VortexHelixBehavior
extends BehaviorDefinition

@export_category("Helix Layout")
@export var strands: int = 3
@export var rotation_speed := 0.08

@export_category("Pacing & Fairness")
## How slow the bullets start out relative to their normal speed (e.g., 0.2 = 20% speed)
@export var initial_speed_mult := 0.2
## How fast they accelerate per second
@export var acceleration_rate := 2.5
## The absolute maximum speed multiplier they can scale up to
@export var max_speed_mult := 1.8
@export var bullet_spacing_delay := 3

var shot_counter: int = 0


func before_attack(context: WeaponAttackContext, _instance: ItemInstance) -> void:
	if context.shots.is_empty():
		return

	if shot_counter % bullet_spacing_delay != 0:
		context.shots.clear()
		shot_counter += 1
		return

	var base_shot = context.shots[0]
	var extra: Array[AttackShot] = []
	var angle_step := (2.0 * PI) / float(strands)

	var base_offset = shot_counter * rotation_speed
	shot_counter += 1

	for i in range(strands):
		var clone = base_shot.clone()
		var current_angle = (angle_step * i) + base_offset

		# 1. Establish the base direction path
		var target_dir = base_shot.direction.rotated(Vector3.UP, current_angle).normalized()
		clone.direction = target_dir

		# 2. Inject the slow starting multiplier straight into the creation context
		clone.speed_multiplier = initial_speed_mult

		extra.append(clone)

	context.shots.clear()
	for shot in extra:
		context.add_shot(shot)


func on_projectile_spawned(
	_context: WeaponAttackContext,
	_shot: AttackShot,
	projectile: Projectile,
	_instance: ItemInstance
) -> void:
	if is_instance_valid(projectile):
		projectile.set_meta("current_mult", initial_speed_mult)


# 🟢 Called every frame via your central processing update loop
func update_live_projectile(projectile: Projectile, delta: float, _instance: ItemInstance) -> void:
	if not is_instance_valid(projectile):
		return

	# Retrieve current working speed multiplier tracker from meta storage safely
	var current_mult: float = projectile.get_meta("current_mult", initial_speed_mult)

	if current_mult < max_speed_mult:
		# Gradually step the modifier values upwards over delta frame timings
		current_mult = move_toward(current_mult, max_speed_mult, acceleration_rate * delta)
		projectile.set_meta("current_mult", current_mult)

		# Directly modify the live velocity property vector since your architecture allows it
		var move_dir := projectile.velocity.normalized()
		var base_speed := projectile.definition.speed

		# Reconstruct velocity instantly on the fly
		projectile.velocity = move_dir * (base_speed * current_mult)
