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
var current_room_id := ""
var last_room_id := ""

var visited_rooms := {} # String -> bool

var start_room_instance: RoomInstance

# --------------------------------------------------
# INIT PIPELINE
# --------------------------------------------------
func generate(_seed: int, room_pool: Array[RoomDefinition], count: int, start_room: RoomDefinition) -> void:
	var gen := DungeonGenerator.new()
	generator = gen
	
	graph = generator.generate(_seed, room_pool, count, start_room)
	layout = LayoutSolver.new().solve(graph)
	
	loaded_rooms.clear()
	current_room_id = ""
	
	_update_room_streaming("start")


func _ready() -> void:
	room_spawner = RoomSpawner.new()
	add_child(room_spawner)


# --------------------------------------------------
# UPDATE STREAM AROUND PLAYER
# --------------------------------------------------
func update_stream(player_global_pos: Vector3) -> void:
	if player_global_pos.y < -2.0:
		return
		
	var closest_room_id := _get_closest_room_id(player_global_pos)
	
	if closest_room_id != current_room_id and closest_room_id != "":
		visited_rooms[closest_room_id] = true
		current_room_id = closest_room_id
		_update_room_streaming(current_room_id)
		if loaded_rooms.has(current_room_id):
			active_room_changed.emit(loaded_rooms[current_room_id])


# --------------------------------------------------
# CORE ROOM STREAMING LOGIC
# --------------------------------------------------
func _update_room_streaming(center_room: String) -> void:
	var needed_rooms := {}
	needed_rooms[center_room] = true
	
	if load_radius > 0 and graph.connections.has(center_room):
		for connection in graph.connections[center_room]:
			needed_rooms[connection.target_id] = true
			
	# 1. Unload old rooms safely
	for id in loaded_rooms.keys().duplicate():
		if not needed_rooms.has(id):
			_unload_room(id)
			
	# 2. Load incoming rooms
	var physics_changed := false
	for id in needed_rooms.keys():
		if not loaded_rooms.has(id):
			_load_room(id)
			physics_changed = true
			
	# 3. Synchronize entry thresholds
	if physics_changed:
		connector.connect_room(graph, layout, loaded_rooms)


# --------------------------------------------------
# INTERNAL ENGINE OPERATIONS
# --------------------------------------------------
func _load_room(id: String) -> void:
	var pos_v3: Vector3 = layout.get(id, Vector3.ZERO)
	var def: RoomDefinition = graph.nodes[id]
	
	var grid_pos := Vector2i(
		roundi(pos_v3.x / room_scene_size),
		roundi(pos_v3.z / room_scene_size)
	)
	
	var room := room_spawner.spawn_room(id, def, grid_pos)
	
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
# GRAPH-AWARE MATCH CHECKING
# --------------------------------------------------
func _get_closest_room_id(world_pos: Vector3) -> String:
	# Fallback initialization to the start node
	if current_room_id == "":
		current_room_id = "start"
		
	var closest_id := current_room_id
	var closest_dist := world_pos.distance_to(layout.get(current_room_id, Vector3.ZERO)) - 5.0
	
	# ONLY check the current room's direct structural graph neighbors
	if graph.connections.has(current_room_id):
		for connection in graph.connections[current_room_id]:
			var n_id = connection.target_id
			if not layout.has(n_id): 
				continue
				
			var dist := world_pos.distance_to(layout[n_id])
			if dist < closest_dist:
				closest_dist = dist
				closest_id = n_id
	
	# Snug collision bounds limit checks to half the scene dimension width
	var max_allowed_distance := room_scene_size * 0.75
	return closest_id if closest_dist < max_allowed_distance else current_room_id


func clear() -> void:
	for id in loaded_rooms.keys().duplicate():
		_unload_room(id)
	loaded_rooms.clear()
	layout.clear()
	graph = null
	current_room_id = ""


func get_start_room_instance() -> RoomInstance:
	return start_room_instance
