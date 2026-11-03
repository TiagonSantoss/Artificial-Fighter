class_name RoomSpawner
extends Node3D

@export var room_scene_size := 40.0

var instances: Dictionary = {}


func spawn_room(
	room_id: String, variant: RoomVariant, layout_pos: Vector2i, world_pos: Vector3  # CHANGED
) -> RoomInstance:
	if instances.has(room_id):
		return instances[room_id]

	var definition := variant.definition  # NEW

	var room := RoomInstance.new()

	room.room_id = room_id
	room.definition = definition
	room.variant = variant  # NEW
	room.rotation_steps = variant.rotation_steps  # NEW
	room.layout_position = layout_pos

	room.node = definition.scene.instantiate()

	_scan_spawn_groups(room)

	add_child(room.node)

	room.node.rotation.y = -variant.rotation_steps * PI / 2.0

	var runtime := room.node.find_child("RoomRuntime", true, false) as RoomRuntime

	if runtime:
		runtime.room_instance = room
		_cache_spawn_groups(room)

	room.node.global_position = world_pos

	room.world_origin = room.node.global_position
	room.spawned = true

	instances[room_id] = room

	return room


func _scan_spawn_groups(room: RoomInstance) -> void:
	var root := room.node.find_child("SpawnGroups", true, false)

	if root == null:
		return

	for group_node in root.get_children():
		var group_name := group_node.name.to_lower()

		room.spawn_groups[group_name] = []

		for child in group_node.get_children():
			if child is Marker3D:
				room.spawn_groups[group_name].append(child)


# --------------------------------------------------
# DESPAWN ONE ROOM
# --------------------------------------------------
func despawn_room(room_id: String) -> void:
	if not instances.has(room_id):
		return

	var room: RoomInstance = instances[room_id]

	if room.node and is_instance_valid(room.node):
		room.node.queue_free()

	room.spawned = false

	instances.erase(room_id)


func get_room(room_id: String) -> RoomInstance:
	return instances.get(room_id)


# --------------------------------------------------
# CLEANUP
# --------------------------------------------------
func clear() -> void:
	for room: RoomInstance in instances.values():
		if room.node and is_instance_valid(room.node):
			room.node.queue_free()

	instances.clear()


func _cache_spawn_groups(room: RoomInstance) -> void:
	var root := room.node.find_child("EnemySpawns", true, false)

	if root == null:
		return

	for group_node in root.get_children():
		var markers: Array[Marker3D] = []

		for child in group_node.get_children():
			if child is Marker3D:
				markers.append(child)

		room.spawn_groups[group_node.name.to_lower()] = markers
