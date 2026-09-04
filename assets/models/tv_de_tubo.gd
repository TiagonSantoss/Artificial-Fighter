extends MeshInstance3D

enum AxisAlignment { X_AXIS, Z_AXIS }

@export var tv_alignment: AxisAlignment = AxisAlignment.X_AXIS

var tween: Tween


func _ready() -> void:
	GState.perspective_updated.connect(_on_perspective_changed)


func _on_perspective_changed(_axis):
	if tween and tween.is_running():
		tween.kill()

	var current_color = get_instance_shader_parameter("color")
	if current_color == null:
		current_color = Color(1.0, 1.0, 1.0, 0.5)

	var target_color: Color

	var camera_on_x = (
		GState.current_perspective.active_axis == CameraPerspectiveState.Axis.X_NEGATIVE
		or GState.current_perspective.active_axis == CameraPerspectiveState.Axis.X_POSITIVE
	)
	var camera_on_z = (
		GState.current_perspective.active_axis == CameraPerspectiveState.Axis.Z_NEGATIVE
		or GState.current_perspective.active_axis == CameraPerspectiveState.Axis.Z_POSITIVE
	)

	if tv_alignment == AxisAlignment.X_AXIS:
		if camera_on_x:
			target_color = Color(1.816, 0.0, 0.0, 0.725)
		elif camera_on_z:
			target_color = Color(0.0, 0.0, 0.0, 0.294)
	elif tv_alignment == AxisAlignment.Z_AXIS:
		if camera_on_z:
			target_color = Color(0.0, 0.0, 1.0, 0.725)
		elif camera_on_x:
			target_color = Color(0.0, 0.0, 0.0, 0.294)

	if target_color == null:
		return

	tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_method(
		func(color_var): set_instance_shader_parameter("color", color_var),
		current_color,
		target_color,
		.8
	)
