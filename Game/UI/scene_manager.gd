extends Control

@export
var _persistent_foreground_scene: PackedScene = preload("res://Game/UI/screen_transition.tscn")

var _foreground_canvas: CanvasLayer
var _foreground_scene: Control

var _transition_effect: ColorRect
var _transition_tween: Tween

var _shake_tween: Tween

var _dotted_vignette: ColorRect
var _vignette_tween: Tween

var _is_transitioning: bool = false

var _impact_frame: ColorRect

var _transition_effect_parameter_call = func(value: float):
	if _transition_effect and _transition_effect.material:
		_transition_effect.material.set_shader_parameter("progress", value)
		_transition_effect.material.set_shader_parameter(
			"background_threshold", abs(1.0 - value * 2.0) - 0.5
		)
		_transition_effect.material.set_shader_parameter(
			"color_threshold", min(1.0, abs(-4.0 + value * 8.0)) * 0.48
		)


func _ready():
	# process_mode = Node.PROCESS_MODE_ALWAYS

	_foreground_canvas = CanvasLayer.new()
	_foreground_canvas.layer = 1000
	add_child(_foreground_canvas)

	_foreground_scene = _persistent_foreground_scene.instantiate()
	_foreground_canvas.add_child(_foreground_scene)

	_transition_effect = _foreground_scene.get_node_or_null("%TransitionEffect")
	if _transition_effect:
		_transition_effect.set_visible(false)

	_dotted_vignette = _foreground_scene.get_node_or_null("%DottedVignette")
	if _dotted_vignette:
		_dotted_vignette.hide()

	_impact_frame = _foreground_scene.get_node_or_null("%ImpactFrame")
	if _impact_frame:
		_impact_frame.hide()


func change_scene(scene_path: String) -> void:
	if _is_transitioning:
		return

	_is_transitioning = true

	await cover_screen()

	var error = get_tree().change_scene_to_file(scene_path)
	if error != OK:
		push_error("Failed to load scene at path: " + scene_path)
		_is_transitioning = false
		return

	await get_tree().process_frame
	await get_tree().process_frame

	await reveal_screen()

	_is_transitioning = false


func cover_screen() -> void:
	if _transition_effect == null:
		return

	if _transition_tween != null:
		_transition_tween.kill()

	_transition_effect.material.set_shader_parameter("seed", randf())
	_transition_effect.set_visible(true)

	_transition_tween = create_tween()
	_transition_tween.tween_method(_transition_effect_parameter_call, 0.0, 0.5, 0.5)

	await _transition_tween.finished


func reveal_screen() -> void:
	if _transition_effect == null:
		return

	if _transition_tween != null:
		_transition_tween.kill()

	_transition_tween = create_tween()
	_transition_tween.tween_method(_transition_effect_parameter_call, 0.5, 1.0, 0.5)
	_transition_tween.tween_callback(_transition_effect.set_visible.bind(false))

	await _transition_tween.finished


func shake(intensity: float = 0.2, duration: float = 0.3) -> void:
	var cam = get_viewport().get_camera_3d()
	if cam == null:
		return

	if _shake_tween != null:
		_shake_tween.kill()

	_shake_tween = create_tween()

	var step_time: float = 0.03
	var steps: int = int(duration / step_time)

	var current_intensity = intensity

	for i in range(steps):
		var rand_x = randf_range(-current_intensity, current_intensity)
		var rand_y = randf_range(-current_intensity, current_intensity)

		_shake_tween.tween_property(cam, "h_offset", rand_x, step_time)
		_shake_tween.parallel().tween_property(cam, "v_offset", rand_y, step_time)

		current_intensity *= 0.85

	_shake_tween.tween_property(cam, "h_offset", 0.0, step_time)
	_shake_tween.parallel().tween_property(cam, "v_offset", 0.0, step_time)


func pulse_vignette(duration: float = 0.3, target_opacity: float = 1.0) -> void:
	if _dotted_vignette == null:
		return

	if _vignette_tween != null:
		_vignette_tween.kill()

	_dotted_vignette.show()

	_dotted_vignette.material.set_shader_parameter("opacity", 0.0)

	_vignette_tween = create_tween()

	var half_time = duration / 2.0

	_vignette_tween.tween_property(
		_dotted_vignette, "material:shader_parameter/opacity", target_opacity, half_time
	)

	_vignette_tween.tween_property(
		_dotted_vignette, "material:shader_parameter/opacity", 0.0, half_time
	)

	_vignette_tween.tween_callback(_dotted_vignette.hide)


func play_impact_frame(target_3d_position: Vector3, duration: float = 0.15) -> void:
	if _impact_frame == null:
		return

	var cam = get_viewport().get_camera_3d()
	if cam == null:
		return

	var screen_pos = cam.unproject_position(target_3d_position)

	var viewport_size = get_viewport().get_visible_rect().size
	var uv_pos = screen_pos / viewport_size

	var aspect = viewport_size.x / viewport_size.y
	_impact_frame.material.set_shader_parameter("center", uv_pos)
	_impact_frame.material.set_shader_parameter("aspect_ratio", aspect)

	_impact_frame.show()

	var timer = get_tree().create_timer(duration)
	await timer.timeout

	_impact_frame.hide()


func spawn_trail(
	target_sprite: Node3D, duration: float = 0.4, custom_color: Color = Color(1, 1, 1, 0.8)
) -> void:
	if target_sprite == null:
		return

	var ghost = target_sprite.duplicate()

	get_tree().current_scene.add_child(ghost)

	ghost.global_transform = target_sprite.global_transform

	if ghost.has_method("pause"):
		ghost.pause()

	if "modulate" in ghost:
		ghost.modulate = custom_color

	var tween = create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, duration).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(ghost.queue_free)
