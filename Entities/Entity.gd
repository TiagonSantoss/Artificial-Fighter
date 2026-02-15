class_name Entity
extends Sprite3D

var _grid_position: Vector3i

var grid_position: Vector3i:
	get:
		return _grid_position
	set(value):
		_grid_position = value
		position = Grid.grid_to_world(_grid_position)


func _init(start_position: Vector3i, entity_definition: EntityDefinition) -> void:
	centered = false
	grid_position = start_position
	texture = entity_definition.texture
	modulate = entity_definition.color
	billboard = entity_definition.billboard
	texture_filter = entity_definition.texture_filter
	shaded = false


func move(move_offset: Vector3i) -> void:
	grid_position += move_offset
