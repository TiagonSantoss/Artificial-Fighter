class_name MovementAction
extends Action

var direction: Vector3

func _init(dir: Vector3) -> void:
	direction = dir.normalized()

func execute(actor, delta: float) -> void:
	actor.move(direction, delta)
