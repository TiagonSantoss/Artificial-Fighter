class_name CompanionController
extends Controller

var follow_target: Entity
var target: Entity

var follow_distance := 8.0
var attack_range := 8.0
var formation_offset := Vector3.ZERO


func get_actions(actor: Entity, _delta: float) -> Array[Action]:
	var actions: Array[Action] = []

	if follow_target == null:
		return actions

	target = find_target(actor)

	if target != null:
		var target_dist := actor.global_position.distance_to(target.global_position)

		if target_dist <= attack_range:
			actions.append(AttackAction.new())

	var nav: NavigationAgent3D = actor.get_node("NavigationAgent3D")

	nav.target_position = (follow_target.global_position + formation_offset)

	var dist := actor.global_position.distance_to(nav.target_position)

	if dist <= follow_distance:
		return actions

	var next_point := nav.get_next_path_position()

	var move_dir := next_point - actor.global_position

	var flat_dir := Vector3(move_dir.x, 0.0, move_dir.z).normalized()

	actions.append(MovementAction.new(flat_dir))

	if should_auto_jump(actor, move_dir):
		actions.append(JumpAction.new())

	return actions


func find_target(actor: Entity) -> Entity:
	var nearest: Entity
	var nearest_dist := attack_range

	for enemy: Entity in actor.get_tree().get_nodes_in_group("enemies"):
		var dist := actor.global_position.distance_to(enemy.global_position)

		if dist < nearest_dist:
			nearest_dist = dist
			nearest = enemy

	return nearest


func get_aim_target(_actor: Entity) -> Variant:
	if target == null:
		return null

	return target.global_position


func should_auto_jump(actor: Entity, move_dir: Vector3) -> bool:
	if not actor.is_on_floor():
		return false

	var space_state := actor.get_world_3d().direct_space_state

	var origin_feet := actor.global_position + Vector3(0, 0.2, 0)
	var target_feet := origin_feet + move_dir * 0.8
	var query_feet := PhysicsRayQueryParameters3D.create(origin_feet, target_feet)
	query_feet.exclude = [actor]

	query_feet.collision_mask = 1

	var hit_feet := space_state.intersect_ray(query_feet)
	if hit_feet.is_empty():
		return false

	var step_height := 3.0
	var origin_clearance := actor.global_position + Vector3(0, step_height, 0)
	var target_clearance := origin_clearance + move_dir * 0.8
	var query_clearance := PhysicsRayQueryParameters3D.create(origin_clearance, target_clearance)
	query_clearance.exclude = [actor]

	query_clearance.collision_mask = 1

	var hit_clearance := space_state.intersect_ray(query_clearance)
	return hit_clearance.is_empty()
