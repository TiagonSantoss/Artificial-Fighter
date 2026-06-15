class_name DynamicRotatingCameraPivot
extends Node3D

@export_category("Rotation")
@export var rotation_speed := 8.0

@export_category("Dynamic Tracking")
@export var follow_speed := 4.0
@export_category("Zoom Configurations")
@export var base_zoom_distance := 25.0
@export var max_extra_zoom := 15.0
@export var zoom_sensitivity := 15.0

# Rotation State
var target_rotation_y := 0.0
var is_rotating := false

# Tracking State
var current_room_base_pos := Vector3.ZERO
var room_size_units := Vector2(40.0, 40.0)

@onready var camera_child: Camera3D = $Camera3D


func _process(delta: float) -> void:
	# 1. ROTATION
	rotation.y = lerp_angle(
		rotation.y,
		target_rotation_y,
		rotation_speed * delta
	)

	if abs(angle_difference(rotation.y, target_rotation_y)) <= 0.001:
		rotation.y = target_rotation_y
		is_rotating = false

	# 2. VALIDATION
	if not Game.player or not camera_child:
		return

	var player_pos := Game.player.global_position
	# Use our new dynamic snapping vector position instead of a static node pointer
	var room_pos := current_room_base_pos 

	# ------------------------------------------------------------
	# 3. PIVOT POSITION (Dynamic player tracking within clamped box bounds)
	# ------------------------------------------------------------
	var desired_look_at := (room_pos + player_pos) / 2.0

	var offset_from_center := desired_look_at - room_pos
	offset_from_center.x = clamp(offset_from_center.x, -room_size_units.x / 2.0, room_size_units.x / 2.0)
	offset_from_center.z = clamp(offset_from_center.z, -room_size_units.y / 2.0, room_size_units.y / 2.0)

	var final_look_target := room_pos + offset_from_center

	# Smoothly slide the pivot position
	global_position = global_position.lerp(final_look_target, follow_speed * delta)

	# ------------------------------------------------------------
	# 4. FIXED ZOOM
	# ------------------------------------------------------------
	var player_offset := player_pos - room_pos
	player_offset.y = 0.0

	var half_size := room_size_units * 0.5

	var nx = abs(player_offset.x) / half_size.x if half_size.x > 0 else 0.0
	var nz = abs(player_offset.z) / half_size.y if half_size.y > 0 else 0.0

	var normalized_dist = clamp(max(nx, nz), 0.0, 1.0)
	var zoom_t := smoothstep(0.0, 1.0, normalized_dist)

	var target_zoom := base_zoom_distance + (zoom_t * max_extra_zoom)

	# ------------------------------------------------------------
	# 5. CAMERA POSITION AND LENS DIRECTION
	# ------------------------------------------------------------
	var ideal_local_pos := Vector3(0, target_zoom, target_zoom * 0.85)

	camera_child.position = camera_child.position.lerp(
		ideal_local_pos,
		follow_speed * delta
	)

	camera_child.look_at(global_position, Vector3.UP)


func rotate_by(degrees: float) -> void:
	is_rotating = true
	target_rotation_y += deg_to_rad(degrees)


# Hook called by Game.gd process frame loop to smoothly guide the tracking system
func update_room_focus_position(target_position: Vector3) -> void:
	current_room_base_pos = target_position
