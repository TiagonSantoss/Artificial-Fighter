class_name DynamicRotatingCameraPivot
extends Node3D

@export_category("Rotation")
@export var rotation_speed := 8.0

@export_category("Dynamic Tracking")
@export var follow_speed := 4.0
@export var tracking_weight := 2.0

@export_category("Zoom Configurations")
@export var base_zoom_distance := 25.0
@export var max_extra_zoom := 15.0
@export var zoom_sensitivity := 15.0

# Rotation State (Static fallback values to prevent undefined jumps)
var target_rotation_y := 0.0
var is_rotating := false

# Room Tracking State
var current_room_base_pos := Vector3.ZERO
var room_size_units := Vector2(40.0, 40.0)
var is_active_pivot := false

var smoothed_look_target := Vector3.ZERO
var _look_target_initialized := false

func _physics_process(delta: float) -> void:
	if not is_active_pivot or not Game.player:
		return
	
	var global_camera = Game.instance.camera_rig
	if not is_instance_valid(global_camera):
		return
	
	# 1. SMOOTH ROTATION
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
		player_offset.y,  # keep vertical tracking
		clamp(player_offset.z, -half_depth, half_depth)
	)
	
	var nx = abs(player_offset.x) / half_width if half_width > 0 else 0.0
	var nz = abs(player_offset.z) / half_depth if half_depth > 0 else 0.0
	var normalized_dist = clamp(max(nx, nz), 0.0, 1.0)
	var zoom_t := smoothstep(0.0, 1.0, normalized_dist)
	
	var tracking_weight := 0.4
	var look_target := current_room_base_pos + clamped_offset * tracking_weight
	
	# Initialize on first frame so there's no snap from Vector3.ZERO
	if not _look_target_initialized:
		smoothed_look_target = look_target
		_look_target_initialized = true
	
	# Lerp from PREVIOUS smoothed value, not from base pos every frame
	smoothed_look_target = smoothed_look_target.lerp(look_target, follow_speed * delta)
	
	# 3. DYNAMIC ZOOM
	var target_zoom := base_zoom_distance + (zoom_t * max_extra_zoom)
	
	# 4. POSITION CAMERA
	var local_offset := Vector3(0.0, target_zoom, target_zoom * 0.85)
	var global_offset := local_offset.rotated(Vector3.UP, rotation.y)
	
	global_camera.global_position = global_camera.global_position.lerp(
		smoothed_look_target + global_offset,
		follow_speed * delta
	)
	
	# 5. LOOK AT smoothed target
	global_camera.look_at(smoothed_look_target, Vector3.UP)
	global_camera.rotation.x = clamp(global_camera.rotation.x, -PI/2, 0.0)
	global_camera.rotation.z = 0.0


func activate(room_size: Vector2) -> void:
	# FIX: We no longer pull values from the camera rig here.
	# The script keeps its own clean rotation.y and target_rotation_y 
	# state across swaps, meaning ongoing spins will never get broken or locked.
	room_size_units = room_size
	is_active_pivot = true


func deactivate() -> void:
	is_active_pivot = false


func set_room(room: RoomInstance) -> void:
	if room == null or room.node == null:
		return
	
	var pivot_node := room.node.find_child("CameraPivot", true, false)
	
	if pivot_node:
		# Preserve our current rotation value so it doesn't drop to 0
		var old_rot = rotation.y
		global_position = pivot_node.global_position
		rotation.y = old_rot
		
		current_room_base_pos = pivot_node.global_position
		
		if room.definition and room.definition.size != Vector2i.ZERO:
			room_size_units = Vector2(room.definition.size) * 40.0
		else:
			room_size_units = Vector2(500.0, 500.0) 
	else:
		var old_rot = rotation.y
		global_position = room.node.global_position
		rotation.y = old_rot
		
		current_room_base_pos = room.node.global_position
		
		if room.definition:
			room_size_units = Vector2(room.definition.size) * 40.0
		else:
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
