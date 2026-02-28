class_name Game
extends Node3D

const player_definition: EntityDefinition = preload("res://assets/definitions/entities/actors/entity_definition_player.tres")
const npc_definition: EntityDefinition = preload("res://assets/definitions/entities/actors/entity_definition_npc.tres")
const ENTITY_SCENE = preload("res://Entities/Entity.tscn")

@onready var entities: Node3D = $Entities
@onready var player_spawn: Marker3D = $PlayerSpawn

func _ready() -> void:
	var player: Entity = ENTITY_SCENE.instantiate()
	entities.add_child(player)
	player.setup(player_spawn.position, player_definition)

	var npc: Entity = ENTITY_SCENE.instantiate()
	entities.add_child(npc)
	npc.setup(player_spawn.position + Vector3.RIGHT, npc_definition)
	npc.sprite.modulate = Color.CORNFLOWER_BLUE
