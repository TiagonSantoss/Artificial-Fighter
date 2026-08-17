class_name CubeController
extends Controller

const SHOOT_COOLDOWN := 1.5
const ATTACK_RANGE := 120.0

var cooldown_left := 0.0

var target: Entity


func get_actions(actor: Entity, delta: float) -> Array[Action]:
	var actions: Array[Action] = []

	# Tick down the shooting cooldown
	if cooldown_left > 0.0:
		cooldown_left -= delta

	# 'target' is automatically set in your Game.gd's spawn_enemy() function!
	if not is_instance_valid(target):
		return actions

	var dist_to_target := actor.global_position.distance_to(target.global_position)

	# If the player is within our attack range...
	if dist_to_target <= ATTACK_RANGE:
		# ...and we have a clear, smart line of sight, pull the trigger!
		if cooldown_left <= 0.0 and has_clear_shot(actor):
			actions.append(AttackAction.new())
			cooldown_left = SHOOT_COOLDOWN

	return actions


func update_aim(actor: Entity) -> void:
	if is_instance_valid(target):
		var target_center := target.global_position + Vector3(0, 0, 0)

		var enemy_weapon_height := actor.global_position.y + 0
		target_center.y = enemy_weapon_height

		aim_target = target_center

		if is_instance_valid(actor.mesh_instance):
			var mesh := actor.mesh_instance

			if mesh.global_position.distance_squared_to(target_center) > 0.01:
				# 1. Get the transform pointing at the flattened target
				var target_transform := mesh.global_transform.looking_at(target_center, Vector3.UP)

				# 2. Invert it so the cube's face points the right way
				target_transform = target_transform.rotated_local(Vector3.UP, PI)

				# 3. Smoothly apply the rotation
				mesh.global_transform = mesh.global_transform.interpolate_with(
					target_transform, 0.1
				)


func has_clear_shot(actor: Entity) -> bool:
	if not is_instance_valid(target):
		return false

	var space_state := actor.get_world_3d().direct_space_state

	# Cast rays from the AI's "eyes" (chest height) instead of its feet
	var origin := actor.global_position + Vector3(0, 0, 0)
	var target_center := target.global_position + Vector3(0, 0, 0)

	# Calculate left and right offsets based on the direction we are looking
	var dir_to_target := origin.direction_to(target_center)
	var right_offset := Vector3.UP.cross(dir_to_target).normalized() * 0.4  # 0.4 meters to the side

	# Our three points of interest on the player's body
	var target_points = [target_center, target_center + right_offset, target_center - right_offset]  # Center mass  # Right shoulder  # Left shoulder

	for point in target_points:
		var query := PhysicsRayQueryParameters3D.create(origin, point)
		query.exclude = [actor]

		# CRITICAL: Collision Mask Math!
		# Layer 1 (World) + Layer 2 (Player) = 3
		# This makes the ray get blocked by walls, hit the player, but pass THROUGH other enemies!
		query.collision_mask = 3

		var result := space_state.intersect_ray(query)

		# If the ray hit something, and that something is our target, we have a shot!
		if not result.is_empty() and result.collider == target:
			return true

	# If all 3 rays hit a wall, the player is safely in cover
	return false
