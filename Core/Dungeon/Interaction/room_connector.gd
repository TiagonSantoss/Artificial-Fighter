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

	var socket_a = _find_socket(room_a.node, connection.direction, room_a.rotation_steps)
	var socket_b = _find_socket(
		room_b.node, DirUtil.opposite(connection.direction), room_b.rotation_steps
	)

	if socket_a:
		socket_a.target_room_id = connection.target_id

	if socket_b:
		socket_b.target_room_id = room_id


func _find_socket(room: Node3D, dir: DoorSocket.Direction, steps: int):
	for socket in room.find_children("*", "DoorSocket", true, false):
		if DirUtil.rotate(socket.direction, steps) == dir:
			return socket
	return null


func _pair_key(a: String, b: String) -> String:
	return "%s|%s" % [a, b] if a < b else "%s|%s" % [b, a]
