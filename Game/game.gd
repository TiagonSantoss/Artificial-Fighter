class_name Game
extends Node3D

const ENTITY_SCENE = preload("res://Core/Entities/Entity.tscn")

const LAYER_WORLD := 1
const LAYER_ENTITY := 2

signal controlled_entity_changed(entity: Entity)

var _controlled_entity: Entity

var controlled_entity: Entity:
	get:
		return _controlled_entity
	set(value):
		_controlled_entity = value
		controlled_entity_changed.emit(value)

static var player: Entity
static var instance: Game

var entity_camera_pivot: Marker3D

@onready var entities: Node3D = $Entities
@onready var player_spawn: Marker3D = $PlayerSpawn
@onready var camera_rig: Node3D = $Camera3D

@export var player_definition: EntityDefinition

@export var enemy_pool: Array[EntityDefinition]
@export var npc_pool: Array[EntityDefinition]
@export var companion_pool: Array[EntityDefinition]
@export var chunk_manager: ChunkManager

@onready var marker = $PlayerSpawn

func _ready():
	instance = self
	if chunk_manager:
		chunk_manager.active_room_changed.connect(_on_active_room_changed)

func _on_active_room_changed(room_data: Variant) -> void:
	if room_data == null:
		return
	
	# 1. Extract the physical 3D node from your RoomInstance data container
	# Replace '.scene_node' with whatever variable name your RoomInstance uses to hold the spawned Node3D
	var physical_room_node: Node3D = null
	
	if room_data is Node3D:
		physical_room_node = room_data
	elif "scene_node" in room_data: 
		physical_room_node = room_data.scene_node
	elif "node" in room_data:
		physical_room_node = room_data.node
	
	# 2. Safety check: did we successfully find a valid 3D scene node?
	if not is_instance_valid(physical_room_node):
		push_warning("Camera could not find a physical 3D scene node for this room data!")
		return
	
	# 3. Handle the camera attachment safely inside the live 3D node
	if physical_room_node.has_node("CameraPivot"):
		var room_pivot = physical_room_node.get_node("CameraPivot")
		camera_rig.reparent(room_pivot, false)
		print("Camera successfully attached to active room: ", room_data)
	else:
		push_warning("Active room 3D scene is missing a 'CameraPivot' node!")

func spawn_enemy(pos: Vector3, definition: EntityDefinition = null) -> Entity:
	if definition == null:
		definition = enemy_pool.pick_random()
	
	var enemy := spawn_entity(
		definition,
		pos
	)
	
	enemy.controller.target = player
	enemy.add_to_group("enemies")
	return enemy

func spawn_player(pos: Vector3) -> Entity:
	player = spawn_entity(
		player_definition,
		pos
	)
	
	controlled_entity = player
	
	player.add_to_group("player")
	
	camera_rig.reparent(player.camera_pivot, false)  # false = don't keep global transform
	#camera_rig.position = Vector3.ZERO  # reset local position to be safe
	#camera_rig.rotation = Vector3.ZERO  # reset local rotation to be safe
	
	return player

func spawn_companion(pos: Vector3, definition: EntityDefinition) -> Entity:
	var companion := spawn_entity(
		definition,
		pos
	)
	
	companion.controller.follow_target = player
	return companion

func spawn_npc(pos: Vector3, definition: EntityDefinition) -> Entity:
	return spawn_entity(
		definition,
		pos
	)

func spawn_entity(definition: EntityDefinition,pos: Vector3) -> Entity:
	var entity: Entity = ENTITY_SCENE.instantiate()
	
	entities.add_child(entity)
	entity.setup(
		pos,
		definition
	)
	
	configure_entity_collision(entity)
	
	return entity

func configure_entity_collision(entity: Entity) -> void:
	entity.collision_layer = LAYER_ENTITY
	entity.collision_mask = LAYER_WORLD
