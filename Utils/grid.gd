class_name Grid
extends Object

const tile_size = Vector3(0.1, 0.1, 0.1)


static func grid_to_world(grid_pos: Vector3) -> Vector3:
	var world_pos: Vector3 = grid_pos * tile_size
	return world_pos


static func world_to_grid(world_pos: Vector3) -> Vector3:
	var grid_pos: Vector3 = world_pos / tile_size
	return grid_pos
