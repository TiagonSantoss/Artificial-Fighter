class_name DynamicRotatingCameraPivot
extends Node3D

@export_category("Rotation")
@export var rotation_speed := 8.0

@export_category("Dynamic Tracking")
@export var follow_speed := 4.0
@export var tracking_weight_factor := 0.4

@export_category("Orthographic Size Configurations")
## The base orthographic view size of the camera.
@export var base_camera_size := 25.0
## How much the camera size expands when running out to room bounds.
@export var max_extra_size := 15.0

# Rotation State
var target_rotation_y := 0.0
var is_rotating := false

var current_axis := CameraPerspectiveState.Axis.Z_NEGATIVE

# Room Tracking State
var current_room_base_pos := Vector3.ZERO
@export var room_size_units := Vector2(40.0, 40.0)
var is_active_pivot := false

var smoothed_look_target := Vector3.ZERO
var _look_target_initialized := false


func _physics_process(delta: float) -> void:
	if not is_active_pivot or not Game.player:
		return

	var global_camera_rig = Game.instance.camera_rig
	if not is_instance_valid(global_camera_rig):
		return

	# 🟢 Find the actual Camera3D node inside or on your rig to change its .size property
	var actual_camera: Camera3D = null
	if global_camera_rig is Camera3D:
		actual_camera = global_camera_rig
	else:
		actual_camera = global_camera_rig.get_node_or_null("Camera3D") as Camera3D
		if actual_camera == null:
			# Fallback if it's named differently, find first camera child
			for child in global_camera_rig.get_children():
				if child is Camera3D:
					actual_camera = child
					break

	# 1. SMOOTH ROTATION
	_update_perspective()
	rotation.y = lerp_angle(rotation.y, target_rotation_y, rotation_speed * delta)
	if abs(angle_difference(rotation.y, target_rotation_y)) <= 0.001:
		rotation.y = target_rotation_y
		is_rotating = false

	# 2. BLEND LOOK TARGET between room pivot and player
	var player_pos := Game.player.global_position
	var half_width := room_size_units.x / 2.0
	var half_depth := room_size_units.y / 2.0

	var player_offset := player_pos - current_room_base_pos

	var clamped_offset := Vector3(
		clamp(player_offset.x, -half_width, half_width),
		player_offset.y,
		clamp(player_offset.z, -half_depth, half_depth)
	)

	var nx = abs(player_offset.x) / half_width if half_width > 0 else 0.0
	var nz = abs(player_offset.z) / half_depth if half_depth > 0 else 0.0
	var normalized_dist = clamp(max(nx, nz), 0.0, 1.0)
	var zoom_t := smoothstep(0.0, 1.0, normalized_dist)

	var look_target := current_room_base_pos + clamped_offset * tracking_weight_factor

	if not _look_target_initialized:
		smoothed_look_target = look_target
		_look_target_initialized = true

	smoothed_look_target = smoothed_look_target.lerp(look_target, follow_speed * delta)

	# 3. DYNAMIC ORTHOGRAPHIC SIZE (🟢 Changes camera frame size instead of physical distance)
	if is_instance_valid(actual_camera):
		var target_size := base_camera_size + (zoom_t * max_extra_size)
		actual_camera.size = lerp(actual_camera.size, target_size, follow_speed * delta)

	# 4. POSITION CAMERA RIG
	# Keep physical distance constant since size handles the zooming layout frame now
	var constant_distance := 30.0
	var local_offset := Vector3(0.0, constant_distance, constant_distance * 0.85)
	var global_offset := local_offset.rotated(Vector3.UP, rotation.y)

	global_camera_rig.global_position = global_camera_rig.global_position.lerp(
		smoothed_look_target + global_offset, follow_speed * delta
	)

	var pitch := -atan2(local_offset.y, local_offset.z)
	global_camera_rig.rotation.y = rotation.y
	global_camera_rig.rotation.x = pitch
	global_camera_rig.rotation.z = 0.0


func activate(room_size: Vector2) -> void:
	if room_size != Vector2.ZERO:
		room_size_units = room_size
	is_active_pivot = true


func deactivate() -> void:
	is_active_pivot = false


func set_room(room: RoomInstance) -> void:
	if room == null or room.node == null:
		return

	var pivot_node := room.node.find_child("CameraPivot", true, false)
	var target_pos = pivot_node.global_position if pivot_node else room.node.global_position

	var old_rot = rotation.y
	global_position = target_pos
	rotation.y = old_rot
	current_room_base_pos = target_pos

	if room.definition and room.definition.size != Vector2i.ZERO:
		room_size_units = Vector2(room.definition.size) * 40.0
	else:
		if room_size_units == Vector2(40.0, 40.0) or room_size_units == Vector2.ZERO:
			room_size_units = Vector2(40.0, 40.0)

	_look_target_initialized = false


func rotate_by(degrees: float) -> void:
	is_rotating = true
	target_rotation_y += deg_to_rad(degrees)


func get_movement_directions() -> Array[Vector3]:
	var cam := Game.instance.camera_rig
	var forward := cam.global_basis.z
	forward.y = 0.0
	forward = forward.normalized()

	var right := cam.global_basis.x
	right.y = 0.0
	right = right.normalized()

	return [forward, right]


func _update_perspective() -> void:
	var axis := _get_current_axis()

	if axis == current_axis:
		return

	current_axis = axis

	# var _snapshotAA = CameraPerspectiveState.new(current_axis)

	GState.perspective_updated.emit(axis)


func _get_current_axis() -> CameraPerspectiveState.Axis:
	var rot := wrapf(rad_to_deg(target_rotation_y), 0.0, 360.0)
	# print(rot)

	match int(round(rot)):
		0:
			return CameraPerspectiveState.Axis.Z_NEGATIVE

		90:
			return CameraPerspectiveState.Axis.X_POSITIVE

		180:
			return CameraPerspectiveState.Axis.Z_POSITIVE

		270:
			return CameraPerspectiveState.Axis.X_NEGATIVE

	return CameraPerspectiveState.Axis.Z_NEGATIVE


#public
func get_current_axis() -> CameraPerspectiveState.Axis:
	return _get_current_axis()
