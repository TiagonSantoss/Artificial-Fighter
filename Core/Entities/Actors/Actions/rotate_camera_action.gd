class_name RotateCameraAction
extends Action

var degrees: float


func _init(rot_degrees: float) -> void:
	degrees = rot_degrees


func execute(_actor: Entity, _delta: float) -> void:
	if GameAutoLoad:
		# 1. Rotate the global camera orbit system inside Game.gd
		GameAutoLoad.rotate_by(degrees)

		# 2. Automatically sync the Minimap rotation if it exists in your UI
		if GameAutoLoad.instance.has_node("UI/Minimap"):
			var minimap = GameAutoLoad.get_node("UI/Minimap")
			if minimap.has_method("rotate_map_to"):
				minimap.rotate_map_to(rad_to_deg(GameAutoLoad.target_rotation_y))
