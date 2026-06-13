class_name RoomSpawner
extends Node3D

@export var room_scene_size := 40.0

var instances: Dictionary = {} # room_id -> RoomInstance

# --------------------------------------------------
# SPAWN ONE ROOM
# --------------------------------------------------
func spawn_room(
	room_id: String,
	definition: RoomDefinition,
	layout_pos: Vector2i
) -> RoomInstance:
	if instances.has(room_id):
		return instances[room_id]
	
	var room := RoomInstance.new()
	
	room.room_id = room_id
	room.definition = definition
	room.layout_position = layout_pos
	
	room.node = definition.scene.instantiate()
	
	add_child(room.node)
	
	var runtime := room.node.find_child(
		"RoomRuntime",
		true,
		false
	) as RoomRuntime
	
	if runtime:
		runtime.room_instance = room
	
	room.node.global_position = Vector3(
		layout_pos.x * room_scene_size,
		0.0,
		layout_pos.y * room_scene_size
	)
	
	room.world_origin = room.node.global_position
	room.spawned = true
	
	instances[room_id] = room
	
	return room

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
