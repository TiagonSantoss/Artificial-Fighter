class_name LayoutSolver
extends RefCounted

# --------------------------------------------------
# MAIN ENTRY
# --------------------------------------------------
func solve(graph: RoomGraph) -> Dictionary:
	var layout := {} 
	var frontier := ["start"]
	var occupied_positions := { Vector3.ZERO: "start" }
	
	# NEW: Pure runtime storage for layout loops, keeping RoomGraph untouched!
	# Key: room_id -> Value: Array of neighbor room_ids it fused with
	var layout_loops := {} 

	layout["start"] = Vector3.ZERO
	
	while frontier.size() > 0:
		var current = frontier.pop_front()
		var base_pos: Vector3 = layout[current]
		var current_def: RoomDefinition = graph.nodes[current]
		
		if not graph.connections.has(current): continue
			
		for connection in graph.connections[current]:
			var neighbor = connection.target_id
			if layout.has(neighbor): continue
				
			var neighbor_def: RoomDefinition = graph.nodes[neighbor]
			var offset := _calculate_distance_offset(current_def, neighbor_def, connection.direction)
			var target_pos := base_pos + offset
			
			var snapped_pos := Vector3(
				snapped(target_pos.x, 0.01),
				snapped(target_pos.y, 0.01),
				snapped(target_pos.z, 0.01)
			)
			
			# --------------------------------------------------
			# PHILOSOPHY PRESERVING SAFETY NET
			# --------------------------------------------------
			if occupied_positions.has(snapped_pos):
				var existing_neighbor = occupied_positions[snapped_pos]
				
				# Record the loop connection locally in the runtime solver system
				if not layout_loops.has(current): layout_loops[current] = []
				if not layout_loops[current].has(existing_neighbor):
					layout_loops[current].append(existing_neighbor)
				
				continue # Graph remains completely untouched and pristine!
				
			layout[neighbor] = target_pos
			occupied_positions[snapped_pos] = neighbor
			frontier.append(neighbor)
			
	# You can optionally return both the layout positions and the loops data structure 
	# by wrapping them in a custom Dictionary or specialized LayoutResult object.
	return layout


## Uses room sizing data from your resources to establish step lengths
func _calculate_distance_offset(_from_room: RoomDefinition, _to_room: RoomDefinition, dir: DoorSocket.Direction) -> Vector3:
	var step_distance := 20.0 
	
	# If your RoomDefinition resource holds a custom size property, use this instead:
	# var step_distance = (from_room.room_size + to_room.room_size) / 2.0
	
	var dir_unit := _dir_to_vec3(dir)
	return dir_unit * step_distance


func _dir_to_vec3(dir: DoorSocket.Direction) -> Vector3:
	match dir:
		DoorSocket.Direction.NORTH:
			return Vector3.FORWARD # Vector3(0, 0, -1)
		DoorSocket.Direction.SOUTH:
			return Vector3.BACK    # Vector3(0, 0, 1)
		DoorSocket.Direction.EAST:
			return Vector3.RIGHT   # Vector3(1, 0, 0)
		DoorSocket.Direction.WEST:
			return Vector3.LEFT    # Vector3(-1, 0, 0)
			
	return Vector3.ZERO
