class_name RoomConnector
extends RefCounted

func _link_rooms(
	room_id: String,
	connection: RoomConnection,
	instances: Dictionary
) -> void:
	if not instances.has(room_id):
		return
	
	if not instances.has(connection.target_id):
		return
	
	var room_a: RoomInstance = instances[room_id]
	var room_b: RoomInstance = instances[
		connection.target_id
	]
	
	if not room_a or not room_b:
		return
	
	print("--------------------------------")
	print(room_id, " -> ", connection.target_id)
	print("CONNECTION DIR: ", connection.direction)	
	
	var socket_a = _find_socket(
		room_a.node,
		connection.direction
	)
	
	var socket_b = _find_socket(
		room_b.node,
		_opposite(connection.direction)
	)
	
	print("SOCKET A:", socket_a)
	print("SOCKET B:", socket_b)
	
	if socket_a:
		socket_a.target_room_id = connection.target_id
	
	if socket_b:
		socket_b.target_room_id = room_id

func connect_room(
	graph: RoomGraph,
	_layout: Dictionary,
	instances: Dictionary
) -> void:
	var visited := {}
	
	for room_id in graph.connections.keys():
		print("ROOM:", room_id)
		for connection in graph.connections[room_id]:
			print(
				" -> ",
				connection.target_id,
				" dir=",
				connection.direction
				)
			var key := _pair_key(
				room_id,
				connection.target_id
			)
			
			if visited.has(key):
				continue
			
			visited[key] = true
			
			_link_rooms(
				room_id,
				connection,
				instances
			)

func _find_socket(room: Node3D, dir: DoorSocket.Direction):
	print("Searching room:", room.name)
	
	var sockets := room.find_children(
		"*",
		"DoorSocket",
		true,
		false
	)
	
	for socket in sockets:
		print(
			socket.name,
			" dir=",
			socket.direction
		)
		
		if socket.direction == dir:
			return socket
	
	return null


func _opposite(dir: DoorSocket.Direction) -> DoorSocket.Direction:
	match dir:
		DoorSocket.Direction.NORTH: return DoorSocket.Direction.SOUTH
		DoorSocket.Direction.SOUTH: return DoorSocket.Direction.NORTH
		DoorSocket.Direction.EAST: return DoorSocket.Direction.WEST
		DoorSocket.Direction.WEST: return DoorSocket.Direction.EAST
	return dir


func _pair_key(a: String, b: String) -> String:
	return a if a < b else b
