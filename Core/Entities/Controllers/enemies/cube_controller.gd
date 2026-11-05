class_name CubeController
extends Controller

const ATTACK_RANGE := 120.0

@export var attack_cooldown := 1.7  # Time between attacks
@export var warning_lead_time := 0.4  # How many seconds before firing to show the warning

var cooldown_left := 0.0
var target: Entity
var _warning_played := false


func get_actions(actor: Entity, delta: float) -> Array[Action]:
	var actions: Array[Action] = []

	if not is_instance_valid(actor) or not is_instance_valid(target):
		return actions

	var dist_to_target := actor.global_position.distance_to(target.global_position)

	if dist_to_target <= ATTACK_RANGE and has_clear_shot(actor):
		# Tick down the cooldown timer
		if cooldown_left > 0.0:
			cooldown_left -= delta

			# TELEGRAPH: Play warning when the timer hits the warning threshold
			if cooldown_left <= warning_lead_time and not _warning_played:
				_warning_played = true
				SceneManager.spawn_effect(
					SceneManager.Fx.WARNING, actor.global_position + Vector3(0, 1.5, 0)
				)
				FmodServer.play_one_shot("event:/SFX/UI/EnemyWarn")

			# ATTACK: Fire when the timer reaches zero
			if cooldown_left <= 0.0:
				actions.append(AttackAction.new())
				# Reset for the next attack cycle
				cooldown_left = attack_cooldown
				_warning_played = false
		else:
			# Initialize the first attack cycle if cooldown hasn't started
			cooldown_left = attack_cooldown
			_warning_played = false
	else:
		# If out of range or blocked, gently decay the cooldown so it doesn't instantly fire when re-engaging
		if cooldown_left > 0.0:
			cooldown_left -= delta

	return actions


func update_aim(actor: Entity) -> void:
	if is_instance_valid(target):
		var target_center := target.global_position
		target_center.y = actor.global_position.y
		aim_target = target_center

		if is_instance_valid(actor.mesh_instance):
			var mesh := actor.mesh_instance
			if mesh.global_position.distance_squared_to(target_center) > 0.01:
				var target_transform := mesh.global_transform.looking_at(target_center, Vector3.UP)
				target_transform = target_transform.rotated_local(Vector3.UP, PI)
				mesh.global_transform = mesh.global_transform.interpolate_with(
					target_transform, 0.1
				)


func has_clear_shot(actor: Entity) -> bool:
	if not is_instance_valid(target):
		return false

	var space_state := actor.get_world_3d().direct_space_state
	var origin := actor.global_position
	var target_center := target.global_position

	var dir_to_target := origin.direction_to(target_center)
	var right_offset := Vector3.UP.cross(dir_to_target).normalized() * 0.4
	var target_points = [target_center, target_center + right_offset, target_center - right_offset]

	for point in target_points:
		var query := PhysicsRayQueryParameters3D.create(origin, point)
		query.exclude = [actor]
		query.collision_mask = 3
		var result := space_state.intersect_ray(query)

		if not result.is_empty() and result.collider == target:
			return true

	return false
