class_name RoomGraph
extends RefCounted

var nodes: Dictionary = {}      # id -> RoomDefinition
var connections := {}			# id -> Array[String]

func add_room(
	id: String,
	definition: RoomDefinition
) -> void:
	nodes[id] = definition
	connections[id] = []

func connect_room(
	a: String,
	b: String,
	dir: DoorSocket.Direction
) -> void:
	var forward := RoomConnection.new()
	forward.target_id = b
	forward.direction = dir
	
	connections[a].append(forward)
	
	var back := RoomConnection.new()
	back.target_id = a
	back.direction = _opposite(dir)
	
	connections[b].append(back)

func _opposite(
	dir: DoorSocket.Direction
) -> DoorSocket.Direction:
	match dir:
		DoorSocket.Direction.NORTH:
			return DoorSocket.Direction.SOUTH
		
		DoorSocket.Direction.SOUTH:
			return DoorSocket.Direction.NORTH
		
		DoorSocket.Direction.EAST:
			return DoorSocket.Direction.WEST
		
		DoorSocket.Direction.WEST:
			return DoorSocket.Direction.EAST
			
	return dir
