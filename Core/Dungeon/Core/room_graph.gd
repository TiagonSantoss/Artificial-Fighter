class_name RoomGraph
extends RefCounted

var nodes: Dictionary = {}  # id -> RoomVariant   (CHANGED)
var connections := {}  # id -> Array[RoomConnection]


func add_room(id: String, variant: RoomVariant) -> void:  # CHANGED type
	nodes[id] = variant
	connections[id] = []


func connect_room(a: String, b: String, dir: DoorSocket.Direction) -> void:
	var forward := RoomConnection.new()
	forward.target_id = b
	forward.direction = dir
	connections[a].append(forward)

	var back := RoomConnection.new()
	back.target_id = a
	back.direction = DirUtil.opposite(dir)  # CHANGED
	connections[b].append(back)


func get_neighbors(room_id: String) -> Array[String]:
	var neighbor_ids: Array[String] = []

	if connections.has(room_id):
		for connection in connections[room_id]:
			neighbor_ids.append(connection.target_id)

	return neighbor_ids
