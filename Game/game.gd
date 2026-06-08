class_name Game
extends Node3D

const player_definition: EntityDefinition = preload("res://assets/definitions/entities/actors/entity_definition_player.tres")
const npc_definition: EntityDefinition = preload("res://assets/definitions/entities/actors/entity_definition_npc.tres")
const companion_definition: EntityDefinition = preload("res://assets/definitions/entities/actors/entity_definition_companion.tres")
const enemy_definition: EntityDefinition = preload("res://assets/definitions/entities/actors/entity_definition_enemy.tres")
const ENTITY_SCENE = preload("res://Core/Entities/Entity.tscn")

signal controlled_entity_changed(entity: Entity)

var _controlled_entity: Entity

var controlled_entity: Entity:
	get:
		return _controlled_entity
	set(value):
		_controlled_entity = value
		controlled_entity_changed.emit(value)

static var player: Entity

var entity_camera_pivot: Marker3D

@onready var entities: Node3D = $Entities
@onready var player_spawn: Marker3D = $PlayerSpawn
@onready var camera_rig: Node3D = $Camera3D

func spawn_entity(definition: EntityDefinition, pos: Vector3) -> Entity:
	var e: Entity = ENTITY_SCENE.instantiate()
	entities.add_child(e)
	e.setup(pos, definition)
	return e

func _ready():
	player = spawn_entity(player_definition, player_spawn.position)
	
	controlled_entity = player
	entity_camera_pivot = player.camera_pivot
	
	var _npc = spawn_entity(npc_definition, player_spawn.position + Vector3.RIGHT)
	
	var companion = spawn_entity(companion_definition, player_spawn.position + Vector3.UP)
	companion.controller.follow_target = player
	
	
	
	camera_rig.reparent(entity_camera_pivot)
	
	while true:
		await get_tree().create_timer(10).timeout
		var enemy = spawn_entity(enemy_definition, player_spawn.position + Vector3(1,2,1))
		enemy.controller.follow_target = player
		
