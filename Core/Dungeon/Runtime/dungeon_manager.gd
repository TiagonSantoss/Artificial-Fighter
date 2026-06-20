class_name DungeonManager
extends Node3D

@export_category("Room Generation")
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
	
	#print_stack()
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
	
	var start_room_instance := _spawn_player_at_start()
	
	if start_room_instance:
		current_room = start_room_instance
		chunk_manager.set_current_room(start_room_instance)
	
	is_generating = false

func _ready() -> void:
	await get_tree().process_frame
	chunk_manager.room_loaded.connect(_on_room_loaded)
	chunk_manager.room_unloaded.connect(_on_room_unloaded)
	
	generate()

func _process(_delta: float) -> void:
	if Game.player == null:
		return

func _on_room_loaded(room: RoomInstance) -> void:
	print("ROOM LOADED:", room.room_id)
	register_room(room)

func _on_room_unloaded(room: RoomInstance) -> void:
	if current_room == room:
		current_room = null

func _on_room_entered(room: RoomInstance) -> void:
	if room == null:
		return
	
	if room.cleared:
		return
	
	if not room.encounter_enabled:
		return
	
	print("Starting encounter in:", room.room_id)
	
	start_encounter(room)
	
	# TODO:
	# Lock doors
	# Play music

func _on_player_entered_room(room: RoomInstance) -> void:
	if current_room == room:
		return
	
	if current_room:
		room_exited.emit(current_room)
	
	previous_room = current_room
	current_room = room
	
	chunk_manager.set_current_room(room)
	
	room_entered.emit(room)
	
	print("Entered:", room.room_id)
	
	_on_room_entered(room)

func _on_player_exited_room(room: RoomInstance) -> void:
	if current_room != room:
		return
	
	print("Exited:", room.room_id)

func _spawn_player_at_start() -> RoomInstance:
	if Game.instance == null:
		return null
	
	var start_room_a: RoomInstance = chunk_manager.loaded_rooms.get("start")
	
	if start_room_a == null:
		return null
	
	var spawn_point := start_room_a.node.find_child(
		"SpawnPoint",
		true,
		false
	)
	
	if spawn_point == null:
		return null
	
	Game.instance.spawn_player(
		spawn_point.global_position
	)
	
	return start_room_a

# ROOM

func register_room(room: RoomInstance) -> void:
	print("REGISTER:", room.room_id)
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

# ENEMY

func _spawn_enemy_for_room(room: RoomInstance, definition: EntityDefinition) -> void:
	var marker := room.get_random_spawn(definition.get_spawn_group_name())
	
	if marker == null:
		push_warning(
			"No spawn found for %s" %
			definition.spawn_group
		)
		return
	
	var enemy := Game.instance.spawn_enemy(
		marker.global_position,
		definition
	)
	
	room.enemies.append(enemy)
	
	enemy.tree_exited.connect(
		func():
			room.enemies.erase(enemy)
		
			if room.enemies.is_empty():
				_on_room_cleared(room)
	)

func _on_room_cleared(room: RoomInstance) -> void:
	room.cleared = true
	
	print("ROOM CLEARED:", room.room_id)
	
	# unlock doors
	# give rewards
	# open next rooms

func start_encounter(room: RoomInstance) -> void:
	if room == null:
		return
	
	if room.encounter_started:
		return
	
	if not room.definition.has_encounter:
		return
	
	var encounter := room.definition.get_random_encounter()
	
	if encounter == null:
		return
	
	room.encounter_started = true
	
	for enemy_def in encounter.enemies:
		_spawn_enemy_for_room(
			room,
			enemy_def
		)
