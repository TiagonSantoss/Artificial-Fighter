class_name Game
extends Node3D

const player_definition: EntityDefinition = preload("res://assets/definitions/entities/actors/entity_definition_player.tres")
const npc_definition: EntityDefinition = preload("res://assets/definitions/entities/actors/entity_definition_npc.tres")
const companion_definition: EntityDefinition = preload("res://assets/definitions/entities/actors/entity_definition_companion.tres")
const enemy_definition: EntityDefinition = preload("res://assets/definitions/entities/actors/entity_definition_enemy.tres")
const ENTITY_SCENE = preload("res://Entities/Entity.tscn")

var controlled_entity: Entity

@onready var entities: Node3D = $Entities
@onready var player_spawn: Marker3D = $PlayerSpawn
@onready var camera_rig: Camera3D = $Camera3D

func _ready() -> void:
	var player: Entity = ENTITY_SCENE.instantiate()
	entities.add_child(player)
	player.setup(player_spawn.position, player_definition)
	controlled_entity = player

	var npc: Entity = ENTITY_SCENE.instantiate()
	entities.add_child(npc)
	npc.setup(player_spawn.position + Vector3.RIGHT, npc_definition)
	npc.sprite.modulate = Color.CORNFLOWER_BLUE
	
	var player_companion: Entity = ENTITY_SCENE.instantiate()
	entities.add_child(player_companion)
	player_companion.setup(player_spawn.position + Vector3.LEFT, companion_definition)
	player_companion.controller.follow_target = player
	
	#while true:
	var enemy: Entity = ENTITY_SCENE.instantiate()
	entities.add_child(enemy)
	enemy.setup(player_spawn.position + Vector3(2,0,2), enemy_definition)
	enemy.controller.follow_target = player_companion
		#await get_tree().create_timer(0.1).timeout

func _process(_delta):
	if controlled_entity:
		camera_rig.global_position = controlled_entity.global_position + Vector3(0, 1, 0)
