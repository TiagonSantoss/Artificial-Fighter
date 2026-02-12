class_name Entity
extends Sprite3D

var grid_position: Vector3:
	set(value):
		grid_position = value
		position = Grid.grid_to_world(grid_position)

func _init(start_position: Vector3, entity_definition: EntityDefinition) -> void:
	centered = false
	grid_position = start_position
	texture = entity_definition.texture
	modulate = entity_definition.color


func move(move_offset: Vector3) -> void:
	grid_position += move_offset
