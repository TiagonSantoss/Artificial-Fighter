class_name MovementAction
extends Action

var offset: Vector3

func _init(dx: float, dy: float, dz: float) -> void:
	offset = Vector3(dx, dy, dz)
