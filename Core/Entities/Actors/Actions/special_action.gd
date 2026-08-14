class_name SpecialAction
extends Action

var id: int


func _init(entity_id: int):
	id = entity_id


func execute(actor: Entity, _delta: float) -> void:
	if actor:
		if id == 0:
			ParryAction.new().execute(actor, _delta)
		elif id == 1:
			DodgeAction.new(20.0, 0.4).execute(actor, _delta)
