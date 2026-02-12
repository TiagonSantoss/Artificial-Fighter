class_name Game
extends Node3D

const player_definition: EntityDefinition = preload("res://assets/definitions/entities/actors/entity_definition_player.tres")

@onready var player: Entity
@onready var event_handler: EventHandler = $EventHandler
@onready var entities: Node3D = $Entities


func _ready() -> void:
	var player_start_pos: Vector3 = Grid.world_to_grid(get_viewport_rect().size.floor() / 2)
	player = Entity.new(player_start_pos, player_definition)
	entities.add_child(player)
	var npc := Entity.new(player_start_pos + Vector3.RIGHT, player_definition)
	npc.modulate = Color.ORANGE_RED
	entities.add_child(npc)
