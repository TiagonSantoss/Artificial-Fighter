class_name DungeonGenerator
extends RefCounted

var rng := RandomNumberGenerator.new()

func generate(_seed: int, room_pool: Array[RoomDefinition], count: int, start_room: RoomDefinition) -> RoomGraph:
	rng.seed = _seed

	var builder := RoomGraphBuilder.new()
	var graph := builder.create_graph(start_room)

	var open := ["start"]
	var id_counter := 1

	var used_doors := {
		"start": []
	}

	while open.size() > 0 and id_counter < count:
		var current: String = open.pop_front()
		
		if not graph.nodes.has(current):
			push_error("Missing node in graph: " + current)
			continue

		var current_def: RoomDefinition = graph.nodes[current]

		# try ALL available doors, not random count
		var available_dirs := _get_free_doors(current_def, used_doors.get(current, []))

		if available_dirs.is_empty():
			continue # IMPORTANT: don't kill expansion, just skip

		for dir in available_dirs:
			if id_counter >= count:
				break

			var opposite := _opposite(dir)

			var room_def := _pick_compatible_room(room_pool, opposite)
			if room_def == null:
				continue

			var room_id := "room_%d" % id_counter
			id_counter += 1

			builder.add_room(graph, room_id, room_def)
			builder.connect_rooms(graph, current, room_id, dir)

			if not used_doors.has(current):
				used_doors[current] = []
			if not used_doors.has(room_id):
				used_doors[room_id] = []

			used_doors[current].append(dir)
			used_doors[room_id].append(opposite)

			open.append(room_id)

	return graph


func _get_free_doors(room: RoomDefinition, used: Array) -> Array:
	var result := []
	for d in room.available_doors:
		if not used.has(d):
			result.append(d)
	return result


func _opposite(dir: DoorSocket.Direction) -> DoorSocket.Direction:
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


func _pick_compatible_room(pool: Array[RoomDefinition], required: DoorSocket.Direction) -> RoomDefinition:
	var candidates: Array[RoomDefinition] = []

	for room in pool:
		if room.has_door(required):
			candidates.append(room)

	if candidates.is_empty():
		return null

	return candidates[rng.randi_range(0, candidates.size() - 1)]
