class_name DynamicRotatingCameraPivot
extends Node3D

@export_category("Rotation")
@export var rotation_speed := 8.0

@export_category("Dynamic Tracking")
@export var follow_speed := 4.0
@export var base_zoom_distance := 25.0
@export var max_extra_zoom := 15.0        ## How far back the camera pulls at max displacement
@export var zoom_sensitivity := 15.0      ## Lower numbers make the zoom scale up faster

# Rotation State
var target_rotation_y := 0.0
var is_rotating := false

# Tracking State
var target_room_node: Node3D = null
var room_size_units := Vector2(40.0, 40.0)

# Child Node Cache
@onready var camera_child: Camera3D = $Camera3D

func _ready() -> void:
	if not camera_child:
		#push_error("DynamicRotatingCameraPivot: Missing direct child Camera3D node!")
		return


func _process(delta: float) -> void:
	# 1. HANDLE SMOOTH TACTICAL SNAPPING ROTATION (Y-Axis)
	rotation.y = lerp_angle(
		rotation.y,
		target_rotation_y,
		rotation_speed * delta
	)
	
	if abs(angle_difference(rotation.y, target_rotation_y)) <= 0.001:
		rotation.y = target_rotation_y
		is_rotating = false

	# 2. SANITY CHECK FOR DYNAMIC TRACKING
	if not Game.player or not is_instance_valid(target_room_node) or not camera_child:
		return
		
	var player_pos := Game.player.global_position
	var room_pos := target_room_node.global_position
	
	# 3. CALCULATE DESIRED FOCUS POINT IN GLOBAL SPACE
	var desired_look_at := (room_pos + player_pos) / 2.0
	
	# Clamp structural camera displacement relative to absolute room grid boundaries
	var offset_from_center := desired_look_at - room_pos
	offset_from_center.x = clamp(offset_from_center.x, -room_size_units.x / 2.0, room_size_units.x / 2.0)
	offset_from_center.z = clamp(offset_from_center.z, -room_size_units.y / 2.0, room_size_units.y / 2.0)
	
	var final_look_target := room_pos + offset_from_center
	
	# 4. TRANSLATE THIS PIVOT NODE TO THE TARGET FOCUS POSITION
	global_position = global_position.lerp(final_look_target, follow_speed * delta)
	
	# 5. NEW: POSITION-RELATIVE ADAPTIVE ZOOM
	# Measure how far the player is from this pivot's center point right now
	var player_displacement := global_position.distance_to(player_pos)
	
	# Scale the factor directly against your sensitivity threshold instead of room sizes
	var extension_factor = clamp(player_displacement / zoom_sensitivity, 0.0, 1.0)
	var target_zoom = base_zoom_distance + (extension_factor * max_extra_zoom)
	
	# 6. RE-POSITION CHILD CAMERA RELATIVELY
	var ideal_local_pos := Vector3(0, target_zoom, target_zoom * 0.85)
	
	# Move the lens back smoothly
	camera_child.position = camera_child.position.lerp(ideal_local_pos, follow_speed * delta)
	
	# Keep the camera lens locked onto this pivot center coordinates point
	camera_child.look_at(global_position, Vector3.UP)


## Public API endpoint called to snap rotation by angles (e.g. 90.0 or -90.0)
func rotate_by(degrees: float) -> void:
	is_rotating = true
	target_rotation_y += deg_to_rad(degrees)


## Public entry pipeline invoked by Game.gd when swapping room environments
func update_room_focus(room_node: Node3D, room_dimensions: Vector2) -> void:
	target_room_node = room_node
	room_size_units = room_dimensions
