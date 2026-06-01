class_name RotateCameraAction
extends Action

var degrees: float
var target_camera: RotateCameraPivot

func _init(rot_degrees: float, camera: RotateCameraPivot):
	degrees = rot_degrees
	target_camera = camera

func execute(_actor: Entity, _delta: float) -> void:
	if target_camera:
		target_camera.rotate_by(degrees)
