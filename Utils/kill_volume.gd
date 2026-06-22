class_name KillVolume
extends Area3D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body == null:
		return
	
	if body is Entity:
		body.queue_free()
