class_name RoomRenderer
extends Node3D

@export var generator: RoomGenerator
@export var start_room: RoomDefinition
@export var room_pool: Array[RoomDefinition]

const CELL_SIZE = 8

func _ready():
	var rooms = generator.generate(start_room, room_pool)
	print("TOTAL ROOMS:", rooms.size())
	
	for room in rooms:
		print("ROOM:", room.def, "OFFSET:", room.offset)
		
		var node = room.def.scene.instantiate()
		node.position = Vector3(
			room.offset.x,
			0,
			room.offset.z
		)
		print("WORLD:", node.position)
		add_child(node)
