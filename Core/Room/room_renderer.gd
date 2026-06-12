class_name RoomRenderer
extends Node3D

@export var generator: RoomGenerator
@export var start_room: RoomDefinition
@export var room_pool: Array[RoomDefinition]

signal room_entered(room: DungeonRoom)
signal room_exited(room: DungeonRoom)

const CELL_SIZE := 8
const ACTIVE_RADIUS := 1

var room_materials := {}
var room_inactive_values := {}
var room_was_active := {}

var rooms := []
var player: Entity

var current_room := Vector2i(999999, 999999)
var active_room: DungeonRoom = null

func _ready():
	var generated_rooms = generator.generate(
		start_room,
		room_pool
	)
	
	for room_data in generated_rooms:
		var node = room_data.def.scene.instantiate()
		room_inactive_values[node] = 0.0
		
		# ✅ SIMPLE ROOM PLACEMENT (NO GRID MATH)
		node.position = Vector3(
			room_data.offset.x,
			0,
			room_data.offset.z
		)
		
		add_child(node)
		
		print("=== PLACEMENT ===")
		print("Node position:", node.position)
		print("Node global_position:", node.global_position)
		
		# ❌ REMOVE ALL GridMap debugging + map_to_local logic
		# ❌ DO NOT use minimum, world_origin, or grid conversion here
		
		var materials := []
		collect_materials(node, materials)
		room_materials[node] = materials
		
		var room := DungeonRoom.new()
		room.definition = room_data.def
		room.has_encounter = room_data.has_encounter
		room.node = node
		room.offset = room_data.offset
		
		# ✅ KEEP RAW GRID POSITIONS (NO CONVERSION HERE)
		for pos in room_data.def.grid_data.get_player_spawns():
			room.player_spawns.append(pos)
		
		for pos in room_data.def.grid_data.get_enemy_spawns():
			room.enemy_spawns.append(pos)
		
		print("Room loaded:", room_data.def)
		rooms.append(room)
	
	update_rooms()

func _process(_delta):
	if Game.player == null:
		return
	
	var room_pos := Vector2i(
		floor(Game.player.global_position.x / CELL_SIZE),
		floor(Game.player.global_position.z / CELL_SIZE)
	)
	
	if room_pos != current_room:
		current_room = room_pos
		
		update_rooms()

func get_room(coord: Vector2i) -> DungeonRoom:
	for room in rooms:
		var room_coord := Vector2i(
			roundi(room.offset.x),
			roundi(room.offset.z)
		)
		
		if room_coord == coord:
			#print("\n--- ROOM FOUND ---")
			#print("DEF:", room.definition.scene if room.definition else "null")
			#print("OFFSET:", room.offset)
			#print("ROOMS:", room_cord)
			#print("HAS ENCOUNTER:", room.has_encounter)
			#print("SPAWNERS:", room.enemy_spawns if "enemy_spawns" in room else "none")
			return room
	
	return null

func update_rooms():
	for room_data in rooms:
		var room: DungeonRoom = room_data
		var node: Node3D = room.node
		var offset: Vector3i = room.offset
		
		var room_coord := Vector2i(
			roundi(offset.x / CELL_SIZE),
			roundi(offset.z / CELL_SIZE)
		)
		
		var distance: int = max(
			abs(room_coord.x - current_room.x),
			abs(room_coord.y - current_room.y)
		)
		
		var active := distance <= ACTIVE_RADIUS
		var was_active: bool = room_was_active.get(room, false)
		
		# ENTER
		if active and not was_active:
			room_was_active[room] = true
			room_entered.emit(room)
		
		# EXIT
		elif not active and was_active:
			room_was_active[room] = false
			room_exited.emit(room)
		
		set_room_active(node, active)

func set_room_active(room: Node3D, active: bool):
	room.process_mode = (
		Node.PROCESS_MODE_INHERIT
		if active
		else Node.PROCESS_MODE_DISABLED
	)
	
	var target := 0.0 if active else 1.0
	
	if not room_inactive_values.has(room):
		room_inactive_values[room] = target
	
	var current: float = room_inactive_values[room]
	
	if abs(current - target) < 0.01:
		return
	
	var tween := create_tween()
	
	tween.tween_method(
		func(value):
			room_inactive_values[room] = value
			
			apply_room_inactive_value(
				room,
				value
			),
		current,
		target,
		1.5
	)

func set_inactive_amount(node: Node, value: float):
	for child in node.get_children():
		if child is MeshInstance3D:
			for i in range(child.mesh.get_surface_count()):
				var mat = child.get_active_material(i)
				
				if mat is ShaderMaterial:
					mat.set_shader_parameter(
						"inactive_amount",
						value
					)
		elif child is GridMap:
			var mesh_library: MeshLibrary = child.mesh_library
			
			if mesh_library == null:
				continue
			
			for item_id in mesh_library.get_item_list():
				var mesh := mesh_library.get_item_mesh(item_id)
				
				if mesh == null:
					continue
				
				for surface in range(mesh.get_surface_count()):
					var mat := mesh.surface_get_material(surface)
					
					if mat is ShaderMaterial:
						mat.set_shader_parameter(
							"inactive_amount",
							value
						)
		
		set_inactive_amount(child, value)

func make_gridmap_materials_unique(node: Node):
	for child in node.get_children():
		if child is GridMap:
			if child.mesh_library == null:
				continue
			
			var unique_library: MeshLibrary = child.mesh_library.duplicate(true)
			
			child.mesh_library = null
			child.mesh_library = unique_library
			
			for item_id in unique_library.get_item_list():
				var mesh := unique_library.get_item_mesh(item_id)
				
				if mesh == null:
					continue
				
				var unique_mesh := mesh.duplicate(true)
				
				for surface in range(unique_mesh.get_surface_count()):
					var mat: Material = unique_mesh.surface_get_material(surface)
					
					if mat != null:
						unique_mesh.surface_set_material(
							surface,
							mat.duplicate(true)
						)
				
				unique_library.set_item_mesh(
					item_id,
					unique_mesh
				)
		
		make_gridmap_materials_unique(child)

func collect_materials(node: Node, out: Array):
	for child in node.get_children():
		if child is MeshInstance3D:
			if child.mesh != null:
				for i in range(
					child.mesh.get_surface_count()
				):
					var mat: Material = child.get_active_material(i)
					
					if mat is ShaderMaterial:
						out.append(mat)
		elif child is GridMap:
			var mesh_library: MeshLibrary = child.mesh_library
			
			if mesh_library != null:
				for item_id in mesh_library.get_item_list():
					var mesh := mesh_library.get_item_mesh(item_id)
					
					if mesh == null:
						continue
					
					for surface in range(
						mesh.get_surface_count()
					):
						var mat := mesh.surface_get_material(surface)
						
						if mat is ShaderMaterial:
							out.append(mat)
		collect_materials(child, out)

func apply_room_inactive_value(
	room: Node3D,
	value: float
):
	if not room_materials.has(room):
		return
	
	for mat in room_materials[room]:
		if mat is ShaderMaterial:
			mat.set_shader_parameter(
				"inactive_amount",
				value
			)
