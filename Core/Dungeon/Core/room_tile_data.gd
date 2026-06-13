class_name RoomTileData
extends Resource

@export var grid: Dictionary = {}   # Vector3i -> CellDefinition
@export var doors: Array = []       # [{pos, dir}]

# --------------------------------------------------
# Core mutation
# --------------------------------------------------
func set_cell(pos: Vector3i, data: CellDefinition) -> void:
	grid[pos] = data
	
	if data.is_door:
		doors.append({
			"pos": pos,
			"dir": data.door_dir
		})


func get_cell(pos: Vector3i) -> CellDefinition:
	return grid.get(pos)


func get_doors() -> Array:
	return doors
