extends Resource
class_name GridData

var grid: Dictionary = {} # Vector3i -> CellData

func set_cell(pos: Vector3i, data: CellDefinition):
	grid[pos] = data

func get_cell(pos: Vector3i) -> CellDefinition:
	return grid.get(pos)

func is_walkable(pos: Vector3i) -> bool:
	var cell = get_cell(pos)
	return cell and cell.walkable

func is_spawn(pos: Vector3i) -> bool:
	var cell = get_cell(pos)
	return cell and cell.spawn

func is_enemy_spawn(pos: Vector3i) -> bool:
	var cell = get_cell(pos)
	return cell and cell.enemy_spawn
