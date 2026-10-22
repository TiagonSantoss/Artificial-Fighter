class_name ChunkManager
extends Node3D

signal room_loaded(room: RoomInstance)
signal room_unloaded(room: RoomInstance)
signal active_room_changed(room_instance: RoomInstance)

var graph: RoomGraph
var layout: Dictionary

var generator: DungeonGenerator
var layout_solver: LayoutSolver
var connector := RoomConnector.new()
var room_spawner: RoomSpawner

var loaded_rooms := {}
var room_states := {}  # NEW: room_id -> RoomState

var current_room: RoomInstance
var start_room_instance: RoomInstance
var visited_rooms := {}

var is_teleporting := false


func _ready() -> void:
	GameAutoLoad.chunk_manager = self
	room_spawner = RoomSpawner.new()
	add_child(room_spawner)


# --------------------------------------------------
# INIT PIPELINE
# --------------------------------------------------
func generate(
	_seed: int, room_pool: Array[RoomDefinition], count: int, start_room: RoomDefinition
) -> void:
	generator = DungeonGenerator.new()
	graph = generator.generate(_seed, room_pool, count, start_room)
	layout = LayoutSolver.new().solve(graph)

	loaded_rooms.clear()
	room_states.clear()  # Reset memory for new runs
	current_room = null
	visited_rooms.clear()

	# teleport_player("start", DoorSocket.Direction.SPECIAL)


# --------------------------------------------------
# TELEPORT LOGIC (With Fades & State)
# --------------------------------------------------
func teleport_player(target_room_id: String, exited_direction: DoorSocket.Direction) -> void:
	# 1. Start screen transition (assuming you make a ScreenFader autoload)
	# If you don't have this yet, just comment it out!
	if is_teleporting:
		return

	is_teleporting = true

	if GameAutoLoad.has_node("ScreenFader"):
		await GameAutoLoad.get_node("ScreenFader").fade_to_black()

	var old_room_id = current_room.room_id if current_room else ""

	# 2. Unload Old Room (This now saves its state automatically)
	if old_room_id != "" and old_room_id != target_room_id:
		_unload_room(old_room_id)

	# 3. Load New Room (This now restores its state automatically)
	if not loaded_rooms.has(target_room_id):
		_load_room(target_room_id)

	var new_room: RoomInstance = loaded_rooms[target_room_id]

	# 4. Position the player
	var spawn_position: Vector3 = new_room.world_origin

	if exited_direction != DoorSocket.Direction.SPECIAL:
		var entry_dir = _opposite(exited_direction)
		var entry_socket = _find_door_in_room(new_room.node, entry_dir)

		if entry_socket:
			spawn_position = entry_socket.global_position
			spawn_position += _get_push_vector(entry_dir) * 2.0

	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.global_position = spawn_position

	_set_current_room(new_room)

	await get_tree().create_timer(1.2).timeout
	is_teleporting = false


func _set_current_room(room: RoomInstance) -> void:
	current_room = room
	visited_rooms[room.room_id] = true
	active_room_changed.emit(room)


# --------------------------------------------------
# STATE MANAGEMENT & ENGINE OPS
# --------------------------------------------------
func _load_room(id: String) -> void:
	var def: RoomDefinition = graph.nodes[id]
	var logical_pos: Vector3 = layout.get(id, Vector3.ZERO)
	var grid_pos := Vector2i(roundi(logical_pos.x), roundi(logical_pos.z))

	var room := room_spawner.spawn_room(id, def, grid_pos, Vector3.ZERO)

	if id == "start":
		start_room_instance = room

	loaded_rooms[id] = room

	_configure_doors(room)

	# --- RESTORE ROOM STATE ---
	if room_states.has(id):
		var state: RoomState = room_states[id]
		room.cleared = state.cleared
		room.encounter_started = state.encounter_started

		# If the room was already cleared, we need to enforce that visually.
		if room.cleared:
			_clear_enemies(room)
			room.unlock_room()

	# Wire runtime
	var runtime := room.node.find_child("RoomRuntime", true, false) as RoomRuntime
	if runtime:
		runtime.room_instance = room
		runtime.set_active(true)

	room_loaded.emit(room)


func _unload_room(id: String) -> void:
	if not loaded_rooms.has(id):
		return
	var room: RoomInstance = loaded_rooms[id]

	# --- SAVE ROOM STATE ---
	var state = RoomState.new()
	state.cleared = room.cleared
	state.encounter_started = room.encounter_started
	# (Save items/enemy HP here later)
	room_states[id] = state

	# Despawn
	room_unloaded.emit(room)
	room_spawner.despawn_room(id)
	loaded_rooms.erase(id)


# --------------------------------------------------
# HELPERS
# --------------------------------------------------
func _clear_enemies(room: RoomInstance) -> void:
	# Example helper: find all entities in the room and remove them if it was previously cleared
	var enemies_node = room.node.find_child("Enemies", true, false)
	if enemies_node:
		for child in enemies_node.get_children():
			child.queue_free()


func _find_door_in_room(room_node: Node3D, dir: DoorSocket.Direction) -> Area3D:
	var sockets = room_node.find_children("*", "DoorSocket", true, false)
	for socket in sockets:
		if socket.direction == dir:
			return socket
	return null


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


func _get_push_vector(dir: DoorSocket.Direction) -> Vector3:
	match dir:
		DoorSocket.Direction.NORTH:
			return Vector3(0, 0, 1)
		DoorSocket.Direction.SOUTH:
			return Vector3(0, 0, -1)
		DoorSocket.Direction.EAST:
			return Vector3(-1, 0, 0)
		DoorSocket.Direction.WEST:
			return Vector3(1, 0, 0)
	return Vector3.ZERO


func _configure_doors(room: RoomInstance) -> void:
	# 1. Get all doors in the physical scene
	var sockets = room.node.find_children("*", "DoorSocket", true, false)

	# 2. Get the logical connections for this room from the Graph
	var logic_connections: Array = graph.connections.get(room.room_id, [])

	for socket in sockets:
		var matching_connection: RoomConnection = null
		print(
			"socket:",
			socket,
			"array:",
		)

		# 3. Check if this physical door has a matching logical connection
		for conn in logic_connections:
			if conn.direction == socket.direction:
				print(conn.direction)
				matching_connection = conn
				break

		# 4. Apply the data or remove the door
		if matching_connection:
			socket.target_room_id = matching_connection.target_id
			# Ensure the door is active
			socket.monitoring = true
			socket.show()
		else:
			# This door is a dead-end according to the dungeon generator.
			# You can queue_free() it, or hide it and enable a static wall model in its place.
			socket.queue_free()


func clear() -> void:
	for id in loaded_rooms.keys().duplicate():
		_unload_room(id)

	loaded_rooms.clear()
	room_states.clear()
	visited_rooms.clear()
	layout.clear()

	graph = null
	current_room = null
	start_room_instance = null
