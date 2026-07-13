class_name CameraPerspectiveState
extends RefCounted

enum Axis { X_POSITIVE, X_NEGATIVE, Z_POSITIVE, Z_NEGATIVE }  # Right  # Left  # Forward  # Backward

var active_axis: Axis
var tracked_entity_id: int
var screen_position: Vector2


func _init(p_axis: Axis, p_id: int, p_pos: Vector2) -> void:
	active_axis = p_axis
	tracked_entity_id = p_id
	screen_position = p_pos
