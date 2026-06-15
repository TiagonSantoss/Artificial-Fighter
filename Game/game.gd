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

# --- Camera Transition & Orbit States ---
var transition_start_pos := Vector3.ZERO
var pivot_to: Node3D = null
var transition_t := 1.0
var transitioning := false

@export_category("Camera Settings")
@export var camera_offset := Vector3(0, 40, 40)
@export var rotation_speed := 8.0

var camera_pos: Vector3 = Vector3.ZERO
var target_rotation_y := 0.0
var current_rotation_y := 0.0
# ----------------------------------------

@onready var entities: Node3D = $Entities
@onready var player_spawn: Marker3D = $PlayerSpawn
@onready var camera_rig: Node3D = $Camera3D

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


func _process(delta: float) -> void:
	if not is_instance_valid(camera_rig):
		return

	# 1. ADVANCE TRANSITION TIMER OVER TIME
	if transitioning:
		transition_t += delta * 2.5 # Controls transition speed (~0.4 seconds)
		if transition_t >= 1.0:
			transition_t = 1.0
			transitioning = false

	# 2. SMOOTHLY INTERPOLATE TACTICAL CAMERA ROTATION ANGLE
	current_rotation_y = lerp_angle(
		current_rotation_y, 
		target_rotation_y, 
		rotation_speed * delta
	)

	# 3. COMPUTE BASE TRANSITION TARGET POSITION
	var target_room_center := get_blended_pivot_position()
	
	# 4. ROTATE THE OFFSET VECTOR AROUND THE Y-AXIS TO ORBIT TARGET CENTER
	var rotated_offset := camera_offset.rotated(Vector3.UP, current_rotation_y)
	var final_target_pos := target_room_center + rotated_offset
	
	# 5. TRANSLATE POSITION AND LOCK CAMERA LENS FOCUS DOWNWARD
	camera_pos = camera_pos.lerp(final_target_pos, delta * 5.0)
	camera_rig.global_position = camera_pos
	camera_rig.look_at(target_room_center, Vector3.UP)


func _on_active_room_changed(room_data: Variant) -> void:
	if room_data == null:
		return
	
	var physical_room_node: Node3D = null
	if room_data is Node3D:
		physical_room_node = room_data
	elif "scene_node" in room_data: 
		physical_room_node = room_data.scene_node
	elif "node" in room_data:
		physical_room_node = room_data.node
	
	if not is_instance_valid(physical_room_node):
		push_warning("Camera could not find a physical 3D scene node for this room data!")
		return
	
	# Transition tracking setup
	if physical_room_node.has_node("CameraPivot"):
		var new_pivot = physical_room_node.get_node("CameraPivot")
		
		# Take a safe positional vector snapshot instead of tracking volatile node instances
		transition_start_pos = camera_rig.global_position
		pivot_to = new_pivot
		transition_t = 0.0
		transitioning = true


func _init_camera() -> void:
	if is_instance_valid(camera_rig):
		# Decouple camera movement from parent hierarchies to maintain clean global coordinate calculations
		camera_rig.top_level = true
		# Set initialization positions behind the player spawn point using default offsets
		camera_pos = player_spawn.global_position + camera_offset
		camera_rig.global_position = camera_pos


func get_camera_offset() -> Vector3:
	return camera_offset


func get_blended_pivot_position() -> Vector3:
	# SAFE FALLBACK: If no room is active/loaded yet, target the player or spawn point
	if not is_instance_valid(pivot_to):
		if is_instance_valid(player):
			return player.global_position
		return player_spawn.global_position
	
	# Apply an aesthetic smooth curve interpolation profile to the linear timer step
	var t := smoothstep(0.0, 1.0, transition_t)
	return transition_start_pos.lerp(pivot_to.global_position, t)


## Public input hook for your Action classes to spin the camera world context
func rotate_by(degrees: float) -> void:
	target_rotation_y += deg_to_rad(degrees)


# --- Spawning Ecosystem Pipeline Methods ---

func spawn_player(pos: Vector3) -> Entity:
	player = spawn_entity(player_definition, pos)
	controlled_entity = player
	player.add_to_group("player")
	
	# Note: Do not reparent camera_rig here. 
	# The camera runs autonomously via global coordinates configured in _process!
	return player


func spawn_enemy(pos: Vector3, definition: EntityDefinition = null) -> Entity:
	if definition == null:
		definition = enemy_pool.pick_random()
	
	var enemy := spawn_entity(definition, pos)
	enemy.controller.target = player
	enemy.add_to_group("enemies")
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
