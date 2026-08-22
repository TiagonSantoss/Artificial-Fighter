class_name DynamicRotatingCameraPivot
extends Node3D

@export_category("Rotation")
@export var rotation_speed := 8.0

@export_category("Dynamic Tracking")
@export var follow_speed := 16.0
@export var tracking_weight_factor := 0.4

@export_category("Size Configurations")
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

# Cached Camera Reference
var _cached_camera: Camera3D = null


func _physics_process(delta: float) -> void:
	if not is_active_pivot or not Game.player:
		return

	var global_camera_rig = GameAutoLoad.camera_rig

	if not is_instance_valid(global_camera_rig):
		return

	# Cache camera reference if not found yet or invalid
	if not is_instance_valid(_cached_camera):
		_cached_camera = _find_camera_node(global_camera_rig)

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

	# 1. Rotate the offset to match the camera's current angle
	var local_offset := player_offset.rotated(Vector3.UP, -rotation.y)

	# 2. Clamp based on the camera's local screen axes
	var clamped_local := Vector3(
		clamp(local_offset.x, -half_width, half_width),
		local_offset.y,
		clamp(local_offset.z, -half_depth, half_depth)
	)

	var nx = abs(local_offset.x) / half_width if half_width > 0 else 0.0
	var nz = abs(local_offset.z) / half_depth if half_depth > 0 else 0.0
	var normalized_dist = clamp(max(nx, nz), 0.0, 1.0)
	var zoom_t := smoothstep(0.0, 1.0, normalized_dist)

	# 3. Rotate the clamped result back into absolute world space
	var clamped_world_offset := clamped_local.rotated(Vector3.UP, rotation.y)

	var look_target := current_room_base_pos + clamped_world_offset * tracking_weight_factor

	if not _look_target_initialized:
		smoothed_look_target = look_target
		_look_target_initialized = true

		# Immediately set camera size on room enter so it doesn't lerp from old scale
		if is_instance_valid(_cached_camera):
			_cached_camera.size = base_camera_size + (zoom_t * max_extra_size)

	smoothed_look_target = smoothed_look_target.lerp(look_target, follow_speed * delta)

	# 3. DYNAMIC ORTHOGRAPHIC SIZE
	if is_instance_valid(_cached_camera):
		var target_size := base_camera_size + (zoom_t * max_extra_size)
		_cached_camera.size = lerp(_cached_camera.size, target_size, follow_speed * delta)

	# 4. POSITION CAMERA RIG
	var constant_distance := 15.0
	var camera_local_offset := Vector3(0.0, constant_distance, constant_distance * 0.85)
	var global_offset := camera_local_offset.rotated(Vector3.UP, rotation.y)

	global_camera_rig.global_position = global_camera_rig.global_position.lerp(
		smoothed_look_target + global_offset, follow_speed * delta
	)

	# var pitch := -atan2(local_offset.y, local_offset.z)
	global_camera_rig.rotation.y = rotation.y
	# global_camera_rig.rotation.x = pitch
	global_camera_rig.rotation.z = 0.0


func activate(_room_size: Vector2 = Vector2.ZERO) -> void:
	# if room_size != Vector2.ZERO:
	# 	room_size_units = room_size
	is_active_pivot = true


func set_room(room: RoomInstance) -> void:
	if room == null or room.node == null:
		return

	var pivot_node := room.node.find_child("CameraPivot", true, false)
	var target_pos = pivot_node.global_position if pivot_node else room.node.global_position

	var old_rot = rotation.y
	global_position = target_pos
	rotation.y = old_rot
	current_room_base_pos = target_pos

	if room.definition and room.definition.size.x > 10 and room.definition.size.y > 10:
		room_size_units = Vector2(room.definition.size)

	_look_target_initialized = false


func deactivate() -> void:
	is_active_pivot = false


func rotate_by(degrees: float) -> void:
	is_rotating = true
	target_rotation_y += deg_to_rad(degrees)


func get_movement_directions() -> Array[Vector3]:
	var cam := GameAutoLoad.camera_rig
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
	GState.perspective_updated.emit(axis)


func _get_current_axis() -> CameraPerspectiveState.Axis:
	var rot := wrapf(rad_to_deg(target_rotation_y), 0.0, 360.0)

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


func get_current_axis() -> CameraPerspectiveState.Axis:
	return _get_current_axis()


func _find_camera_node(rig: Node3D) -> Camera3D:
	if rig is Camera3D:
		return rig as Camera3D

	var cam := rig.get_node_or_null("Camera3D") as Camera3D
	if cam:
		return cam

	for child in rig.get_children():
		if child is Camera3D:
			return child as Camera3D

	return null
