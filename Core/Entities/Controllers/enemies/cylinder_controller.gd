class_name CylinderController
extends Controller

# Cylinder Combat Constants
const SHOOT_COOLDOWN := 0.1
const ATTACK_RANGE := 60.0

# Movement Sweet Spot (AI will try to stay between 8 and 12 meters away)
const RETREAT_DISTANCE := 12.0
const STOP_DISTANCE := 19.0

# Pac-Man Movement Constants
const AXIS_THRESHOLD := 0.2
const CARDINAL_DIRECTIONS: Array[Vector3] = [
	Vector3(0, 0, -1), Vector3(0, 0, 1), Vector3(-1, 0, 0), Vector3(1, 0, 0)
]

@export var separation_radius: float = 3.0
@export var separation_weight: float = 1.5
@export var ray_check_distance: float = 1.2

@export var debug_rays: bool = true

var cooldown_left := 0.0
var target: Entity


func get_actions(actor: Entity, delta: float) -> Array[Action]:
	var actions: Array[Action] = []

	# Tick down the shooting cooldown
	if cooldown_left > 0.0:
		cooldown_left -= delta

	if not is_instance_valid(target):
		return actions

	var dist_to_target = actor.global_position.distance_to(target.global_position)

	var is_retreating = dist_to_target < RETREAT_DISTANCE
	var is_following = dist_to_target > STOP_DISTANCE

	# 1. PAC-MAN STYLE MOVEMENT (Advance or Retreat)
	if is_retreating or is_following:
		var target_pos := target.global_position

		# Only use the NavigationAgent if we are trying to reach the player.
		# If we are retreating, we just want to back away directly using our wall-checks.
		if is_following:
			var nav: NavigationAgent3D = actor.get_node_or_null("NavigationAgent3D")
			if is_instance_valid(nav):
				nav.target_position = target_pos
				if not nav.is_navigation_finished() and nav.is_target_reachable():
					var next_pos := nav.get_next_path_position()
					if next_pos != Vector3.ZERO or target_pos.length_squared() < 1.0:
						target_pos = next_pos

		# Tell our direction chooser whether we want to get closer or further away
		var move_dir := _choose_direction(actor, target_pos, is_retreating)

		var separation := _get_separation_vector(actor)
		var combined_dir := move_dir + (separation * separation_weight)

		var dx := combined_dir.x
		var dz := combined_dir.z
		var flat_dir := Vector3.ZERO

		# Snap to Cardinal Directions
		if abs(dx) > abs(dz) + AXIS_THRESHOLD:
			flat_dir.x = sign(dx)
		elif abs(dz) > abs(dx) + AXIS_THRESHOLD:
			flat_dir.z = sign(dz)
		elif abs(dx) > 0.01:
			flat_dir.x = sign(dx)

		if flat_dir != Vector3.ZERO:
			actions.append(MovementAction.new(flat_dir))

			if is_instance_valid(actor.audio_component):
				actor.audio_component.play_sfx("EnemyFootSteps")

		# Only jump to navigate terrain if we are actively chasing
		if is_following and (target_pos - actor.global_position).y > 0.3:
			actions.append(JumpAction.new())

	# 2. COMBAT LOGIC
	if dist_to_target <= ATTACK_RANGE:
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
				var target_transform := mesh.global_transform.looking_at(target_center, Vector3.UP)
				target_transform = target_transform.rotated_local(Vector3.UP, PI)
				mesh.global_transform = mesh.global_transform.interpolate_with(
					target_transform, 0.1
				)


