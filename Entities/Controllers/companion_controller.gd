class_name CompanionController
extends Controller

var follow_target: Entity

func get_actions(_actor: Entity, _delta: float) -> Array[Action]:
	var actions: Array[Action] = []

	if follow_target:
		var dir = follow_target.global_position - _actor.global_position
		if dir.length() > 0.2:
			dir = dir.normalized()
			actions.append(MovementAction.new(dir))

	return actions
