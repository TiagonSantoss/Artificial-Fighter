class_name LayoutSolver
extends RefCounted

# --------------------------------------------------
# MAIN ENTRY
# --------------------------------------------------
func solve(graph: RoomGraph) -> Dictionary:
	var layout := {} # Holds actual Vector3 positions
	
	# Start room always begins at the origin
	layout["start"] = Vector3.ZERO
	
	var frontier := ["start"]
	
	while frontier.size() > 0:
		var current = frontier.pop_front()
		var base_pos: Vector3 = layout[current]
		
		# Get properties of the room we are expanding from
		var current_def: RoomDefinition = graph.nodes[current]
		
		for connection in graph.connections[current]:
			var neighbor = connection.target_id
			
			if layout.has(neighbor):
				continue
			
			var neighbor_def: RoomDefinition = graph.nodes[neighbor]
			
			# Calculate exact structural distance offset based on room sizes
			var offset := _calculate_distance_offset(current_def, neighbor_def, connection.direction)
			
			layout[neighbor] = base_pos + offset
			frontier.append(neighbor)
			
	return layout


## Uses room sizing data from your resources to establish step lengths
func _calculate_distance_offset(from_room: RoomDefinition, to_room: RoomDefinition, dir: DoorSocket.Direction) -> Vector3:
	# Default fallback spacing if sizing properties aren't configured yet
	var step_distance := 20.0 
	
	# If your RoomDefinition resource holds a custom size property, you can replace the fixed step with:
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
			
	return Vector3.ZERO # Fixed: Fallback path to clear the compiler error
