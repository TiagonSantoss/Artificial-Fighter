class_name Game
extends Node3D

const player_definition: EntityDefinition = preload("res://assets/definitions/entities/actors/entity_definition_player.tres")

@onready var player: Entity
@onready var event_handler: EventHandler = $EventHandler
@onready var entities: Node3D = $Entities
@onready var player_spawn: Marker3D = $PlayerSpawn


func _ready() -> void:
	player = Entity.new(player_spawn.position, player_definition)
	entities.add_child(player)
	var npc := Entity.new(player_spawn.position + Vector3.RIGHT, player_definition)
	npc.modulate = Color.ORANGE_RED
	entities.add_child(npc)
