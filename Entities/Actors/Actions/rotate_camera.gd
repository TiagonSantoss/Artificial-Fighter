class_name RotateCameraAction
extends Action

var degrees: float

func _init(rot_degrees: float):
	degrees = rot_degrees

func execute(actor: Entity, _delta: float) -> void:
	var camera := actor.get_viewport().get_camera_3d() as GameCamera
	
	if camera:
		camera.rotate_by(degrees)
