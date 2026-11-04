class_name RotateCameraAction
extends Action

var degrees: float


func _init(rot_degrees: float) -> void:
	degrees = rot_degrees


func execute(_actor: Entity, _delta: float) -> void:
	if GameAutoLoad:
		FmodServer.play_one_shot("event:/SFX/UI/CameraRotate")
		GameAutoLoad.rotate_by(degrees)

		if GameAutoLoad.instance.has_node("UI/Minimap"):
			var minimap = GameAutoLoad.get_node("UI/Minimap")
			if minimap.has_method("rotate_map_to"):
				minimap.rotate_map_to(rad_to_deg(GameAutoLoad.target_rotation_y))
 