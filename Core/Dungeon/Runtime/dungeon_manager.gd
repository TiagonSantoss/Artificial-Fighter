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

@export_category("Special Doors")
@export var bonus_room_pool: Array[RoomDefinition]
@export var special_door_min_rank := 5
@export var special_door_rank_bonus := 25.0

@export var boss_room_pool: Array[RoomDefinition]
@export var boss_room: RoomDefinition  # fallback, used only if the pool is empty

var _last_boss_room: RoomDefinition

var _advancing := false
var floor_number := 1

var emitter: FmodEventEmitter3D

var graph: RoomGraph
var layout: Dictionary = {}

var current_room: RoomInstance
var previous_room: RoomInstance
var is_generating := false

@onready var chunk_manager: ChunkManager = $ChunkManager


func generate(keep_party := false) -> void:
	if is_generating:
		print("GENERATION BLOCKED (already running)")
		return

	is_generating = true

	# Advancing a floor always needs a new seed, even if generate_random_seed is off
	if generate_random_seed or keep_party:
		randomize()
		_seed = randi()

	print("DungeonManager generating layout with seed: ", _seed)
	GameAutoLoad.floors_reached = floor_number

	seed(_seed)
	GState.seed_changed.emit(_seed)

	chunk_manager.clear()
	clear()

	var chosen_boss := _pick_boss_room()
	chunk_manager.generate(_seed, room_pool, room_count, start_room, chosen_boss)
	graph = chunk_manager.graph
	layout = chunk_manager.layout

	chunk_manager._load_room("start")
	_spawn_player_at_start(keep_party)
	MusicDirector.set_mood(MusicDirector.Mood.EXPLORE)

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


func _spawn_player_at_start(keep_party := false) -> void:
	if GameAutoLoad == null:
		return

	var start_room_a: RoomInstance = chunk_manager.loaded_rooms.get("start")
	if start_room_a == null:
		return

	var spawn_point := start_room_a.node.find_child("SpawnPoint", true, false)
	var spawn_pos = spawn_point.global_position if spawn_point else Vector3.ZERO

	if keep_party:
		# Bring back whoever died during the floor, then move everyone who's alive
		GameAutoLoad.revive_missing_characters(spawn_pos)

		var offset := 0.0
		for entity in GameAutoLoad.get_living_characters():
			_move_entity(entity, spawn_pos + Vector3(offset, 0.0, 0.0))
			offset += 1.5
		return
	GameAutoLoad.spawn_player(spawn_pos)
	GameAutoLoad.spawn_companion(spawn_pos)


func _move_entity(entity, pos: Vector3) -> void:
	if not is_instance_valid(entity):
		return
	entity.global_position = pos
	entity.velocity = Vector3.ZERO


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


func _update_boss_bar(room: RoomInstance) -> void:
	var bosses: Array = []
	for e in room.enemies:
		if is_instance_valid(e) and not e.is_queued_for_deletion():
			if e.definition != null and e.definition.is_boss:
				bosses.append(e)
	GState.boss_fight_changed.emit(bosses)


func _spawn_enemy_for_room(room: RoomInstance, definition: EntityDefinition) -> void:
	var marker := room.get_random_spawn(definition.get_spawn_group_name())

	if marker == null:
		push_warning("No spawn found for %s" % definition.spawn_group)
		return

	var enemy := GameAutoLoad.spawn_enemy(marker.global_position, definition)
	room.enemies.append(enemy)

	enemy.tree_exited.connect(
		func():
			if _advancing or GameAutoLoad.is_restarting:
				return

			if _advancing:
				return  # being cleaned up by a floor change, not killed

			room.enemies.erase(enemy)

			if room.cleared:
				return  # already cleared, e.g. leftover minions dying afterwards

			if definition.is_boss:
				_update_boss_bar(room)

			if definition.is_boss:
				# Only clear once the last boss is gone
				if not _boss_alive_in(room):
					_on_boss_defeated(room)
			elif room.enemies.is_empty():
				_on_room_cleared(room)
	)


func _on_boss_defeated(room: RoomInstance) -> void:
	room.cleared = true
	advance_floor()


