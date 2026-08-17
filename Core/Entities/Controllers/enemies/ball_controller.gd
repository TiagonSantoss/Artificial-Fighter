class_name BallController
extends Controller

const AXIS_THRESHOLD := 0.2
const CARDINAL_DIRECTIONS: Array[Vector3] = [
	Vector3(0, 0, -1), Vector3(0, 0, 1), Vector3(-1, 0, 0), Vector3(1, 0, 0)
]

@export var separation_radius: float = 3.0
@export var separation_weight: float = 1.5
@export var ray_check_distance: float = 1.2

var follow_target: Entity
var follow_distance := 0.1
var target: Entity
var attack_range := 15.0


func get_actions(actor: Entity, _delta: float) -> Array[Action]:
	var actions: Array[Action] = []

	if not is_instance_valid(target):
		_find_player(actor)

	if not is_instance_valid(target):
		return actions

	var dist := actor.global_position.distance_to(target.global_position)

	if dist > follow_distance:
		# 1. Determine base target point (via NavigationAgent3D if available)
		var nav: NavigationAgent3D = actor.get_node_or_null("NavigationAgent3D")
		var target_pos := target.global_position

		if is_instance_valid(nav):
			nav.target_position = target_pos
			if not nav.is_navigation_finished() and nav.is_target_reachable():
				var next_pos := nav.get_next_path_position()
				if next_pos != Vector3.ZERO or target_pos.length_squared() < 1.0:
					target_pos = next_pos

		var move_dir := _choose_direction(actor, target_pos)

		var separation := _get_separation_vector(actor)
		var combined_dir := move_dir + (separation * separation_weight)

		var dx := combined_dir.x
		var dz := combined_dir.z
		var flat_dir := Vector3.ZERO

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

		if (target_pos - actor.global_position).y > 0.3:
			actions.append(JumpAction.new())

	# Attack
	if dist <= attack_range:
		actions.append(AttackAction.new())

	return actions


func get_aim_target(_actor: Entity) -> Variant:
	if not is_instance_valid(target):
		return null

	return target.global_position


func _choose_direction(actor: Entity, destination: Vector3) -> Vector3:
	var space_state := actor.get_world_3d().direct_space_state
	var best_dir := Vector3.ZERO
	var shortest_dist := INF

	for dir in CARDINAL_DIRECTIONS:
		var check_target := actor.global_position + (dir * ray_check_distance)

		# Skip direction if another enemy or wall is blocking it
		if _is_path_blocked(actor, space_state, check_target):
			continue

		var dist_to_target := check_target.distance_squared_to(destination)
		if dist_to_target < shortest_dist:
			shortest_dist = dist_to_target
			best_dir = dir

	# Fallback: if all directions are blocked, default to direct path to destination
	if best_dir == Vector3.ZERO:
		var fallback_dir := destination - actor.global_position
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


func _find_player(actor: Entity) -> void:
	var players := actor.get_tree().get_nodes_in_group("player")
	if not players.is_empty() and players[0] is Entity:
		target = players[0]


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
