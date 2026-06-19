#@tool
class_name ChunkManager
extends Node3D

@export var room_scene_size := 40.0
@export var load_radius := 1

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

var current_room: RoomInstance
var start_room_instance: RoomInstance

var visited_rooms := {} # room_id -> bool


# --------------------------------------------------
# INIT PIPELINE
# --------------------------------------------------

func generate(
	_seed: int,
	room_pool: Array[RoomDefinition],
	count: int,
	start_room: RoomDefinition
) -> void:
	
	var gen := DungeonGenerator.new()
	generator = gen
	
	graph = generator.generate(
		_seed,
		room_pool,
		count,
		start_room
	)
	
	layout = LayoutSolver.new().solve(graph)
	
	loaded_rooms.clear()
	current_room = null
	visited_rooms.clear()
	
	_update_room_streaming("start")


func _ready() -> void:
	room_spawner = RoomSpawner.new()
	add_child(room_spawner)


# --------------------------------------------------
# ACTIVE ROOM MANAGEMENT
# --------------------------------------------------

func set_current_room(room: RoomInstance) -> void:
	if room == null:
		return
	
	if current_room == room:
		return
	
	current_room = room
	
	visited_rooms[room.room_id] = true
	
	_update_room_streaming(room.room_id)
	
	active_room_changed.emit(room)


# --------------------------------------------------
# CORE ROOM STREAMING LOGIC
# --------------------------------------------------

func _update_room_streaming(current_room_id: String) -> void:
	# 1. Always keep the room the player is standing in active
	var active_room_ids : Array[String] = [current_room_id]
	
	# 2. Query your layout graph structure directly for immediate neighbor rooms
	if graph.nodes.has(current_room_id):
		# Replace '.get_neighbors' with your actual graph layout connectivity function
		for neighbor_id in graph.get_neighbors(current_room_id):
			active_room_ids.append(neighbor_id)
			
	# 3. Unload any rooms that are no longer immediate neighbors
	for id in loaded_rooms.keys():
		if not id in active_room_ids:
			_unload_room(id) # Or your custom function that removes/hides the room node
			
	# 4. Load or show rooms that are direct structural neighbors
	for id in active_room_ids:
		if not loaded_rooms.has(id):
			_load_room(id)

# --------------------------------------------------
# INTERNAL ENGINE OPERATIONS
# --------------------------------------------------

func _load_room(id: String) -> void:
	var pos_v3: Vector3 = layout.get(id, Vector3.ZERO)
	var depth_axis = pos_v3.z if pos_v3.z != 0.0 else pos_v3.y
	
	var def: RoomDefinition = graph.nodes[id]
	
	var grid_pos := Vector2i(
		roundi(pos_v3.x / room_scene_size),
		roundi(depth_axis / room_scene_size)
	)
	
	var room := room_spawner.spawn_room(
		id,
		def,
		grid_pos,
		pos_v3
	)
	
	if id == "start":
		start_room_instance = room
	
	loaded_rooms[id] = room
	
	room_loaded.emit(room)


func _unload_room(id: String) -> void:
	if not loaded_rooms.has(id):
		return
	
	var room: RoomInstance = loaded_rooms[id]
	
	room_unloaded.emit(room)
	
	room_spawner.despawn_room(id)
	
	loaded_rooms.erase(id)


# --------------------------------------------------
# CLEANUP
# --------------------------------------------------

func clear() -> void:
	for id in loaded_rooms.keys().duplicate():
		_unload_room(id)
	
	loaded_rooms.clear()
	
	layout.clear()
	
	graph = null
	
	current_room = null
	start_room_instance = null
	
	visited_rooms.clear()


# --------------------------------------------------
# HELPERS
# --------------------------------------------------

func get_start_room_instance() -> RoomInstance:
	return start_room_instance
