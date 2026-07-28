class_name Game
extends Node3D

const ENTITY_SCENE = preload("res://Core/Entities/Entity.tscn")

const LAYER_WORLD := 1
const LAYER_ENTITY := 3

signal controlled_entity_changed(entity: Entity)

var _controlled_entity: Entity
var controlled_entity: Entity:
	get:
		return _controlled_entity
	set(value):
		_controlled_entity = value
		GState.controlled_entity_changed.emit(controlled_entity)

static var player: Entity
static var instance: Game

var entity_camera_pivot: Marker3D
var active_room_pivot: DynamicRotatingCameraPivot = null

@onready var entities: Node3D = $Entities
@onready var player_spawn: Marker3D = $PlayerSpawn

@onready var camera_rig: Camera3D = $Camera3D

@export var player_definition: EntityDefinition

@export var enemy_pool: Array[EntityDefinition]
@export var npc_pool: Array[EntityDefinition]
@export var companion_pool: Array[EntityDefinition]
@export var chunk_manager: ChunkManager

@onready var marker = $PlayerSpawn


func _ready() -> void:
	instance = self
	call_deferred("_init_camera")
	if chunk_manager:
		chunk_manager.active_room_changed.connect(_on_active_room_changed)


func _process(_delta: float) -> void:
	if not is_instance_valid(camera_rig):
		return


func _on_active_room_changed(room_data: Variant) -> void:
	if room_data == null or not is_instance_valid(camera_rig):
		return

	var physical_room_node: Node3D = null
	var room_def: RoomDefinition = null

	if room_data is RoomInstance:
		physical_room_node = room_data.node
		room_def = room_data.definition
	elif "node" in room_data:
		physical_room_node = room_data.node
		if "definition" in room_data:
			room_def = room_data.definition

	if not is_instance_valid(physical_room_node):
		return

	var new_pivot := (
		physical_room_node.find_child("CameraPivot", true, false) as DynamicRotatingCameraPivot
	)

	if not is_instance_valid(new_pivot):
		return

	if is_instance_valid(active_room_pivot):
		new_pivot.rotation.y = active_room_pivot.rotation.y
		new_pivot.target_rotation_y = active_room_pivot.target_rotation_y
		new_pivot.is_rotating = active_room_pivot.is_rotating
		active_room_pivot.deactivate()

	active_room_pivot = new_pivot

	var target_size := Vector2(40.0, 40.0)
	if room_def:
		target_size = Vector2(room_def.size) * 40.0

	active_room_pivot.set_room(room_data)
	active_room_pivot.activate(target_size)


func _init_camera() -> void:
	if is_instance_valid(camera_rig) and is_instance_valid(player_spawn):
		camera_rig.global_position = player_spawn.global_position


func flash_screen_overlay(color: Color, duration: float) -> void:
	# 1. Create a top-level CanvasLayer so it covers the whole screen
	var canvas_layer := CanvasLayer.new()
	canvas_layer.layer = 100  # Render on top of all HUD/UI elements
	add_child(canvas_layer)

	# 2. Create the full-screen color tint
	var overlay := ColorRect.new()
	overlay.color = color
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Don't block gameplay input
	canvas_layer.add_child(overlay)

	# 3. Tween the overlay alpha from initial color down to completely invisible
	var tween := create_tween()
	tween.tween_property(overlay, "color:a", 0.0, duration)

	# 4. Clean up nodes when the animation completes
	tween.finished.connect(canvas_layer.queue_free)


func rotate_by(degrees: float) -> void:
	if is_instance_valid(active_room_pivot):
		active_room_pivot.rotate_by(degrees)


func get_camera_forward() -> Vector3:
	if not is_instance_valid(active_room_pivot):
		return Vector3(0, 0, -1)
	return Vector3(0, 0, -1).rotated(Vector3.UP, active_room_pivot.rotation.y)


func get_camera_right() -> Vector3:
	if not is_instance_valid(active_room_pivot):
		return Vector3(1, 0, 0)
	return Vector3(1, 0, 0).rotated(Vector3.UP, active_room_pivot.rotation.y)


func spawn_player(pos: Vector3) -> Entity:
	player = spawn_entity(player_definition, pos)
	controlled_entity = player
	player.add_to_group("player")
	return player


func spawn_enemy(pos: Vector3, definition: EntityDefinition = null) -> Entity:
	if definition == null:
		definition = enemy_pool.pick_random()

	var enemy := spawn_entity(definition, pos)
	enemy.controller.target = player
	enemy.add_to_group("enemies")

	enemy.collision_layer = 2
	return enemy


func spawn_companion(pos: Vector3, definition: EntityDefinition) -> Entity:
	var companion := spawn_entity(definition, pos)
	companion.controller.follow_target = player
	return companion


func spawn_npc(pos: Vector3, definition: EntityDefinition) -> Entity:
	return spawn_entity(definition, pos)


func spawn_entity(definition: EntityDefinition, pos: Vector3) -> Entity:
	var entity: Entity = ENTITY_SCENE.instantiate()
	entities.add_child(entity)
	entity.setup(pos, definition)
	configure_entity_collision(entity)
	return entity


func configure_entity_collision(entity: Entity) -> void:
	entity.collision_layer = LAYER_ENTITY
	entity.collision_mask = LAYER_WORLD
