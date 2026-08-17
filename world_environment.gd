extends WorldEnvironment

var rotation_speed := 0.05


func _process(_delta: float) -> void:
	GState.fmod.connect(_on_enter)


func _on_enter():
	print("connected")

	var tween = get_tree().create_tween()

	if environment != null:
		var sky_material = environment.sky.sky_material

		tween.tween_property(sky_material, "shader_parameter/rotation_speed", 1.0, 2.0)
