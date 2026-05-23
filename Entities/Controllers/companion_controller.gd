class_name CompanionController
extends Controller

var follow_target: Entity
var follow_distance := 1.0

func get_actions(actor: Entity, _delta: float) -> Array[Action]:
	var actions: Array[Action] = []
	
	if follow_target == null:
		return actions
	
	var nav: NavigationAgent3D = actor.get_node("NavigationAgent3D")
	
	nav.target_position = follow_target.global_position
	
	var dist := actor.global_position.distance_to(follow_target.global_position)
	
	if dist <= follow_distance:
		return actions
	
	var next_point := nav.get_next_path_position()
	
	var move_dir := next_point - actor.global_position
	
	var flat_dir := Vector3(move_dir.x, 0.0, move_dir.z).normalized()
	
	actions.append(MovementAction.new(flat_dir))
	
	var height_diff := move_dir.y
	print(height_diff)
	
	if height_diff > 0.3:
		actions.append(JumpAction.new())
	
	return actions
