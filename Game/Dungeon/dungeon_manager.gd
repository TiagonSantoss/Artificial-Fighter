class_name DungeonManager
extends Node

enum RoomType {
	START,
	COMBAT,
	TREASURE,
	SHOP,
	BOSS
}
@export var room_renderer: RoomRenderer

var current_room: DungeonRoom = null
var active_encounter_room: DungeonRoom = null

func _ready():
	room_renderer.room_entered.connect(_on_room_entered)
	room_renderer.room_exited.connect(_on_room_exited)
	
	call_deferred("spawn_player")

func _on_room_entered(room: DungeonRoom) -> void:
	enter_room(room)

func _on_room_exited(room: DungeonRoom) -> void:
	if room == null:
		return
	
	# only care if we are exiting the active encounter room
	if active_encounter_room == room:
		print("Exited encounter room:", room)
	
	# optional: you can decide behavior here
	# (usually you DON'T stop encounters just because player left radius)

func _on_enemy_died(room: DungeonRoom, enemy: Entity) -> void:
	if not is_instance_valid(room):
		return
	
	room.enemies.erase(enemy)
	
	if room.enemies.is_empty():
		finish_encounter(room)

func enter_room(room: DungeonRoom) -> void:
	if room == null:
		return
	
	if current_room == room:
		return
	
	current_room = room
	
	print("Entered room:", room)
	print("HAS ENCOUNTER:", room.has_encounter)
	
	# ignore non-combat rooms
	if not room.has_encounter:
		return
	
	# already done
	if room.cleared:
		return
	
	# already running encounter here
	if active_encounter_room == room:
		return
	
	start_encounter(room)

func start_encounter(room: DungeonRoom):
	room.spawned = true
	active_encounter_room = room
	lock_room(room)
	room.enemies.clear()
	
	for pos in room.enemy_spawns:
		var world_pos := Vector3(
			room.node.global_position.x,
			0,
			room.node.global_position.z
		)
		
		print("Spawning enemy at:", world_pos, " (grid pos:", pos, ")")
		var enemy = Game.instance.spawn_enemy(world_pos)
		room.enemies.append(enemy)
		enemy.tree_exited.connect(_on_enemy_died.bind(room, enemy))

func on_enemy_removed(room: DungeonRoom, enemy: Entity) -> void:
	room.enemies.erase(enemy)
	
	if room.enemies.is_empty():
		finish_encounter(room)

func finish_encounter(room: DungeonRoom) -> void:
	print("Encounter finished")
	
	room.cleared = true
	
	if active_encounter_room == room:
		active_encounter_room = null
	
	unlock_room(room)

func spawn_player():
	if room_renderer.rooms.is_empty():
		push_error("No rooms generated")
		return
	
	var start_room: DungeonRoom = room_renderer.rooms[0]
	
	if start_room.player_spawns.is_empty():
		push_error("No player spawn found")
		return
	
	var pos = start_room.player_spawns[0]
	
	var spawn_pos := Vector3(
		start_room.node.global_position.x + pos.x,
		0,
		start_room.node.global_position.z + pos.z
	)
	
	print("Player spawning at:", spawn_pos)
	Game.instance.spawn_player(spawn_pos)
	spawn_starting_companions(spawn_pos)

func spawn_starting_companions(spawn_pos: Vector3):
	var offsets := [
		Vector3(1, 0, 0),
		Vector3(-1, 0, 0),
		Vector3(0, 0, 1),
		Vector3(0, 0, -1)
	]
	
	var count = min(Game.instance.companion_pool.size(), offsets.size())
	
	for i in range(count):
		Game.instance.spawn_companion(
			spawn_pos + offsets[i],
			Game.instance.companion_pool[i]
		)

func lock_room(room: DungeonRoom) -> void:
	# implement door blocking here
	pass

func unlock_room(room: DungeonRoom) -> void:
	pass
