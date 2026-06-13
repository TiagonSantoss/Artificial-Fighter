class_name RoomConnector
extends RefCounted

func connect_room(graph: RoomGraph, _layout: Dictionary, instances: Dictionary) -> void:
	var visited := {}
	
	for room_id in graph.connections.keys():
		for connection in graph.connections[room_id]:
			var key := _pair_key(room_id, connection.target_id)
			
			if visited.has(key):
				continue
			
			visited[key] = true
			_link_rooms(room_id, connection, instances)


func _link_rooms(room_id: String, connection: RoomConnection, instances: Dictionary) -> void:
	if not instances.has(room_id) or not instances.has(connection.target_id):
		return
	
	var room_a: RoomInstance = instances[room_id]
	var room_b: RoomInstance = instances[connection.target_id]
	
	var socket_a = _find_socket(room_a.node, connection.direction)
	var socket_b = _find_socket(room_b.node, _opposite(connection.direction))
	
	if socket_a:
		socket_a.target_room_id = connection.target_id
	
	if socket_b:
		socket_b.target_room_id = room_id


func _find_socket(room: Node3D, dir: DoorSocket.Direction):
	var sockets := room.find_children("*", "DoorSocket", true, false)
	
	for socket in sockets:
		if socket.direction == dir:
			return socket
			
	return null


func _opposite(dir: DoorSocket.Direction) -> DoorSocket.Direction:
	match dir:
		DoorSocket.Direction.NORTH: return DoorSocket.Direction.SOUTH
		DoorSocket.Direction.SOUTH: return DoorSocket.Direction.NORTH
		DoorSocket.Direction.EAST:  return DoorSocket.Direction.WEST
		DoorSocket.Direction.WEST:  return DoorSocket.Direction.EAST
	return dir


func _pair_key(a: String, b: String) -> String:
	return a if a < b else b
