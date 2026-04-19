class_name RoomGenerator
extends Resource

class RoomNode:
	var def: RoomDefinition
	var offset: Vector3i

var occupied := {}
var placed_rooms := []
var open_doors := []

func generate(start_def: RoomDefinition, pool: Array[RoomDefinition]) -> Array:
	placed_rooms.clear()
	open_doors.clear()
	occupied.clear()
	
	var start = RoomNode.new()
	start.def = start_def
	start.offset = Vector3i.ZERO
	
	placed_rooms.append(start)
	register_room(start)
	
	open_doors = get_world_doors(start)
	
	while open_doors.size() > 0:
		var door = open_doors.pop_back()
		
		var next = pool.pick_random()
		var result = try_attach(door, next)
		
		print("Tentando conectar porta:", door)
		print("Room escolhida:", next)
		
		if result:
			placed_rooms.append(result.room)
			open_doors.append_array(result.new_doors)
	
	return placed_rooms

func get_world_doors(room: RoomNode) -> Array:
	var result := []
	
	for d in room.def.grid_data.get_doors():
		result.append({
			"pos": d.pos + room.offset,
			"dir": d.dir
		})
	
	return result

func try_attach(door, room_def):
	for candidate in room_def.grid_data.get_doors():
		if candidate.dir != -door.dir:
			continue
		
		var offset = door.pos + candidate.pos #+ door.dir
		
		print("Offset:", offset)
		print("Collision?", check_collision(room_def.grid_data, offset))
		
		#if check_collision(room_def.grid_data, offset):
		#	continue
		
		var room = RoomNode.new()
		room.def = room_def
		room.offset = offset
		
		register_room(room)
		
		return {
			"room": room,
			"new_doors": get_world_doors(room)
		}
	return null

func check_collision(grid: GridData, offset: Vector3i) -> bool:
	for pos in grid.grid.keys():
		if occupied.has(pos + offset):
			return true
	return false

func register_room(room: RoomNode):
	for pos in room.def.grid_data.grid.keys():
		occupied[pos + room.offset] = true
