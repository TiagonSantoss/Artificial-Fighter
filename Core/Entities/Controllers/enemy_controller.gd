class_name EnemyController
extends Controller

var follow_target: Entity
var follow_distance := 0.1
var target: Entity

func get_actions(_actor: Entity, _delta: float) -> Array[Action]:
	var actions: Array[Action] = []
	
	if follow_target:
		var diff = follow_target.global_position - _actor.global_position
		var dist = diff.length()
		
		if dist > follow_distance:
			var dir = diff / dist
			
			var strength = clamp((dist - follow_distance), 0.0, 1.0)
			
			actions.append(MovementAction.new(dir * strength))
			
	return actions

func get_aim_target(_actor):
	if target == null:
		return null
	
	return target.global_position
