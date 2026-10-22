class_name RoomRuntime
extends Node

var room_instance: RoomInstance

var is_active := false
var is_locked := false
var cleared := false

@onready var spawn_point: Marker3D = get_node_or_null("../SpawnPoint")
@onready var arena: ArenaBarrierRoot = get_node_or_null("../ArenaBarrierRoot")


func _ready() -> void:
	add_to_group("rooms")


func set_active(value: bool) -> void:
	is_active = value


func set_locked(value: bool) -> void:
	is_locked = value

	if arena:
		arena.set_locked(value)
