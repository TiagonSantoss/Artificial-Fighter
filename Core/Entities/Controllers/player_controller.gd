class_name PlayerController
extends Controller

const BURN_EFFECT = preload("res://assets/items/effects/fire.tres")

var locked_forward := Vector3.ZERO
var locked_right := Vector3.ZERO
var movement_locked := false

var previous_input := Vector2.ZERO
var locked_direction := Vector3.ZERO
var previous_camera_rotation_y := 0.0

func get_actions(_actor: Entity, _delta: float) -> Array[Action]:
	var actions: Array[Action] = []
	
	var input := Vector2.ZERO
	input.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input.y = Input.get_action_strength("ui_up") - Input.get_action_strength("ui_down")
	
	var cam := _actor.get_viewport().get_camera_3d()
	if cam == null:
		return actions
	
	if input.length() > 0.01:
		if not input.is_equal_approx(previous_input) or locked_direction == Vector3.ZERO:
			var forward := Game.instance.get_camera_forward()
			var right := Game.instance.get_camera_right()
			locked_direction = (right * input.x + forward * input.y).normalized()
			previous_input = input
		
		actions.append(MovementAction.new(locked_direction))
	else:
		previous_input = Vector2.ZERO
		locked_direction = Vector3.ZERO
	
	if Input.is_action_just_pressed("ui_cancel"):
		actions.append(EscapeAction.new())
	
	if Input.is_action_pressed("fire"):
		actions.append(AttackAction.new())
	
	if Input.is_action_just_pressed("rotate_camera_right"):
		actions.append(RotateCameraAction.new(90))
	
	if Input.is_action_just_pressed("rotate_camera_left"):
		actions.append(RotateCameraAction.new(-90))
	
	if Input.is_action_just_pressed("jump"):
		actions.append(JumpAction.new())
	
	if Input.is_action_just_pressed("add_item"):
		actions.append(AddItemAction.new(BURN_EFFECT, _actor.effects_component.effects))
	
	if Input.is_action_just_pressed("remove_item"):
		actions.append(RemoveItemAction.new(BURN_EFFECT, _actor.effects_component.effects))
	
	return actions

func get_aim_target(actor: Entity) -> Vector3:
	var cam: Camera3D = actor.get_viewport().get_camera_3d()
	
	if cam == null:
		return actor.global_position + Vector3.FORWARD
	
	var mouse := actor.get_viewport().get_mouse_position()
	
	var player_screen := cam.unproject_position(actor.global_position)
	var screen_dir := (mouse - player_screen)
	
	if screen_dir.length() < 0.001:
		screen_dir = Vector2.RIGHT
	
	screen_dir = screen_dir.normalized()
	
	# camera-relative axes
	var cam_forward := -cam.global_transform.basis.z
	var cam_right := cam.global_transform.basis.x
	
	cam_forward.y = 0
	cam_right.y = 0
	
	cam_forward = cam_forward.normalized()
	cam_right = cam_right.normalized()
	
	# convert screen direction -> world direction
	var world_dir := (
		cam_right * screen_dir.x +
		cam_forward * -screen_dir.y
	).normalized()
	
	return actor.global_position + world_dir * 10.0

func update_aim(actor: Entity) -> void:
	aim_target = get_aim_target(actor)
