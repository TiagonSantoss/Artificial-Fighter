class_name LayoutSolver
extends RefCounted


func solve(graph: RoomGraph) -> Dictionary:
	var layout := {}
	var frontier := ["start"]
	var occupied_positions := {Vector3.ZERO: "start"}

	var layout_loops := {}

	layout["start"] = Vector3.ZERO

	while frontier.size() > 0:
		var current = frontier.pop_front()
		var base_pos: Vector3 = layout[current]
		var current_variant: RoomVariant = graph.nodes[current]

		if not graph.connections.has(current):
			continue

		for connection in graph.connections[current]:
			var neighbor = connection.target_id
			if layout.has(neighbor):
				continue

			var neighbor_variant: RoomVariant = graph.nodes[neighbor]
			var offset := _calculate_distance_offset(
				current_variant, neighbor_variant, connection.direction
			)
			var target_pos := base_pos + offset

			var snapped_pos := Vector3(
				snapped(target_pos.x, 0.01),
				snapped(target_pos.y, 0.01),
				snapped(target_pos.z, 0.01)
			)

			if occupied_positions.has(snapped_pos):
				var existing_neighbor = occupied_positions[snapped_pos]

				if not layout_loops.has(current):
					layout_loops[current] = []
				if not layout_loops[current].has(existing_neighbor):
					layout_loops[current].append(existing_neighbor)

				continue

			layout[neighbor] = target_pos
			occupied_positions[snapped_pos] = neighbor
			frontier.append(neighbor)

	return layout


func _calculate_distance_offset(
	from_variant: RoomVariant, to_variant: RoomVariant, dir: DoorSocket.Direction
) -> Vector3:
	var room_unit_size := 40.0
	var step_cells := 0.0

	var from_size := from_variant.get_size()
	var to_size := to_variant.get_size()

	match dir:
		DoorSocket.Direction.NORTH, DoorSocket.Direction.SOUTH:
			step_cells = (from_size.y + to_size.y) / 2.0
		DoorSocket.Direction.EAST, DoorSocket.Direction.WEST:
			step_cells = (from_size.x + to_size.x) / 2.0

	return _dir_to_vec3(dir) * step_cells * room_unit_size


func _dir_to_vec3(dir: DoorSocket.Direction) -> Vector3:
	match dir:
		DoorSocket.Direction.NORTH:
			return Vector3.FORWARD
		DoorSocket.Direction.SOUTH:
			return Vector3.BACK
		DoorSocket.Direction.EAST:
			return Vector3.RIGHT
		DoorSocket.Direction.WEST:
			return Vector3.LEFT

	return Vector3.ZERO
