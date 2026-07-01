extends Node

const CELL_SIZE := 4.0

var grid := {}

func rebuild(entities: Array) -> void:
	grid.clear()
	
	for entity in entities:
		var cell := _cell(entity.global_position)
		
		if !grid.has(cell):
			grid[cell] = []
		
		grid[cell].append(entity)

func query_segment(start: Vector3, end: Vector3) -> Array:
	var result := []
	
	var min_cell := Vector3i(
		floori(minf(start.x, end.x) / CELL_SIZE),
		floori(minf(start.y, end.y) / CELL_SIZE),
		floori(minf(start.z, end.z) / CELL_SIZE)
	)
	
	var max_cell := Vector3i(
		floori(maxf(start.x, end.x) / CELL_SIZE),
		floori(maxf(start.y, end.y) / CELL_SIZE),
		floori(maxf(start.z, end.z) / CELL_SIZE)
	)
	
	for x in range(min_cell.x, max_cell.x + 1):
		for y in range(min_cell.y, max_cell.y + 1):
			for z in range(min_cell.z, max_cell.z + 1):
				var key := Vector3i(x, y, z)
				
				if grid.has(key):
					result.append_array(grid[key])
	
	return result

func _cell(pos: Vector3) -> Vector3i:
	return Vector3i(
		floori(pos.x / CELL_SIZE),
		floori(pos.y / CELL_SIZE),
		floori(pos.z / CELL_SIZE)
	)
