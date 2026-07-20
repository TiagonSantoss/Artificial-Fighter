class_name WeaponAttackComponent
extends WeaponComponent

#const PROJECTILE_SCENE = preload("res://Core/Combat/Projectile/Projectile.tscn")
const MELEE_SCENE = preload("res://Core/Combat/Projectile/Melee/Melee.tscn")

var can_fire := true
var fire_cooldown := 0.0


func _physics_process(delta: float) -> void:
	if fire_cooldown > 0.0:
		fire_cooldown -= delta


func _create_attack_context(direction: Vector3) -> WeaponAttackContext:
	var context := WeaponAttackContext.new()

	context.weapon = weapon
	context.wielder = weapon.wielder
	context.origin = weapon.visual_component.muzzle.global_position
	context.recoil = weapon.definition.recoil

	context.attack_type = (
		WeaponAttackContext.AttackType.MELEE
		if weapon.definition.is_melee
		else WeaponAttackContext.AttackType.PROJECTILE
	)

	if weapon.definition.is_melee:
		var shot := AttackShot.new()

		shot.direction = direction.normalized()
		shot.damage_multiplier = weapon.damage_multiplier
		shot.knockback_multiplier = weapon.knockback_multiplier
		shot.pierce_multiplier = weapon.pierce_multiplier
		shot.speed_multiplier = weapon.speed_multiplier if "speed_multiplier" in weapon else 1.0
		shot.melee = weapon.definition.melee

		context.add_shot(shot)

	else:
		for i in weapon.definition.projectile_count:
			var shot := AttackShot.new()

			shot.direction = _spread_direction(
				direction, i, weapon.definition.projectile_count, weapon.definition.spread
			)

			shot.damage_multiplier = weapon.damage_multiplier
			shot.knockback_multiplier = weapon.knockback_multiplier
			shot.pierce_multiplier = weapon.pierce_multiplier
			shot.speed_multiplier = weapon.speed_multiplier
			shot.projectile = weapon.definition.projectile

			context.add_shot(shot)

	return context


func _spread_direction(
	base_direction: Vector3, index: int, projectile_count: int, spread: float
) -> Vector3:
	base_direction = base_direction.normalized()

	if projectile_count <= 1:
		return base_direction

	var t := float(index) / float(projectile_count - 1)
	var angle = lerp(-spread * 0.5, spread * 0.5, t)

	return base_direction.rotated(Vector3.UP, deg_to_rad(angle)).normalized()


func use(direction: Vector3) -> void:
	if weapon.definition.is_melee:
		swing(direction)
	else:
		fire(direction)


func fire(direction: Vector3):
	if weapon.wielder == null:
		push_error("Weapon fired without wielder (setup missing)")
		return

	if fire_cooldown > 0.0 or not can_fire:
		return

	can_fire = false
	fire_cooldown = weapon.definition.fire_rate

	var context := _create_attack_context(direction)

	weapon.behavior_component.before_attack(context)

	if context.cancelled:
		can_fire = true
		return

	for shot in context.shots:
		var request := ProjectileRequest.new()

		request.position = weapon.visual_component.muzzle.global_position
		request.direction = shot.direction

		request.definition = weapon.definition.projectile
		request.source_entity = weapon.wielder
		request.source_team = weapon.wielder.team

		request.damage_multiplier = shot.damage_multiplier
		request.knockback_multiplier = shot.knockback_multiplier

		# 🟢 SAFE PASSING: Check if your custom Request resource handles properties dynamically
		if "speed_multiplier" in request:
			request.speed_multiplier = shot.speed_multiplier
		if (
			"projectile_size_multiplier" in request
			and "projectile_size_multiplier" in weapon.definition
		):
			request.projectile_size_multiplier = weapon.definition.projectile_size_multiplier

		# Spawn the resource container via your system
		var projectile = AutoProjectileSystem.spawn(request)

		# 🟢 SAFE FALLBACK: If your returned data object holds a reference to the 3D scene instance
		# (commonly named 'node', 'instance', or 'scene_node'), scale that instead!
		if projectile != null:
			if "node" in projectile and projectile.node != null:
				projectile.node.scale *= weapon.definition.projectile_size_multiplier
			elif "instance" in projectile and projectile.instance != null:
				projectile.instance.scale *= weapon.definition.projectile_size_multiplier

		weapon.behavior_component.on_projectile_spawned(context, shot, projectile)

	var recoil_dir := -direction.normalized()
	context.wielder.movement_component.apply_impulse(recoil_dir * context.recoil)

	weapon.behavior_component.after_attack(context)

	weapon.audio_component.play_shoot(weapon.definition.shoot_sound)

	await get_tree().create_timer(weapon.definition.fire_rate).timeout
	can_fire = true


func swing(direction: Vector3):
	if weapon.wielder == null:
		push_error("Weapon swung without wielder (setup missing)")
		return

	if fire_cooldown > 0.0 or not can_fire:
		return

	can_fire = false
	fire_cooldown = weapon.definition.fire_rate

	var context := _create_attack_context(direction)

	weapon.behavior_component.before_attack(context)

	if context.cancelled:
		can_fire = true
		return

	for shot in context.shots:
		var melee_strike: Melee = MELEE_SCENE.instantiate()

		get_tree().current_scene.add_child(melee_strike)

		melee_strike.setup(
			context.origin,
			shot.direction,
			shot.melee,
			context.wielder,
			context.wielder.team,
			shot.damage_multiplier,
			shot.knockback_multiplier
		)

		if "speed_multiplier" in melee_strike:
			melee_strike.speed_multiplier = shot.speed_multiplier

		weapon.behavior_component.on_melee_spawned(context, shot, melee_strike)

	var lunge_dir := -direction.normalized()
	context.wielder.movement_component.apply_impulse(lunge_dir * context.recoil)

	weapon.behavior_component.after_attack(context)

	await get_tree().create_timer(weapon.definition.fire_rate).timeout
	can_fire = true
