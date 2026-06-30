class_name InteractAction
extends Action

var target: Node
var actor: Entity

func _init(_actor: Entity, _target: Node):
	actor = _actor
	target = _target

func execute(_actor: Entity, _delta):
	if target == null:
		return
	
	if target.has_method("interact"):
		target.interact(actor)
