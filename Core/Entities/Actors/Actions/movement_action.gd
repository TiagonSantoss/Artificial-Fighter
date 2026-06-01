class_name MovementAction
extends Action

var direction: Vector3

func _init(dir: Vector3) -> void:
	direction = dir

func execute(actor: Entity, _delta: float) -> void:
	actor.movement_component.apply_movement(direction, _delta)
