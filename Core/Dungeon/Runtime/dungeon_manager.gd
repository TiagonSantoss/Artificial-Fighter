class_name DungeonManager
extends Node3D

@export var room_pool: Array[RoomDefinition]
@export var start_room: RoomDefinition
@export var _seed := 1234
@export var room_count := 12

@onready var chunk_manager: ChunkManager = $ChunkManager

var graph: RoomGraph
var layout: Dictionary = {}

var current_room: RoomInstance
var previous_room: RoomInstance
var is_generating := false

signal room_entered(room: RoomInstance)
signal room_exited(room: RoomInstance)


func generate() -> void:
	if is_generating:
		print("GENERATION BLOCKED (already running)")
		return
	
	is_generating = true
	
	print_stack()
	chunk_manager.clear()
	clear()
	
	chunk_manager.generate(
		_seed,
		room_pool,
		room_count,
		start_room
	)
	
	graph = chunk_manager.graph
	layout = chunk_manager.layout
	
	_spawn_player_at_start()
	
	is_generating = false

func _ready() -> void:
	await get_tree().process_frame
	chunk_manager.room_loaded.connect(_on_room_loaded)
	chunk_manager.room_unloaded.connect(_on_room_unloaded)
	
	generate()

func _process(_delta: float) -> void:
	if Game.player == null:
		return
	
	chunk_manager.update_stream(
		Game.player.global_position
	)

func _on_room_loaded(room: RoomInstance) -> void:
	register_room(room)

func _on_room_unloaded(room: RoomInstance) -> void:
	if current_room == room:
		current_room = null

func _on_room_entered(room: RoomInstance) -> void:
	if room == null:
		return
	
	if room.cleared:
		return
	
	if not room.has_encounter:
		return
	
	print("Starting encounter in:", room.room_id)
	
	# TODO:
	# Spawn enemies
	# Lock doors
	# Play music

func _on_player_entered_room(
	room: RoomInstance
) -> void:
	if current_room == room:
		return
	
	if current_room:
		room_exited.emit(current_room)
	
	previous_room = current_room
	current_room = room
	
	room_entered.emit(room)
	
	print("Entered:", room.room_id)
	
	_on_room_entered(room)

func _on_player_exited_room(
	room: RoomInstance
) -> void:
	if current_room != room:
		return
	
	print("Exited:", room.room_id)

func _spawn_player_at_start() -> void:
	if Game.instance == null:
		push_error("Game.instance not ready yet")
		return
	var chunk_manager_a := get_node("./ChunkManager")
	
	var start_room_a = chunk_manager_a.loaded_rooms.get("start")
	
	if start_room_a == null:
		push_error("Start room not loaded yet")
		return
	
	var room_node: Node3D = start_room_a.node
	var spawn_point := room_node.find_child("SpawnPoint", true, false)
	
	if spawn_point == null:
		push_error("SpawnPoint not found in start room")
		return
	
	Game.instance.spawn_player(spawn_point.global_position)
	#await get_tree().create_timer(2.0).timeout
	#chunk_manager.update_stream(Game.player.global_position)

func register_room(room: RoomInstance) -> void:
	var runtime := room.node.find_child(
		"RoomRuntime",
		true,
		false
	) as RoomRuntime
	
	if runtime == null:
		return
	
	if not runtime.player_entered.is_connected(_on_player_entered_room):
		runtime.player_entered.connect(
			_on_player_entered_room
		)
	
	if not runtime.player_exited.is_connected(_on_player_exited_room):
		runtime.player_exited.connect(
			_on_player_exited_room
		)

func clear() -> void:
	current_room = null
	
	graph = null
	
	layout.clear()
	
	if chunk_manager:
		chunk_manager.clear()
	
	#room_cleared.emit() NEED ROOM
