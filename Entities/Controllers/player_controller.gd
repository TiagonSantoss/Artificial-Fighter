class_name PlayerController
extends Controller

var locked_forward := Vector3.ZERO
var locked_right := Vector3.ZERO
var movement_locked := false

func get_actions(_actor: Entity, _delta: float) -> Array[Action]:
	var actions: Array[Action] = []
	
	var input := Vector2.ZERO
	
	input.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input.y = Input.get_action_strength("ui_up") - Input.get_action_strength("ui_down")
	
	var cam := _actor.get_viewport().get_camera_3d()

	if input != Vector2.ZERO:
		if not movement_locked:
			locked_forward = -cam.global_transform.basis.z
			locked_right = cam.global_transform.basis.x
			
			locked_forward.y = 0
			locked_right.y = 0
			
			locked_forward = locked_forward.normalized()
			locked_right = locked_right.normalized()
			
			movement_locked = true
		var dir := (
			locked_right * input.x +
			locked_forward * input.y
		).normalized()
		actions.append(MovementAction.new(dir))
	else:
		movement_locked = false
	
	if Input.is_action_just_pressed("ui_cancel"):
		actions.append(EscapeAction.new())
	
	if Input.is_action_pressed("fire"):
		actions.append(FireAction.new())
	
	if Input.is_action_just_pressed("rotate_camera_right"):
		actions.append(RotateCameraAction.new(90))
	
	if Input.is_action_just_pressed("rotate_camera_left"):
		actions.append(RotateCameraAction.new(-90))
	
	return actions
