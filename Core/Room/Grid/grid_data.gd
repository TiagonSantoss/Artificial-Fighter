class_name GridData
extends Resource

@export var grid: Dictionary = {}
@export var doors: Array[Dictionary] = []

func set_cell(pos: Vector3i, data: CellDefinition):
	grid[pos] = data
	if data.is_door:
		doors.append({"pos": pos, "dir": data.door_dir})

func get_cell(pos: Vector3i) -> CellDefinition:
	return grid.get(pos)

func get_doors():
	return doors

func is_walkable(pos: Vector3i) -> bool:
	var cell = get_cell(pos)
	return cell and cell.walkable

func is_spawn(pos: Vector3i) -> bool:
	var cell = get_cell(pos)
	return cell and cell.spawn

func is_enemy_spawn(pos: Vector3i) -> bool:
	var cell = get_cell(pos)
	return cell and cell.enemy_spawn

func get_player_spawns() -> Array[Vector3i]:
	var result: Array[Vector3i] = []
	
	for pos in grid.keys():
		if is_spawn(pos):
			result.append(pos)
	
	return result

func get_enemy_spawns() -> Array[Vector3i]:
	var result: Array[Vector3i] = []

	for pos in grid.keys():
		if is_enemy_spawn(pos):
			result.append(pos)

	return result
