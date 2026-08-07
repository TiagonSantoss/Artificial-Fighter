class_name MovementAction
extends Action

static var time_since_last_step: float = 0.0

var direction: Vector3
var step_cooldown: float = 0.4


func _init(dir: Vector3) -> void:
	direction = dir


func execute(actor: Entity, _delta: float) -> void:
	actor.movement_component.apply_movement(direction, _delta)
