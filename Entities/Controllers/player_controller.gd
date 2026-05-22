class_name PlayerController
extends Controller

var locked_forward := Vector3.ZERO
var locked_right := Vector3.ZERO
var movement_locked := false

var previous_input := Vector2.ZERO
var locked_direction := Vector3.ZERO

func get_actions(_actor: Entity, _delta: float) -> Array[Action]:
	var actions: Array[Action] = []
	
	var input := Vector2.ZERO
	
	input.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input.y = Input.get_action_strength("ui_up") - Input.get_action_strength("ui_down")
	
	var cam := _actor.get_viewport().get_camera_3d()
	var pivot := cam.get_parent() as RotateCameraPivot
	
	if input != Vector2.ZERO:
		if input != previous_input:
			var forward = -pivot.global_transform.basis.z
			var right = pivot.global_transform.basis.x
			
			forward.y = 0
			right.y = 0
			
			forward = forward.normalized()
			right = right.normalized()
			
			locked_direction = (
				right * input.x +
				forward * input.y
			).normalized()
			previous_input = input
		actions.append(MovementAction.new(locked_direction))
	else:
		previous_input = Vector2.ZERO
	
	if Input.is_action_just_pressed("ui_cancel"):
		actions.append(EscapeAction.new())
	
	if Input.is_action_pressed("fire"):
		var target = get_aim_target(_actor)
		if target != null:
			var dir = (
				target - _actor.global_position
			)
			dir.y = 0
			dir = dir.normalized()
			actions.append(
				FireAction.new(dir)
			)
	
	if Input.is_action_just_pressed("rotate_camera_right"):
		actions.append(RotateCameraAction.new(90, pivot))
	
	if Input.is_action_just_pressed("rotate_camera_left"):
		actions.append(RotateCameraAction.new(-90, pivot))
	
	if Input.is_action_just_pressed("jump"):
		actions.append((JumpAction.new()))
	
	return actions

func get_aim_target(actor) -> Variant:
	var cam: Camera3D = actor.get_viewport().get_camera_3d()
	
	if cam == null:
		return null
	
	var mouse: Vector2 = actor.get_viewport().get_mouse_position()
	
	var ray_origin := cam.project_ray_origin(mouse)
	var ray_dir := cam.project_ray_normal(mouse)
	
	var plane := Plane(
		Vector3.UP,
		actor.global_position
	)
	
	return plane.intersects_ray(
		ray_origin,
		ray_dir
	)
