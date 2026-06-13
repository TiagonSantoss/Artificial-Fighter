class_name RoomRuntime
extends Node

signal player_entered(room: RoomInstance)
signal player_exited(room: RoomInstance)

var room_instance: RoomInstance

@onready var room_area: Area3D = $"../RoomArea"

func _ready() -> void:
	room_area.body_entered.connect(_on_body_entered)
	room_area.body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	
	player_entered.emit(room_instance)

func _on_body_exited(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	
	player_exited.emit(room_instance)