func _pick_boss_room() -> RoomDefinition:
	if boss_room_pool.is_empty():
		return boss_room

	var candidates := boss_room_pool.duplicate()

	# Avoid repeating the previous floor's boss when there's another option
	if candidates.size() > 1 and _last_boss_room != null:
		candidates.erase(_last_boss_room)

	# Own RNG seeded from the dungeon seed: same seed = same boss,
	# and the global seed() sequence (so the room layout) is unaffected
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%s_boss" % _seed)

	_last_boss_room = candidates[rng.randi_range(0, candidates.size() - 1)]
	return _last_boss_room


func _boss_alive_in(room: RoomInstance) -> bool:
	for e in room.enemies:
		if is_instance_valid(e) and e.definition != null and e.definition.is_boss:
			return true
	return false


func advance_floor() -> void:
	if _advancing or is_generating:
		return
	_advancing = true

	await get_tree().create_timer(1.5).timeout  # let the kill land

	SceneManager.play_cutscene(preload("res://assets/elevador.ogv"))

	var fader := GameAutoLoad.get_node_or_null("ScreenFader")
	if fader:
		await fader.fade_to_black()

	# Boss minions or leftovers shouldn't follow you to the next floor
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(enemy):
			enemy.queue_free()

	floor_number += 1
	generate(true)

	FmodServer.play_one_shot("event:/SFX/UI/DoorOpen")
	SceneManager.cover_screen()
	await SceneManager.reveal_screen()

	_advancing = false


func start_encounter(room: RoomInstance) -> void:
	if room == null or room.encounter_started or not room.definition.has_encounter:
		return

	seed(hash(str(_seed) + room.room_id))

	var encounter := room.definition.get_random_encounter()

	if encounter == null:
		return

	room.encounter_started = true

	MusicDirector.set_mood(MusicDirector.Mood.COMBAT)

	for enemy_def in encounter.possible_enemies:
		if enemy_def.intro_cutscene != null:
			await SceneManager.play_cutscene(enemy_def.intro_cutscene)
			break

	if encounter.possible_enemies.size() > 0:
		for i in range(encounter.spawn_count):
			var random_enemy_def = encounter.possible_enemies.pick_random()
			_spawn_enemy_for_room(room, random_enemy_def)


func _on_room_cleared(room: RoomInstance) -> void:
	if not is_inside_tree():
		return

	room.cleared = true

	await get_tree().create_timer(1.2).timeout
	_try_open_special_door(room)
	room.unlock_room()

	if is_instance_valid(room.node):
		var scene_doors = room.node.find_children("*", "SceneTransitionDoor", true, false)
		for door in scene_doors:
			if door.has_method("unlock"):
				door.unlock()

	MusicDirector.set_mood(MusicDirector.Mood.EXPLORE)

	await get_tree().create_timer(1.2).timeout
	if _advancing or chunk_manager.loaded_rooms.get(room.room_id) != room:
		return
	room.unlock_room()


func _try_open_special_door(room: RoomInstance) -> void:
	if bonus_room_pool.is_empty():
		return
	if chunk_manager.loaded_rooms.get(room.room_id) != room:
		return  # room was unloaded during the wait
	if chunk_manager.special_links.has(room.room_id):
		return

	var base: float = room.definition.special_door_chance
	if base <= 0.0:
		return

	var rank := _get_player_rank()
	if rank < special_door_min_rank:
		return

	var chance := clampf(base + (rank - special_door_min_rank) * special_door_rank_bonus, 0.0, 1.0)

	# Deterministic per seed + room, so it doesn't mess with your global RNG
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%s_%s_special" % [_seed, room.room_id])

	#if rng.randf() > chance:
	#	print("DANG IT")
	#	return

	print("SPAWNING SPECIAL ROOM")

	var bonus_def := bonus_room_pool[rng.randi_range(0, bonus_room_pool.size() - 1)]
	chunk_manager.create_special_link(room, bonus_def)


func _get_player_rank() -> int:
	var player = GameAutoLoad.get_current_entity()
	if player and player.rank_component:
		return player.rank_component.current_rank
	return 0
