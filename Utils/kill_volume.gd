class_name KillVolume
extends Area3D


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if body == null:
		return

	if body is Entity:
		var controller = body.controller
		if controller is CompanionController or controller is PlayerController:
			body.position = Vector3(0,0,0)
			return

		body.health_component.damage(999)
