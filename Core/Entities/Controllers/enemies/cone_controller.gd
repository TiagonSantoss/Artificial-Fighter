class_name ConeController

extends Controller

@export_category("Cone Settings")
@export var jump_interval := 1.5  # Time from one jump to the next
@export var recovery_duration := 5.0  # How long it stands perfectly still after landing
@export var attack_cooldown := 5.0  # How often it fires its weapon
@export var aggro_range := 40.0
@export var attack_range := 100.0
@export var warning_lead_time := 1.0  # seconds between warning and attack

var jump_cooldown_left := 0.0
var recovery_time_left := 0.0
var attack_cooldown_left := 0.0
var target: Entity

# Trackers

var was_in_air := false

var _winding_up := false
var _windup_left := 0.0


func get_actions(actor: Entity, delta: float) -> Array[Action]:
	var actions: Array[Action] = []

	# 1. CHECK LANDING: Start recovery ONLY when hitting the ground

	var is_grounded = (
		actor.is_on_floor() if actor.has_method("is_on_floor") else abs(actor.velocity.y) < 0.1
	)

	if not is_grounded:
		was_in_air = true

	elif was_in_air and is_grounded:
		# We just landed! Start the recovery pause now.

		was_in_air = false

		recovery_time_left = recovery_duration

	# 2. TICK TIMERS

	if jump_cooldown_left > 0.0:
		jump_cooldown_left -= delta

	if attack_cooldown_left > 0.0:
		attack_cooldown_left -= delta

	if recovery_time_left > 0.0:
		recovery_time_left -= delta

	if not is_instance_valid(target):
		return actions

	var dist_to_target = actor.global_position.distance_to(target.global_position)

	if recovery_time_left > 0.0:
		return actions

	# 4. COMBAT & TELEGRAPHING
	if dist_to_target <= attack_range:
		if _winding_up:
			_windup_left -= delta
			if _windup_left <= 0.0:
				_winding_up = false
				if has_clear_shot(actor):
					actions.append(AttackAction.new())
				attack_cooldown_left = attack_cooldown
		elif attack_cooldown_left <= 0.0 and has_clear_shot(actor):
			# Start telegraph, the attack comes later
			_winding_up = true
			_windup_left = warning_lead_time
			var spawn_pos := actor.global_position + Vector3(0.0, 1.5, 0.0)
			SceneManager.spawn_effect(SceneManager.Fx.WARNING, spawn_pos)
			FmodServer.play_one_shot("event:/SFX/UI/Warn")
	else:
		_winding_up = false  # target left range, cancel the wind-up

		# 5. MOVEMENT
	if dist_to_target <= aggro_range and not _winding_up:
		var dir_to_target := actor.global_position.direction_to(target.global_position)
		var flat_dir := Vector3(dir_to_target.x, 0, dir_to_target.z).normalized()

		if flat_dir.length_squared() > 0.001:
			actions.append(MovementAction.new(flat_dir))

		# Hop toward the player
		if jump_cooldown_left <= 0.0 and is_grounded:
			actions.append(JumpAction.new())
			jump_cooldown_left = jump_interval
	
	return actions


func update_aim(actor: Entity) -> void:
	if is_instance_valid(target):
		aim_target = target.global_position + Vector3(0, 1.0, 0)

		if is_instance_valid(actor.mesh_instance):
			var mesh := actor.mesh_instance

			if mesh.global_position.distance_squared_to(target.global_position) > 0.1:
				var look_pos = target.global_position

				# Pitch down if we are high in the air

				if actor.global_position.y <= target.global_position.y + 0.5:
					look_pos.y = mesh.global_position.y

				var target_transform := mesh.global_transform.looking_at(look_pos, Vector3.UP)

				target_transform = target_transform.rotated_local(Vector3.UP, PI)

				mesh.global_transform = mesh.global_transform.interpolate_with(
					target_transform, 0.1
				)


func has_clear_shot(actor: Entity) -> bool:
	if not is_instance_valid(target):
		return false

	var space_state := actor.get_world_3d().direct_space_state

	var origin := actor.global_position + Vector3(0, 0.5, 0)

	var target_center := target.global_position + Vector3(0, 1.0, 0)

	var query := PhysicsRayQueryParameters3D.create(origin, target_center)

	query.exclude = [actor.get_rid()]

	query.collision_mask = 3

	var result := space_state.intersect_ray(query)

	return result.is_empty() or result.collider == target
