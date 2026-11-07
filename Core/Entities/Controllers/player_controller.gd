class_name PlayerController
extends Controller

const DASH_COOLDOWN := 1.2

const STICK_DEADZONE := 0.25
const STICK_FIRE_THRESHOLD := 0.4
const STICK_AIM_DISTANCE := 30.0

static var _using_gamepad := false
static var _last_mouse_pos := Vector2.ZERO
static var _last_aim_dir := Vector3.ZERO

var _aim_stick := Vector2.ZERO

var locked_forward := Vector3.ZERO
var locked_right := Vector3.ZERO
var movement_locked := false

var previous_input := Vector2.ZERO
var locked_direction := Vector3.ZERO
var previous_camera_rotation_y := 0.0

var dodge_cooldown_left := 0.0


func get_actions(_actor: Entity, _delta: float) -> Array[Action]:
	var actions: Array[Action] = []
	_poll_aim_input(_actor)

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
			var forward = GameAutoLoad.get_camera_forward()
			var right = GameAutoLoad.get_camera_right()
			locked_direction = (right * input.x + forward * input.y).normalized()
			previous_input = input

		actions.append(MovementAction.new(locked_direction))
		_actor.audio_component.play_sfx("PlayerFootSteps")
	else:
		previous_input = Vector2.ZERO
		locked_direction = Vector3.ZERO

	if Input.is_action_just_pressed("ui_cancel"):
		actions.append(EscapeAction.new())

	var over_ui := _actor.get_viewport().gui_get_hovered_control() != null
	var stick_firing := _aim_stick.length() >= STICK_FIRE_THRESHOLD
	var button_firing := Input.is_action_pressed("fire") and (_using_gamepad or not over_ui)

	if stick_firing or button_firing:
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

	if Input.is_action_just_pressed("change_characters"):
		actions.append(ChangeCharactersAction.new())

	return actions


func _poll_aim_input(actor: Entity) -> void:
	_aim_stick = Input.get_vector("aim_left", "aim_right", "aim_down", "aim_up", STICK_DEADZONE)

	var mouse := actor.get_viewport().get_mouse_position()
	if _aim_stick.length() > 0.0:
		_using_gamepad = true
	elif mouse.distance_squared_to(_last_mouse_pos) > 4.0:
		_using_gamepad = false
	_last_mouse_pos = mouse


func get_aim_target(actor: Entity) -> Vector3:
	if _using_gamepad:
		return _get_stick_aim_target(actor)

	var viewport := actor.get_viewport()
	var cam := viewport.get_camera_3d()
	if cam == null:
		return actor.global_position + Vector3.FORWARD

	var mouse := viewport.get_mouse_position()
	var ray_origin := cam.project_ray_origin(mouse)
	var ray_dir := cam.project_ray_normal(mouse)

	var plane := Plane(Vector3.UP, actor.weapon_socket.global_position.y)
	var hit = plane.intersects_ray(ray_origin, ray_dir)

	if hit == null:
		return actor.global_position - actor.global_transform.basis.z * 10.0

	return hit


func _get_stick_aim_target(actor: Entity) -> Vector3:
	if _aim_stick.length() > 0.0:
		# Same camera-relative mapping as movement, so aim matches where you walk
		var forward := GameAutoLoad.get_camera_forward()
		var right := GameAutoLoad.get_camera_right()
		_last_aim_dir = (right * _aim_stick.x + forward * _aim_stick.y).normalized()

	if _last_aim_dir == Vector3.ZERO:
		_last_aim_dir = -actor.global_transform.basis.z
		_last_aim_dir.y = 0.0
		_last_aim_dir = _last_aim_dir.normalized()

	# Released stick keeps the last direction, so the weapon doesn't snap back
	var target := actor.global_position + _last_aim_dir * STICK_AIM_DISTANCE
	target.y = actor.weapon_socket.global_position.y
	return target


func update_aim(actor: Entity) -> void:
	if _using_gamepad:
		if Input.mouse_mode != Input.MOUSE_MODE_HIDDEN:
			Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	else:
		if Input.mouse_mode != Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

		var shape := Input.CURSOR_CROSS
		var interactable = actor.current_interactable
		if is_instance_valid(interactable) and _can_interact(interactable):
			shape = Input.CURSOR_POINTING_HAND
		Input.set_default_cursor_shape(shape)

	aim_target = get_aim_target(actor)


func _can_interact(interactable: Node) -> bool:
	if interactable.has_method("can_interact"):
		return interactable.can_interact()
	return true


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
