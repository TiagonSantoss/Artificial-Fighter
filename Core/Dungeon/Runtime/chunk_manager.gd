class_name ChunkManager
extends Node3D

@export var room_scene_size := 40.0
@export var load_radius := 1

signal room_loaded(room: RoomInstance)
signal room_unloaded(room: RoomInstance)
signal active_room_changed(room_instance: RoomInstance)

enum StreamingMode {
	EXPLORATION,
	COMBAT
}

var streaming_mode := StreamingMode.EXPLORATION

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

var active_room: RoomRuntime


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
	var rooms_to_load: Array[String] = _get_rooms_in_radius(
		current_room_id,
		_get_radius()
	)
	
	# Unload anything not in the list
	for id in loaded_rooms.keys().duplicate():
		if not id in rooms_to_load:
			_unload_room(id)
	
	# Load anything missing
	for id in rooms_to_load:
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
	
	var room := room_spawner.spawn_room(id, def, grid_pos, pos_v3)
	
	if id == "start":
		start_room_instance = room
	
	loaded_rooms[id] = room
	
	# Wire up room detection to chunk manager
	var runtime := room.node.find_child("RoomRuntime", true, false) as RoomRuntime
	if runtime:
		runtime.room_instance = room
		if not runtime.player_entered.is_connected(set_current_room):
			runtime.player_entered.connect(set_current_room)
	
	room_loaded.emit(room)

func _unload_room(id: String) -> void:
	if not loaded_rooms.has(id):
		return
	
	var room: RoomInstance = loaded_rooms[id]
	
	room_unloaded.emit(room)
	
	room_spawner.despawn_room(id)
	
	loaded_rooms.erase(id)

func _get_rooms_in_radius(start_id: String, radius: int) -> Array[String]:
	var result: Array[String] = []
	var visited := {}
	var queue: Array = [[start_id, 0]]
	
	while queue.size() > 0:
		var item = queue.pop_front()
		var id: String = item[0]
		var depth: int = item[1]
		
		if visited.has(id):
			continue
		
		visited[id] = true
		result.append(id)
		
		if depth >= radius:
			continue
		
		if graph.nodes.has(id):
			for neighbor in graph.get_neighbors(id):
				queue.append([neighbor, depth + 1])
	
	return result

func _get_radius() -> int:
	match streaming_mode:
		StreamingMode.COMBAT:
			return 0
		StreamingMode.EXPLORATION:
			return load_radius
	return load_radius

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

func set_active_room(room: RoomRuntime):
	if active_room == room:
		return
	
	active_room = room
	
	for r in get_tree().get_nodes_in_group("rooms"):
		r.set_active(r == room)

func set_streaming_mode(mode: StreamingMode, room_id: String = "") -> void:
	streaming_mode = mode
	if room_id != "":
		_update_room_streaming(room_id)
