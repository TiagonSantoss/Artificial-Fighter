class_name MeleeEnemyController
extends Controller

const AXIS_THRESHOLD := 0.2

var follow_target: Entity
var follow_distance := 0.1
var target: Entity
var attack_range := 1.6


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
		
		var move_dir := (next_point - actor.global_position)
		
		var dx := move_dir.x
		var dz := move_dir.z
		
		var flat_dir := Vector3.ZERO
		
		if abs(dx) > abs(dz) + AXIS_THRESHOLD:
			flat_dir.x = sign(dx)
		elif abs(dz) > abs(dx) + AXIS_THRESHOLD:
			flat_dir.z = sign(dz)
		else:
			flat_dir.x = sign(dx)
		
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
			AttackAction.new()
		)
	
	return actions

func get_aim_target(_actor: Entity) -> Variant:
	if target == null:
		return null

	return target.global_position