func has_clear_shot(actor: Entity) -> bool:
	if not is_instance_valid(target):
		return false

	var space_state := actor.get_world_3d().direct_space_state
	var origin := actor.global_position + Vector3(0, -1, 0)
	var target_center := target.global_position + Vector3(0, 0, 0)

	var dir_to_target := origin.direction_to(target_center)
	var right_offset := Vector3.UP.cross(dir_to_target).normalized() * 0.4
	var wide_right_offset := right_offset * 1.5

	var head_offset := Vector3.UP * 0.7
	var leg_offset := Vector3.DOWN * 0.7

	var target_points = [
		target_center,
		target_center + head_offset,
		target_center + leg_offset,
		target_center + right_offset,
		target_center - right_offset,
		target_center + wide_right_offset,
		target_center - wide_right_offset
	]

	for point in target_points:
		var query := PhysicsRayQueryParameters3D.create(origin, point)
		query.exclude = [actor]
		query.collision_mask = 3
		var result := space_state.intersect_ray(query)

		var hit_target = not result.is_empty() and result.collider == target

		if debug_rays:
			# Draw green if it hits the player, red if it hits a wall/nothing
			var line_color = Color.GREEN if hit_target else Color.RED
			var end_point = result.position if not result.is_empty() else point
			_draw_debug_line(actor, origin, end_point, line_color)

		if hit_target:
			return true

	return false


func _draw_debug_line(actor: Entity, start: Vector3, end: Vector3, color: Color) -> void:
	var mesh_instance := MeshInstance3D.new()
	var immediate_mesh := ImmediateMesh.new()
	var material := StandardMaterial3D.new()

	mesh_instance.mesh = immediate_mesh
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	# Draw the line
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES, material)
	immediate_mesh.surface_add_vertex(start)
	immediate_mesh.surface_add_vertex(end)
	immediate_mesh.surface_end()

	# Make it unshaded so it glows nicely in the dark
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color

	actor.get_tree().root.add_child(mesh_instance)

	# Automatically delete the line after 0.05 seconds so they don't pile up and lag the game
	actor.get_tree().create_timer(0.05).timeout.connect(mesh_instance.queue_free)


# Added a `retreat` parameter to flip the distance logic
func _choose_direction(actor: Entity, destination: Vector3, retreat: bool = false) -> Vector3:
	var space_state := actor.get_world_3d().direct_space_state
	var best_dir := Vector3.ZERO

	# If retreating, we want to maximize distance (start at negative infinity).
	# If following, we want to minimize distance (start at infinity).
	var best_dist := -INF if retreat else INF

	for dir in CARDINAL_DIRECTIONS:
		var check_target := actor.global_position + (dir * ray_check_distance)

		# Skip direction if another enemy or wall is blocking it
		if _is_path_blocked(actor, space_state, check_target):
			continue

		var dist_to_target := check_target.distance_squared_to(destination)

		if retreat:
			# Pick the direction that takes us FURTHEST from the player
			if dist_to_target > best_dist:
				best_dist = dist_to_target
				best_dir = dir
		else:
			# Pick the direction that takes us CLOSEST to the player
			if dist_to_target < best_dist:
				best_dist = dist_to_target
				best_dir = dir

	# Fallback: if all valid cardinal directions are blocked by walls
	if best_dir == Vector3.ZERO:
		# Flee exactly away from target, or walk exactly toward it
		var fallback_dir := (
			actor.global_position - destination if retreat else destination - actor.global_position
		)
		fallback_dir.y = 0.0
		return fallback_dir.normalized() if fallback_dir.length_squared() > 0.001 else Vector3.ZERO

	return best_dir


func _is_path_blocked(
	actor: Entity, space_state: PhysicsDirectSpaceState3D, check_pos: Vector3
) -> bool:
	var query := PhysicsRayQueryParameters3D.create(actor.global_position, check_pos)
	query.exclude = [actor.get_rid()]
	query.collision_mask = actor.collision_layer | 1
	var result := space_state.intersect_ray(query)
	return not result.is_empty()


func _get_separation_vector(actor: Entity) -> Vector3:
	var separation := Vector3.ZERO
	var space_state := actor.get_world_3d().direct_space_state

	var query := PhysicsShapeQueryParameters3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = separation_radius

	query.shape = sphere
	query.transform = actor.global_transform
	query.collision_mask = actor.collision_layer

	var results := space_state.intersect_shape(query)

	for result in results:
		var collider = result.get("collider")
		if collider is Entity and collider != actor and collider.team == actor.team:
			var diff: Vector3 = actor.global_position - collider.global_position
			diff.y = 0.0
			var d: float = diff.length()

			if d > 0.001 and d < separation_radius:
				separation += (diff / d) * (separation_radius - d)

	return separation
