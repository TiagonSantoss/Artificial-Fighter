class_name DungeonManager
extends Node3D

signal room_entered(room: RoomInstance)
signal room_exited(room: RoomInstance)

@export_category("Room Generation")
@export var room_pool: Array[RoomDefinition]
@export var start_room: RoomDefinition
@export var generate_random_seed: bool = true
@export var _seed := 1234
@export var room_count := 12

@export_category("Item Drop")
@export var item_pool: Array[ItemDefinition]

var emitter: FmodEventEmitter3D

var graph: RoomGraph
var layout: Dictionary = {}

var current_room: RoomInstance
var previous_room: RoomInstance
var is_generating := false

@onready var chunk_manager: ChunkManager = $ChunkManager


func generate() -> void:
	if is_generating:
		print("GENERATION BLOCKED (already running)")
		return

	is_generating = true

	if generate_random_seed:
		randomize()
		_seed = randi()

	print("DungeonManager generating layout with seed: ", _seed)

	seed(_seed)
	GState.seed_changed.emit(_seed)

	chunk_manager.clear()
	clear()

	# 1. Generate the logical layout
	chunk_manager.generate(_seed, room_pool, room_count, start_room)
	graph = chunk_manager.graph
	layout = chunk_manager.layout

	# ---> THE STARTUP FIX <---
	# 2. Physically load the start room into the scene first
	chunk_manager._load_room("start")

	# 3. Now that the room exists, spawn the player at its SpawnPoint
	_spawn_player_at_start()
	MusicDirector.set_mood(MusicDirector.Mood.EXPLORE)

	# 4. Officially trigger the room change.
	# Because the player now exists, Game.gd will successfully hook up the camera!
	var start_instance = chunk_manager.loaded_rooms["start"]
	chunk_manager._set_current_room(start_instance)

	is_generating = false


func _ready() -> void:
	await get_tree().process_frame

	chunk_manager.active_room_changed.connect(_on_active_room_changed)
	chunk_manager.room_loaded.connect(_on_room_loaded)

	if is_instance_valid(GameAutoLoad):
		emitter = GameAutoLoad.emitter

	generate()


func _on_room_loaded(room: RoomInstance) -> void:
	print("ROOM LOADED:", room.room_id)
	register_room(room)


func _on_active_room_changed(room: RoomInstance) -> void:
	if current_room:
		room_exited.emit(current_room)
		print("Exited:", current_room.room_id)

	previous_room = current_room
	current_room = room

	room_entered.emit(room)
	print("Entered:", room.room_id)

	if not room.cleared and room.encounter_enabled:
		room.lock_room()
		await get_tree().create_timer(1.3).timeout
		start_encounter(room)

	if room.encounter_started and not room.cleared:
		MusicDirector.set_mood(MusicDirector.Mood.COMBAT)
	else:
		MusicDirector.set_mood(MusicDirector.Mood.EXPLORE)

	print("whats playing right now:", MusicDirector.current_value)


func _spawn_player_at_start() -> void:
	if GameAutoLoad == null:
		return

	var start_room_a: RoomInstance = chunk_manager.loaded_rooms.get("start")
	if start_room_a == null:
		return

	var spawn_point := start_room_a.node.find_child("SpawnPoint", true, false)
	var spawn_pos = spawn_point.global_position if spawn_point else Vector3.ZERO

	GameAutoLoad.spawn_player(spawn_pos)
	GameAutoLoad.spawn_companion(spawn_pos)


func register_room(room: RoomInstance) -> void:
	print("REGISTER:", room.room_id)

	var barrier := room.node.find_child("ArenaBarrierRoot", true, false)
	if barrier:
		room.barrier_root = barrier


func clear() -> void:
	current_room = null
	previous_room = null
	graph = null
	layout.clear()

	if chunk_manager:
		chunk_manager.clear()


# --------------------------------------------------
# ENEMY & ENCOUNTER
# --------------------------------------------------


func _spawn_enemy_for_room(room: RoomInstance, definition: EntityDefinition) -> void:
	var marker := room.get_random_spawn(definition.get_spawn_group_name())

	if marker == null:
		push_warning("No spawn found for %s" % definition.spawn_group)
		return

	var enemy := GameAutoLoad.spawn_enemy(marker.global_position, definition)
	room.enemies.append(enemy)

	enemy.tree_exited.connect(
		func():
			room.enemies.erase(enemy)

			if room.enemies.is_empty():
				_on_room_cleared(room)
	)


func start_encounter(room: RoomInstance) -> void:
	if room == null or room.encounter_started or not room.definition.has_encounter:
		return

	seed(hash(str(_seed) + room.room_id))

	var encounter := room.definition.get_random_encounter()

	if encounter == null:
		return

	room.encounter_started = true

	MusicDirector.set_mood(MusicDirector.Mood.COMBAT)

	if encounter.possible_enemies.size() > 0:
		for i in range(encounter.spawn_count):
			var random_enemy_def = encounter.possible_enemies.pick_random()
			_spawn_enemy_for_room(room, random_enemy_def)


func _on_room_cleared(room: RoomInstance) -> void:
	room.cleared = true


	await get_tree().create_timer(1.2).timeout
	room.unlock_room()
	print("ROOM CLEARED:", room.room_id)

	MusicDirector.set_mood(MusicDirector.Mood.EXPLORE)

	# if item_pool.size() > 0:
	# 	var random_accessory_def = item_pool.pick_random()
	# 	var new_item_instance = ItemInstance.new()
	# 	new_item_instance.definition = random_accessory_def
	#
	# 	var player = GameAutoLoad.get_current_entity()
	# 	if player and player.rank_component:
	# 		player.rank_component.finish_encounter()
	#
	# 	var drop_pos = player.position + Vector3(0.0, 2.0, 0.0) if player else room.world_origin
	# 	WorldItemSpawner.drop(new_item_instance, drop_pos)
