class_name MovementAction
extends Action

const BLOCK_SPEED_MULTIPLIER := 0.4

var direction := Vector3.ZERO


func _init(dir: Vector3):
	direction = dir


func execute(actor: Entity, delta: float) -> void:
	var final_direction = direction

	if actor.get("is_blocking"):
		final_direction *= BLOCK_SPEED_MULTIPLIER

	actor.movement_component.apply_movement(final_direction, delta)
