class_name MeleeEnemyController
extends Controller

var follow_target: Entity
var follow_distance := 0.1
var target: Entity
var attack_range := 0.7


func get_actions(actor: Entity, _delta: float) -> Array[Action]:
	var actions: Array[Action] = []
	
	if target == null:
		return actions
	
	var dist := actor.global_position.distance_to(
		target.global_position
	)
	
	# Chase
	if dist > follow_distance:
		var nav: NavigationAgent3D = actor.get_node("NavigationAgent3D")
		
		nav.target_position = target.global_position
		
		var next_point := nav.get_next_path_position()
		
		var move_dir := (
			next_point - actor.global_position
		)
		
		var flat_dir := Vector3(
			move_dir.x,
			0.0,
			move_dir.z
		).normalized()
		
		actions.append(
			MovementAction.new(flat_dir)
		)
		
		if move_dir.y > 0.3:
			actions.append(
				JumpAction.new()
			)
			
	# Attack
	if dist <= attack_range:
		actions.append(
			FireAction.new()
		)
	
	return actions

func get_aim_target(_actor: Entity) -> Variant:
	if target == null:
		return null

	return target.global_position
