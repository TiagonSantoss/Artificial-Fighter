extends Node3D

@onready var collider = $RoomArea


func _ready() -> void:
	collider.body_entered.connect(_on_body_entered)


func _on_body_entered(body):
	if body.is_in_group("player"):
		GState.fmod.emit()
