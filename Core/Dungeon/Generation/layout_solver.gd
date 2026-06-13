class_name LayoutSolver
extends RefCounted

var dirs := [
	Vector2i.RIGHT,
	Vector2i.LEFT,
	Vector2i.UP,
	Vector2i.DOWN
]

# --------------------------------------------------
# MAIN ENTRY
# --------------------------------------------------
func solve(graph: RoomGraph) -> Dictionary:
	var layout := {}
	var occupied := {}
	
	# start room always at origin
	layout["start"] = Vector2i.ZERO
	occupied[Vector2i.ZERO] = "start"
	
	var frontier := ["start"]
	
	while frontier.size() > 0:
		var current = frontier.pop_front()
		var base = layout[current]
		
		for connection in graph.connections[current]:
			var neighbor = connection.target_id
			
			if layout.has(neighbor):
				continue
			
			var pos = base + _dir_to_vec(
				connection.direction
			)
			
			layout[neighbor] = pos
			occupied[pos] = neighbor
			
			frontier.append(neighbor)
	return layout

func _dir_to_vec(
	dir: DoorSocket.Direction
) -> Vector2i:
	match dir:
		DoorSocket.Direction.NORTH:
			return Vector2i.UP
		
		DoorSocket.Direction.SOUTH:
			return Vector2i.DOWN
		
		DoorSocket.Direction.EAST:
			return Vector2i.RIGHT
		
		DoorSocket.Direction.WEST:
			return Vector2i.LEFT
			
	return Vector2i.ZERO

# --------------------------------------------------
# SAFE POSITION FINDING
# --------------------------------------------------
func _find_free_position(base: Vector2i, dir_index: int, occupied: Dictionary) -> Vector2i:
	var pos = base + dirs[dir_index % dirs.size()]
	
	var tries := 0
	while occupied.has(pos) and tries < 10:
		pos += dirs[(dir_index + tries) % dirs.size()]
		tries += 1
	
	return pos
