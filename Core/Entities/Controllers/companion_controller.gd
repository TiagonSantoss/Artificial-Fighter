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

	if move_dir.y > 0.3:
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
