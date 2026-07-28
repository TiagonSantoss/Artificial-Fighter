class_name NaturalAccelerationBehavior
extends BehaviorDefinition

@export_category("Pacing & Fairness")
@export var initial_speed_mult := 1.0
@export var acceleration_rate := 2.5
@export var max_speed_mult := 1.8


func before_attack(context: WeaponAttackContext, _instance: ItemInstance) -> void:
	for shot in context.shots:
		shot.speed_multiplier = initial_speed_mult


func on_projectile_spawned(
	_context: WeaponAttackContext,
	_shot: AttackShot,
	projectile: Projectile,
	_instance: ItemInstance
) -> void:
	if is_instance_valid(projectile):
		projectile.set_meta("current_mult", initial_speed_mult)


func update_live_projectile(projectile: Projectile, delta: float, _instance: ItemInstance) -> void:
	if not is_instance_valid(projectile):
		return

	var current_mult: float = projectile.get_meta("current_mult", initial_speed_mult)

	if current_mult < max_speed_mult:
		current_mult = move_toward(current_mult, max_speed_mult, acceleration_rate * delta)
		projectile.set_meta("current_mult", current_mult)

		var move_dir := projectile.velocity.normalized()
		var base_speed := projectile.definition.speed

		projectile.velocity = move_dir * (base_speed * current_mult)
