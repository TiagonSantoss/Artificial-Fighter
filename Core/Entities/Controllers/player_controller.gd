class_name PlayerController
extends Controller

const DASH_COOLDOWN := 1.2

var locked_forward := Vector3.ZERO
var locked_right := Vector3.ZERO
var movement_locked := false

var previous_input := Vector2.ZERO
var locked_direction := Vector3.ZERO
var previous_camera_rotation_y := 0.0

var dodge_cooldown_left := 0.0


func get_actions(_actor: Entity, _delta: float) -> Array[Action]:
	var actions: Array[Action] = []

	if dodge_cooldown_left > 0.0:
		dodge_cooldown_left -= _delta

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
		_actor.audio_component.play_sfx("PlayerFootSteps")
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

	if input.length() > 0.01 and should_auto_jump(_actor, locked_direction):
		actions.append(JumpAction.new())

	if Input.is_action_just_pressed("interact"):
		if _actor.current_interactable != null:
			actions.append(InteractAction.new(_actor, _actor.current_interactable))

	if _actor.entity_id == 0:
		if Input.is_action_pressed("special"):
			actions.append(ParryAction.new())
	else:
		if Input.is_action_just_pressed("special") and dodge_cooldown_left <= 0.0:
			actions.append(DodgeAction.new(35.0, 0.4))
			if _actor.entity_id == 1:
				dodge_cooldown_left = DASH_COOLDOWN

	return actions


func get_aim_target(actor: Entity) -> Vector3:
	var cam: Camera3D = actor.get_viewport().get_camera_3d()

	if cam == null:
		return actor.global_position + Vector3.FORWARD

	var mouse := actor.get_viewport().get_mouse_position()

	var player_screen := cam.unproject_position(actor.global_position)
	var screen_dir := mouse - player_screen

	if screen_dir.length() < 0.001:
		screen_dir = Vector2.RIGHT

	screen_dir = screen_dir.normalized()

	var cam_forward := -cam.global_transform.basis.z
	var cam_right := cam.global_transform.basis.x

	cam_forward.y = 0
	cam_right.y = 0

	cam_forward = cam_forward.normalized()
	cam_right = cam_right.normalized()

	var world_dir := (cam_right * screen_dir.x + cam_forward * -screen_dir.y).normalized()

	return actor.global_position + world_dir * 10.0


func update_aim(actor: Entity) -> void:
	aim_target = get_aim_target(actor)


func should_auto_jump(actor: Entity, move_dir: Vector3) -> bool:
	if not actor.is_on_floor():
		return false

	var space_state := actor.get_world_3d().direct_space_state

	var origin_feet := actor.global_position + Vector3(0, 0.2, 0)
	var target_feet := origin_feet + move_dir * 0.8
	var query_feet := PhysicsRayQueryParameters3D.create(origin_feet, target_feet)
	query_feet.exclude = [actor]

	query_feet.collision_mask = 1

	var hit_feet := space_state.intersect_ray(query_feet)
	if hit_feet.is_empty():
		return false

	var step_height := 3.0
	var origin_clearance := actor.global_position + Vector3(0, step_height, 0)
	var target_clearance := origin_clearance + move_dir * 0.8
	var query_clearance := PhysicsRayQueryParameters3D.create(origin_clearance, target_clearance)
	query_clearance.exclude = [actor]

	query_clearance.collision_mask = 1

	var hit_clearance := space_state.intersect_ray(query_clearance)
	return hit_clearance.is_empty()
