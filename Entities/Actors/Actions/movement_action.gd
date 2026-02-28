class_name MovementAction
extends Action

var direction: Vector3

func _init(dir: Vector3):
	direction = dir

func execute(actor: Entity, delta: float) -> void:
	var target_x := direction.x * actor.move_speed
	var target_z := direction.z * actor.move_speed

	#X
	if direction.x != 0:
		actor.velocity.x = move_toward(
			actor.velocity.x,
			target_x,
			actor.acceleration * delta
		)

	#Z
	if direction.z != 0:
		actor.velocity.z = move_toward(
			actor.velocity.z,
			target_z,
			actor.acceleration * delta
		)
