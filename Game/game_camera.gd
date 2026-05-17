class_name GameCamera
extends Camera3D

@export var start_size := 20.0
@export var target_size := 8.0
@export var zoom_duration := 2.0
@export var wait_time := 1.5

func _ready():
	size = start_size
	
	await get_tree().create_timer(wait_time).timeout
	var tween := create_tween()
	tween.tween_property(self, "size", target_size, zoom_duration)
