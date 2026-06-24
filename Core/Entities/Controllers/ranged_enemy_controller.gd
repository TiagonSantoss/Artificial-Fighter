class_name RangedEnemyController
extends Controller

var target: Entity

var desired_distance := 6.0
var flee_distance := 5.0
var attack_range := 6.7


func get_actions(actor: Entity, _delta: float) -> Array[Action]:
	var actions: Array[Action] = []
	
	if target == null:
		return actions
	
	var dist := actor.global_position.distance_to(
		target.global_position
	)
	
	var nav: NavigationAgent3D = actor.get_node(
		"NavigationAgent3D"
	)
	
	# Too close -> run away
	if dist < flee_distance:
		var flee_dir := (
			actor.global_position
			- target.global_position
		).normalized()
		
		var flee_point := (
			actor.global_position
			+ flee_dir * desired_distance
		)
		
		nav.target_position = flee_point
		
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
	
	# Too far -> move closer
	elif dist > desired_distance:
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
			
	# Attack whenever in range
	if dist <= attack_range:
		actions.append(
			AttackAction.new()
		)
	
	return actions


func get_aim_target(_actor: Entity) -> Variant:
	if target == null:
		return null

	return target.global_position
