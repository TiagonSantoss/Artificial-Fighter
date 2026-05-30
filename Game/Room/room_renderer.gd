class_name RoomRenderer
extends Node3D

@export var generator: RoomGenerator
@export var start_room: RoomDefinition
@export var room_pool: Array[RoomDefinition]

const CELL_SIZE := 8
const ACTIVE_RADIUS := 1

var room_materials := {}
var room_inactive_values := {}

var rooms := []
var player: Entity

var current_room := Vector2i(999999, 999999)

func _ready():
	var generated_rooms = generator.generate(
		start_room,
		room_pool
	)
	
	for room_data in generated_rooms:
		var node = room_data.def.scene.instantiate()
		
		room_inactive_values[node] = 0.0
		
		node.position = Vector3(
			room_data.offset.x,
			0,
			room_data.offset.z
		)
		
		add_child(node)
		make_gridmap_materials_unique(node)
		
		var materials := []
		collect_materials(node, materials)
		
		room_materials[node] = materials
		
		rooms.append({
			"node": node,
			"offset": room_data.offset
		})
	
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

func update_rooms():
	for room_data in rooms:
		var room: Node3D = room_data.node
		var offset: Vector3i = room_data.offset
		
		var room_coord := Vector2i(
			roundi(offset.x / CELL_SIZE),
			roundi(offset.z / CELL_SIZE)
		)
		
		var distance: int = max(
			abs(room_coord.x - current_room.x),
			abs(room_coord.y - current_room.y)
		)
		
		var active := distance <= ACTIVE_RADIUS
		
		set_room_active(room, active)

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
