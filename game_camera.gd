class_name GameCamera
extends Camera3D

@export var rotation_speed := 8.0

var target_rotation_y := 0.0
var is_rotating := false

func rotate_by(degrees: float):
	if is_rotating:
		return
	
	is_rotating = true
	target_rotation_y += deg_to_rad(degrees)

func _process(delta):
	rotation.y = lerp_angle(
		rotation.y,
		target_rotation_y,
		rotation_speed * delta
	)

	if abs(angle_difference(rotation.y, target_rotation_y)) < 0.01:
		rotation.y = target_rotation_y
		is_rotating = false
