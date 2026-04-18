class_name RoomGrid
extends Node

@export var room_pool: Array[RoomDefinition]

var occupied := {} # Dictionary<Vector3i, bool>

const start_definition: RoomDefinition = preload("res://assets/definitions/rooms/start_room.tres")
const CELL_SIZE = 8
const MAX_ROOMS = 3

class RoomInstance:
	var position: Vector3i
	var grid: GridData
	var node: Node3D

func spawn_room(def: RoomDefinition, offset: Vector3i):
	var instance = RoomInstance.new()
	
	var node = def.scene.instantiate()
	node.position = offset * CELL_SIZE
	add_child(node)
	
	instance.grid = GridBuild.new().build(node.get_node("GridMap"))
	instance.node = node
	instance.position = offset
	
	return instance

func pick_random_room() -> RoomDefinition:
	return room_pool.pick_random()

func check_collision(grid: GridData, offset: Vector3i) -> bool:
	for pos in grid.cells.keys():
		var world_pos = pos + offset
		
		if occupied.has(world_pos):
			return true
	
	return false

func try_attach_room(door: Dictionary, room_def: RoomDefinition):
	print("Tentando sala:", room_def)
	print("Porta alvo:", door)
	for candidate in room_def.grid_data.get_doors():
		print("Candidate:", candidate.pos, candidate.dir)
		if candidate.dir != -door.dir:
			continue
		var offset = door.pos - candidate.pos
		
		if not check_collision(room_def.grid_data, offset):
			var room = spawn_room(room_def, offset)
			
			var new_doors: Array[Dictionary] = []

			for d in room_def.grid_data.get_doors():
				new_doors.append({
					"pos": d.pos + offset,
					"dir": d.dir
				})
			
			print("DIR CHECK:", candidate.dir, "vs", -door.dir)
			
			register_room(room_def.grid_data, offset)
			
			return {
				"room": room,
				"new_doors": new_doors
			}
	return null

func generate():
	var rooms := []
	
	var start_room: RoomInstance = spawn_room(start_definition, Vector3i.ZERO)
	print("DOORS DO START:", start_room.grid.get_doors())
	rooms.append(start_room)
	
	register_room(start_room.grid, Vector3i.ZERO)
	
	var open_doors: Array[Dictionary] = []
	print(start_room.grid.get_doors().size())
	for d in start_room.grid.get_doors():
		print(d.pos)
		print(d.dir)
		open_doors.append({
			"pos": d.pos,
			"dir": d.dir
		})
		
	
	print(open_doors)
	while rooms.size() < MAX_ROOMS:
		var door = open_doors.pop_back()
		
		var next_def: RoomDefinition = pick_random_room()
		#print(next_def)
		var result = try_attach_room(door, next_def)
		
		if result != null:
			rooms.append(result.room)
			
			for new_door in result.new_doors:
				if new_door.pos != door.pos:
					open_doors.append(new_door)

func register_room(grid: GridData, offset: Vector3i):
	for pos in grid.grid.keys():
		occupied[pos + offset] = true

func _ready():
	generate()
