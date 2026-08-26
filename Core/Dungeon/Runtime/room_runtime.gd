class_name RoomRuntime
extends Node

signal player_entered(room: RoomInstance)
signal player_exited(room: RoomInstance)

var room_instance: RoomInstance

var is_active := false
var is_locked := false
var cleared := false

@onready var room_area: Area3D = $"../RoomArea"
@onready var spawn_point: Marker3D = get_node_or_null("$../SpawnPoint")
@onready var arena: ArenaBarrierRoot = get_node_or_null("$ArenaBarrierRoot")


func _ready() -> void:
	room_area.body_entered.connect(_on_room_area_body_entered)
	room_area.body_exited.connect(_on_room_area_body_exited)
	add_to_group("rooms")


func _on_room_area_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return

	player_entered.emit(room_instance)


func _on_room_area_body_exited(body: Node) -> void:
	if not body.is_in_group("player"):
		return

	player_exited.emit(room_instance)


func set_active(value: bool) -> void:
	is_active = value

	if room_instance:
		room_instance.set_active(value)


func set_locked(value: bool) -> void:
	is_locked = value

	if arena:
		arena.set_locked(value)
