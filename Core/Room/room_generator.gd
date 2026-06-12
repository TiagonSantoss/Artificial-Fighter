class_name RoomGenerator
extends Resource

class RoomNode:
	var def: RoomDefinition
	var offset: Vector3i
	var has_encounter: bool = false

var occupied: Dictionary = {}
var placed_rooms: Array = []
var open_doors: Array = []

func generate(start_def: RoomDefinition, pool: Array[RoomDefinition]) -> Array:
	placed_rooms.clear()
	open_doors.clear()
	occupied.clear()
	
	var start := RoomNode.new()
	start.def = start_def
	start.offset = Vector3i.ZERO
	
	_place_room(start)
	
	open_doors = get_world_doors(start)
	
	while open_doors.size() > 0:
		var door = open_doors.pop_back()
		
		var next = pool.pick_random()
		if next == null:
			continue
		
		var result = try_attach(door, next)
		
		if result == null:
			continue
			
		_place_room(result.room)
		open_doors.append_array(result.new_doors)
		
	return placed_rooms

func _place_room(room: RoomNode) -> void:
	placed_rooms.append(room)
	print("GEN ROOM:", room, "enc:", room.has_encounter)
	
	var cells := room.def.grid_data.grid.keys()
	
	var minimun = cells[0]
	
	for c in cells:
		minimun = Vector3i(
			min(minimun.x, c.x),
			min(minimun.y, c.y),
			min(minimun.z, c.z)
		)
	
	for c in cells:
		var cell := room.def.grid_data.get_cell(c)
		
		if cell.enemy_spawn:
			room.has_encounter = true
		
		var world_pos = (c - minimun) + room.offset
		occupied[world_pos] = true

func get_world_doors(room: RoomNode, exclude = null) -> Array:
	var result := []
	
	for d in room.def.grid_data.get_doors():
		if d == exclude:
			continue
		
		result.append({
			"pos": d.pos + room.offset,
			"dir": d.dir
		})
	
	return result

func check_collision(grid: GridData, offset: Vector3i) -> bool:
	var cells := grid.grid.keys()
	
	var minimun = cells[0]
	
	for c in cells:
		minimun = Vector3i(
			min(minimun.x, c.x),
			min(minimun.y, c.y),
			min(minimun.z, c.z)
		)
	
	for c in cells:
		var world_pos = (c - minimun) + offset
		
		if occupied.has(world_pos):
			print("💥 COLLISION at:", world_pos)
			return true
	
	return false

func try_attach(door, room_def):
	for candidate in room_def.grid_data.get_doors():
		if candidate.dir != -door.dir:
			continue
		
		var offset = door.pos + door.dir - candidate.pos
		
		var has_collision := check_collision(room_def.grid_data, offset)
		
		print("\n--- TRY ATTACH ---")
		print("Door:", door)
		print("Candidate door:", candidate)
		print("Offset:", offset)
		print("Collision?:", has_collision)
		
		if has_collision:
			print("❌ REJECTED (collision)")
			continue
		
		print("✅ ACCEPTED")
		
		var room := RoomNode.new()
		room.def = room_def
		room.offset = offset
		
		return {
			"room": room,
			"new_doors": get_world_doors(room, candidate)
		}
	
	return null
