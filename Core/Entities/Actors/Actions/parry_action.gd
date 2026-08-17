class_name ParryAction
extends Action


func execute(actor: Entity, _delta: float) -> void:
	if actor.has_method("trigger_guard"):
		actor.trigger_guard()
