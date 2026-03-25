class_name Grid
extends Object

const tile_size = Vector3(0.1, 0.1, 0.1)


static func grid_to_world(grid_pos: Vector3) -> Vector3:
	var world_pos: Vector3 = grid_pos * tile_size
	return world_pos


static func world_to_grid(world_pos: Vector3) -> Vector3i:
	return Vector3i(
		floor(world_pos.x / tile_size.x + 0.5),
		floor(world_pos.y / tile_size.y + 0.5),
		floor(world_pos.z / tile_size.z + 0.5)
	)
