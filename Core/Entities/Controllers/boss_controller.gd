class_name BossEnemyController
extends Controller

var target: Entity

@export_category("Distance Tuning")
var desired_distance := 25.0
var flee_distance := 10.0
var attack_range := 35.0

@export_category("Movement Variety")
## Alternates between left/right circling states to confuse the player
var circle_direction := 1.0
var circle_switch_timer := 0.0
# 🟢 NEW: Tracks elapsed time to drive organic movement shifts
var lifetime_drift_timer := 0.0

func get_actions(actor: Entity, delta: float) -> Array[Action]:
	var actions: Array[Action] = []
	
	if target == null:
		return actions
		
	var dist := actor.global_position.distance_to(target.global_position)
	var nav: NavigationAgent3D = actor.get_node("NavigationAgent3D")
	
	# Increment our master wave clocks
	lifetime_drift_timer += delta
	circle_switch_timer -= delta
	
	if circle_switch_timer <= 0.0:
		circle_direction = 1.0 if randf() > 0.5 else -1.0
		circle_switch_timer = randf_range(3.0, 6.0) # slightly longer timers feel less twitchy

	# --- DYNAMIC NAVIGATION PATHFINDING SYSTEM ---
	if dist < flee_distance:
		var flee_dir := (actor.global_position - target.global_position).normalized()
		var flee_point := actor.global_position + flee_dir * desired_distance
		
		nav.target_position = flee_point
		_add_nav_movement_action(actor, nav, actions)
		
	elif dist > attack_range:
		nav.target_position = target.global_position
		_add_nav_movement_action(actor, nav, actions)
		
	else:
		# 🟢 FIXED BREAKOUT: Calculate a dynamic floating distance ring instead of a rigid, flat one
		# This sine wave fluctuates between -6.0 and +6.0 units every few seconds
		var dynamic_drift = sin(lifetime_drift_timer * 0.8) * 6.0
		var current_ideal_range = desired_distance + dynamic_drift
		
		var to_target := (target.global_position - actor.global_position).normalized()
		var tangent_dir := Vector3(-to_target.z, 0.0, to_target.x) * circle_direction
		
		# Blend towards the shifting dynamic orbit range rather than a fixed number
		if dist > current_ideal_range:
			tangent_dir = (tangent_dir + to_target * 0.35).normalized()
		else:
			tangent_dir = (tangent_dir - to_target * 0.35).normalized()
			
		# Project the target position point outward along the navigation grid mesh
		var strafe_target_point := actor.global_position + (tangent_dir * 7.0)
		
		nav.target_position = strafe_target_point
		_add_nav_movement_action(actor, nav, actions)

	# --- COMBAT MANAGEMENT SYSTEM ---
	if dist <= attack_range:
		actions.append(AttackAction.new())
		
	return actions


func _add_nav_movement_action(actor: Entity, nav: NavigationAgent3D, actions: Array[Action]) -> void:
	var next_point := nav.get_next_path_position()
	var move_dir := next_point - actor.global_position
	
	var flat_dir := Vector3(move_dir.x, 0.0, move_dir.z).normalized()
	
	if flat_dir.length_squared() > 0.001:
		actions.append(MovementAction.new(flat_dir))
		
	if move_dir.y > 0.4:
		actions.append(JumpAction.new())


func get_aim_target(_actor: Entity) -> Variant:
	if target == null:
		return null
	return target.global_position
