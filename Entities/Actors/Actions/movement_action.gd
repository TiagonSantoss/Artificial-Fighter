class_name MovementAction
extends Action

var direction: Vector3

func _init(dir: Vector3):
	direction = dir

func execute(actor: Entity, _delta: float) -> void:
	var dir = direction.normalized()
	
	actor.velocity.x = move_toward(
		actor.velocity.x,
		dir.x * actor.move_speed,
		actor.acceleration * _delta
	)
	
	actor.velocity.z = move_toward(
		actor.velocity.z,
		dir.z * actor.move_speed,
		actor.acceleration * _delta
	)
