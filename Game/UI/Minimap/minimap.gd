class_name Minimap
extends Control

@export_category("Visuals")
@export var cell_size := 16.0
@export var spacing := 24.0

@export_category("Colors")
@export var color_current := Color.WHITE
@export var color_visited := Color.WEB_GRAY
@export var color_unseen := Color.DIM_GRAY
@export var color_door := Color.DARK_GRAY

var room_coords: Dictionary = {}  # Maps room_id (String) -> grid position (Vector2i)
var discovered_rooms: Array[String] = []
var current_room_id := ""

var _dungeon_graph: RoomGraph


func _ready() -> void:
	# Wait one frame to ensure DungeonManager finishes generating the map
	await get_tree().process_frame

	# Hook into ChunkManager's room changes
	if GameAutoLoad.chunk_manager:
		GameAutoLoad.chunk_manager.active_room_changed.connect(_on_active_room_changed)
		_dungeon_graph = GameAutoLoad.chunk_manager.graph

		# Build the initial layout map
		if _dungeon_graph != null:
			_build_grid("start")


func _on_active_room_changed(room) -> void:
	if room == null or not "room_id" in room:
		return

	current_room_id = room.room_id

	if not discovered_rooms.has(current_room_id):
		discovered_rooms.append(current_room_id)

	# Queue a redraw of the Control node
	queue_redraw()


# ---------------------------------------------------------
# MAP GENERATION LOGIC
# ---------------------------------------------------------
func _build_grid(start_id: String) -> void:
	room_coords.clear()
	_traverse_graph(start_id, Vector2i.ZERO, [])


func _traverse_graph(room_id: String, coord: Vector2i, visited: Array) -> void:
	if room_id in visited:
		return

	visited.append(room_id)
	room_coords[room_id] = coord

	var connections: Array = _dungeon_graph.connections.get(room_id, [])

	for conn in connections:
		var next_coord := coord

		# Calculate the adjacent grid coordinate based on the door direction
		match conn.direction:
			DoorSocket.Direction.NORTH:
				next_coord.y -= 1
			DoorSocket.Direction.SOUTH:
				next_coord.y += 1
			DoorSocket.Direction.EAST:
				next_coord.x += 1
			DoorSocket.Direction.WEST:
				next_coord.x -= 1

		_traverse_graph(conn.target_id, next_coord, visited)


# ---------------------------------------------------------
# DRAWING LOGIC (Runs every time queue_redraw() is called)
# ---------------------------------------------------------
func _draw() -> void:
	if room_coords.is_empty() or current_room_id == "":
		return

	var center := size / 2.0
	var current_coord: Vector2i = room_coords.get(current_room_id, Vector2i.ZERO)

	# Draw connections (hallways) first so they sit under the rooms
	for room_id in discovered_rooms:
		var coord: Vector2i = room_coords[room_id]
		var connections: Array = _dungeon_graph.connections.get(room_id, [])

		var start_pos := center + Vector2(coord - current_coord) * spacing

		for conn in connections:
			if room_coords.has(conn.target_id) and discovered_rooms.has(conn.target_id):
				var target_coord: Vector2i = room_coords[conn.target_id]
				var end_pos := center + Vector2(target_coord - current_coord) * spacing
				draw_line(start_pos, end_pos, color_door, 4.0)

	# Draw the room boxes
	for room_id in room_coords:
		# Optional: Only draw rooms if they are discovered, or adjacent to a discovered room
		var is_discovered = discovered_rooms.has(room_id)
		var is_adjacent = _is_adjacent_to_discovered(room_id)

		if not is_discovered and not is_adjacent:
			continue

		var coord: Vector2i = room_coords[room_id]
		var offset := coord - current_coord
		var draw_pos := center + Vector2(offset) * spacing

		var rect := Rect2(draw_pos - (Vector2.ONE * (cell_size / 2.0)), Vector2.ONE * cell_size)

		var color := color_unseen
		if room_id == current_room_id:
			color = color_current
		elif is_discovered:
			color = color_visited

		draw_rect(rect, color)


func _is_adjacent_to_discovered(target_id: String) -> bool:
	for visited_id in discovered_rooms:
		var connections: Array = _dungeon_graph.connections.get(visited_id, [])
		for conn in connections:
			if conn.target_id == target_id:
				return true
	return false
