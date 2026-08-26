class_name RoomInstance
extends RefCounted

var room_id: String
var definition: RoomDefinition

var layout_position: Vector2i
var world_origin: Vector3

var node: Node3D

# Runtime
var spawned := false
var cleared := false
var encounter_started := false
var encounter_enabled := true

# Spawn points
var player_spawns: Array[Marker3D] = []

# Group name -> Array[Marker3D]
var spawn_groups: Dictionary = {}

# Active enemies
var enemies: Array[Entity] = []

var barrier_root: ArenaBarrierRoot = null


func get_spawn_group(group_name: String) -> Array:
	return spawn_groups.get(group_name.to_lower(), [])


func get_random_spawn(group_name: String) -> Marker3D:
	var group := get_spawn_group(group_name)

	if group.is_empty():
		return null

	return group.pick_random()


func get_random_spawn_for_group(group: EntityDefinition.SpawnGroup) -> Marker3D:
	var name = EntityDefinition.SpawnGroup.keys()[group].to_lower()

	return get_random_spawn(name)


func lock_room() -> void:
	if definition.has_encounter:
		if barrier_root:
			barrier_root.set_locked(true)


func unlock_room() -> void:
	if barrier_root:
		barrier_root.set_locked(false)
