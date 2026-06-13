class_name ChunkManager
extends Node3D

@export var chunk_size := 2
@export var room_scene_size := 40.0
@export var load_radius := 1

signal room_loaded(room: RoomInstance)
signal room_unloaded(room: RoomInstance)

var active_chunks := {}     # Vector2i -> {room_id -> instance}
var loaded_rooms := {}      # room_id -> instance

var graph: RoomGraph
var layout: Dictionary

var generator: DungeonGenerator
var layout_solver: LayoutSolver

var connector := RoomConnector.new()
var room_spawner: RoomSpawner

var chunk_index := {}

# --------------------------------------------------
# INIT PIPELINE
# --------------------------------------------------
func generate(_seed: int, room_pool: Array[RoomDefinition], count: int, start_room: RoomDefinition) -> void:
	var gen := DungeonGenerator.new()
	generator = gen
	
	graph = generator.generate(_seed, room_pool, count, start_room)
	layout = LayoutSolver.new().solve(graph)
	
	_build_chunk_index()
	_update_streaming(Vector2i.ZERO)

func _ready() -> void:
	room_spawner = RoomSpawner.new()
	add_child(room_spawner)

# --------------------------------------------------
# UPDATE STREAM AROUND PLAYER
# --------------------------------------------------
func update_stream(player_global_pos: Vector3) -> void:
	var current_chunk := world_to_chunk(player_global_pos)
	_update_streaming(current_chunk)

# --------------------------------------------------
# CORE STREAMING LOGIC
# --------------------------------------------------
func _update_streaming(center_chunk: Vector2i) -> void:
	var needed := {}
	var chunk_was_loaded := false
	
	# 1. Determine chunks to keep
	for x in range(-load_radius, load_radius + 1):
		for y in range(-load_radius, load_radius + 1):
			var chunk := center_chunk + Vector2i(x, y)
			needed[chunk] = true
	
	# 2. Unload old chunks
	for chunk in active_chunks.keys():
		if not needed.has(chunk):
			_unload_chunk(chunk)
	
	# 3. Load new chunks
	for chunk in needed.keys():
		if not active_chunks.has(chunk):
			_load_chunk(chunk)
			chunk_was_loaded = true
			
	# 4. If a chunk was introduced, safely bind sockets once
	if chunk_was_loaded:
		_connect_chunk()

# --------------------------------------------------
# LOAD CHUNK
# --------------------------------------------------
func _load_chunk(chunk: Vector2i) -> Dictionary:
	var chunk_rooms := {}
	var room_ids: Array = chunk_index.get(chunk, [])
	
	for id in room_ids:
		if loaded_rooms.has(id):
			continue
		
		var pos_v3: Vector3 = layout.get(id)
		var def: RoomDefinition = graph.nodes[id]
		
		# Convert the physical 3D position back to an integer grid coordinate for RoomSpawner
		var grid_pos := Vector2i(
			roundi(pos_v3.x / room_scene_size),
			roundi(pos_v3.z / room_scene_size)
		)
		
		var room := room_spawner.spawn_room(
			id,
			def,
			grid_pos # Passed as Vector2i to satisfy spawn_room()
		)
		
		room_loaded.emit(room)
		
		chunk_rooms[id] = room
		loaded_rooms[id] = room
		
	active_chunks[chunk] = chunk_rooms
	return chunk_rooms

# --------------------------------------------------
# BUILD CHUNK INDEX
# --------------------------------------------------
func _build_chunk_index() -> void:
	chunk_index.clear()
	
	for room_id in layout.keys():
		var chunk := world_to_chunk_pos(layout[room_id])
		
		if not chunk_index.has(chunk):
			chunk_index[chunk] = []
		
		chunk_index[chunk].append(room_id)

# --------------------------------------------------
# UNLOAD CHUNK
# --------------------------------------------------
func _unload_chunk(chunk: Vector2i) -> void:
	if not active_chunks.has(chunk):
		return
	
	for id in active_chunks[chunk].keys():
		var room: RoomInstance = active_chunks[chunk][id]
		
		room_unloaded.emit(room)
		room_spawner.despawn_room(id)
		loaded_rooms.erase(id)

	active_chunks.erase(chunk)

# --------------------------------------------------
# CONNECT CHUNK
# --------------------------------------------------
func _connect_chunk() -> void:
	connector.connect_room(graph, layout, loaded_rooms)

# --------------------------------------------------
# WORLD ↔ CHUNK CONVERSION
# --------------------------------------------------
func world_to_chunk(world: Vector3) -> Vector2i:
	return Vector2i(
		floor(world.x / (chunk_size * room_scene_size)),
		floor(world.z / (chunk_size * room_scene_size))
	)

## Fixed: Takes the computed Vector3 position data and translates it to chunk grids
func world_to_chunk_pos(room_pos: Vector3) -> Vector2i:
	return Vector2i(
		floor(room_pos.x / (chunk_size * room_scene_size)),
		floor(room_pos.z / (chunk_size * room_scene_size))
	)

func clear() -> void:
	for chunk in active_chunks.keys():
		_unload_chunk(chunk)
	
	active_chunks.clear()
	loaded_rooms.clear()
	chunk_index.clear()
	
	graph = null
	layout.clear()
