class_name JumpAction
extends Action

func execute(actor: Entity, _delta: float) -> void:
	if actor.is_on_floor():
		actor.movement_component.jump()
