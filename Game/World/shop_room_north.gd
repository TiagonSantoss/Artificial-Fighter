class_name UpdateTVs extends Node3D

@onready var x_area = $x_area
@onready var z_area = $z_area


func _ready() -> void:
	x_area.body_entered.connect(_on_x_area_body_entered)
	z_area.body_entered.connect(_on_z_area_body_entered)

	x_area.body_exited.connect(_on_area_body_exited)
	z_area.body_exited.connect(_on_area_body_exited)


func _on_x_area_body_entered(body: Node3D) -> void:
	if body is Entity:
		if body.entity_id == 0 or body.entity_id == 1:
			if GState.current_perspective != null:
				if (
					GState.current_perspective.active_axis == CameraPerspectiveState.Axis.X_POSITIVE
					or (
						GState.current_perspective.active_axis
						== CameraPerspectiveState.Axis.X_NEGATIVE
					)
				):
					GState.shop_activation_requested.emit(true)


func _on_z_area_body_entered(body: Node3D) -> void:
	if body is Entity:
		if body.entity_id == 0 or body.entity_id == 1:
			if GState.current_perspective != null:
				if (
					GState.current_perspective.active_axis == CameraPerspectiveState.Axis.Z_POSITIVE
					or (
						GState.current_perspective.active_axis
						== CameraPerspectiveState.Axis.Z_NEGATIVE
					)
				):
					GState.shop_activation_requested.emit(true)


func _on_area_body_exited(body: Node3D) -> void:
	if body is Entity:
		if body.entity_id == 0 or body.entity_id == 1:
			GState.shop_activation_requested.emit(false)
