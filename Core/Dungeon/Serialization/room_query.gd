class_name RoomQuery
extends RefCounted

# --------------------------------------------------
# Gameplay queries (kept separate from data)
# --------------------------------------------------
static func is_walkable(room: RoomTileData, pos: Vector3i) -> bool:
	var cell := room.get_cell(pos)
	return cell != null and cell.walkable


static func is_spawn(room: RoomTileData, pos: Vector3i) -> bool:
	var cell := room.get_cell(pos)
	return cell != null and cell.spawn


static func is_enemy_spawn(room: RoomTileData, pos: Vector3i) -> bool:
	var cell := room.get_cell(pos)
	return cell != null and cell.enemy_spawn


static func get_player_spawns(room: RoomTileData) -> Array[Vector3i]:
	var result: Array[Vector3i] = []
	
	for pos in room.grid.keys():
		if is_spawn(room, pos):
			result.append(pos)
	
	return result


static func get_enemy_spawns(room: RoomTileData) -> Array[Vector3i]:
	var result: Array[Vector3i] = []
	
	for pos in room.grid.keys():
		if is_enemy_spawn(room, pos):
			result.append(pos)
	
	return result
