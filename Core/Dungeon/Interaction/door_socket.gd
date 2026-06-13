class_name DoorSocket
extends Node3D

enum Direction {
	NORTH,
	SOUTH,
	EAST,
	WEST
}

@export var direction: Direction

var room_id: String
var target_room_id: String

func _ready():
	add_to_group("door_socket")
