class_name Minimap
extends Control

@export_category("Visuals")
@export var cell_size := 16.0
@export var spacing := 24.0
@export var line_width := 4.0
@export var rotate_with_camera := true
@export var rotation_smoothing := 10.0  # 0 = snap instantly
@export_range(0, 3) var map_rotation_steps := 0

@export_category("Colors")
@export var color_current := Color.WHITE
@export var color_visited := Color.WEB_GRAY
@export var color_unseen := Color.DIM_GRAY
@export var color_door := Color.DARK_GRAY
@export var color_bonus_link := Color.MEDIUM_PURPLE

@export_category("Highlights")
## Key = exact room_id ("start") or the room definition's file name ("shop" for shop.tres)
@export var highlights: Dictionary = {"start": Color.GOLD}
## Key = room_id prefix
@export var highlight_prefixes: Dictionary = {"bonus_": Color.MEDIUM_PURPLE}

var room_coords := {}  # room_id -> Vector2i grid position (main graph only)
var discovered_rooms: Array[String] = []
var current_room_id := ""

var _graph: RoomGraph
var _chunks: ChunkManager
var _angle := 0.0
var _angle_ready := false


func _ready() -> void:
	clip_contents = true
	await get_tree().process_frame

	_chunks = GameAutoLoad.chunk_manager
	if _chunks:
		_chunks.active_room_changed.connect(_on_active_room_changed)


func _process(delta: float) -> void:
	if _chunks == null:
		return

	# New dungeon generated -> rebuild everything
	if _chunks.graph != _graph:
		_rebuild()

	_update_rotation(delta)
	queue_redraw()


func _on_active_room_changed(room) -> void:
	if room == null or not "room_id" in room:
		return

	current_room_id = room.room_id
	if not discovered_rooms.has(current_room_id):
		discovered_rooms.append(current_room_id)


# ---------------------------------------------------------
# MAP BUILDING
# ---------------------------------------------------------
func _rebuild() -> void:
	_graph = _chunks.graph
	room_coords.clear()
	discovered_rooms.clear()
	current_room_id = ""

	if _graph == null:
		return

	_traverse_graph("start", Vector2i.ZERO, [])

	if _chunks.current_room:
		_on_active_room_changed(_chunks.current_room)


func _traverse_graph(room_id: String, coord: Vector2i, visited: Array) -> void:
	if room_id in visited:
		return

	visited.append(room_id)
	room_coords[room_id] = coord

	for conn in _graph.connections.get(room_id, []):
		var next_coord := coord

		match conn.direction:
			DoorSocket.Direction.NORTH:
				next_coord.y -= 1
			DoorSocket.Direction.SOUTH:
				next_coord.y += 1
			DoorSocket.Direction.EAST:
				next_coord.x += 1
			DoorSocket.Direction.WEST:
				next_coord.x -= 1
			_:
				continue  # SPECIAL etc. never go on the main grid

		_traverse_graph(conn.target_id, next_coord, visited)


# ---------------------------------------------------------
# CAMERA ROTATION
# ---------------------------------------------------------
func _update_rotation(delta: float) -> void:
	if not rotate_with_camera:
		_angle = 0.0
		return

	var target := 0.0

	# 1. Pega a rotação Y direta do rig (como no script 2) para evitar problemas de vetor
	if is_instance_valid(GameAutoLoad) and GameAutoLoad.camera_rig:
		target = GameAutoLoad.camera_rig.rotation.y
	else:
		var cam := get_viewport().get_camera_3d()
		if cam == null:
			cam = get_tree().root.get_camera_3d()
		if cam != null:
			target = cam.global_rotation.y

	# 2. Adiciona os steps da sua configuração
	target += map_rotation_steps * (PI / 2.0)

	# 3. Mantém a sua animação de suavização original
	if rotation_smoothing <= 0.0 or not _angle_ready:
		_angle = target
		_angle_ready = true
	else:
		_angle = lerp_angle(_angle, target, 1.0 - exp(-rotation_smoothing * delta))


func _to_screen(coord: Vector2i, anchor: Vector2i, center: Vector2) -> Vector2:
	var offset := Vector2(coord - anchor) * spacing
	# NOTA: Agora aplicamos a rotação positiva pura da câmera!
	return center + offset.rotated(_angle)


# ---------------------------------------------------------
# DRAWING
# ---------------------------------------------------------
func _draw() -> void:
	if _graph == null or room_coords.is_empty() or current_room_id == "":
		return

	var anchor_id := current_room_id
	if not room_coords.has(anchor_id):
		anchor_id = _chunks.special_links.get(current_room_id, "")
	if not room_coords.has(anchor_id):
		return

	var anchor: Vector2i = room_coords[anchor_id]
	var center := size / 2.0

	# Hallways first so they sit under the rooms
	for room_id in discovered_rooms:
		if not room_coords.has(room_id):
			continue
		var from := _to_screen(room_coords[room_id], anchor, center)

		for conn in _graph.connections.get(room_id, []):
			if room_coords.has(conn.target_id) and discovered_rooms.has(conn.target_id):
				var to := _to_screen(room_coords[conn.target_id], anchor, center)
				draw_line(from, to, color_door, line_width)

	# Rooms
	for room_id in room_coords:
		var is_discovered := discovered_rooms.has(room_id)
		if not is_discovered and not _is_adjacent_to_discovered(room_id):
			continue

		var pos := _to_screen(room_coords[room_id], anchor, center)

		var fill := color_unseen
		if room_id == current_room_id:
			fill = color_current
		elif is_discovered:
			fill = color_visited

		_draw_room(pos, fill, _get_highlight(room_id))

		if is_discovered and _chunks.special_links.has(room_id):
			_draw_bonus_marker(pos + Vector2(cell_size * 0.5, -cell_size * 0.5))

		if room_id == current_room_id:
			_draw_player_marker(pos)

	_draw_bonus_panel()


func _draw_room(pos: Vector2, fill: Color, accent: Variant) -> void:
	# Rooms rotate with the map so they line up with the hallways
	# NOTA: Agora usa _angle positivo para as salas rodarem perfeitamente alinhadas
	draw_set_transform(pos, _angle, Vector2.ONE)

	var half := Vector2.ONE * (cell_size * 0.5)
	var rect := Rect2(-half, half * 2.0)
	draw_rect(rect, fill)

	if accent != null:
		draw_rect(rect.grow(2.0), accent, false, 2.0)

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_player_marker(pos: Vector2) -> void:
	# Always points up = the way the camera is facing
	var s := cell_size * 0.3
	draw_colored_polygon(
		PackedVector2Array([pos + Vector2(0, -s), pos + Vector2(s, s), pos + Vector2(-s, s)]),
		Color.BLACK
	)


func _draw_bonus_marker(pos: Vector2) -> void:
	var s := cell_size * 0.28
	draw_colored_polygon(
		PackedVector2Array(
			[pos + Vector2(0, -s), pos + Vector2(s, 0), pos + Vector2(0, s), pos + Vector2(-s, 0)]
		),
		color_bonus_link
	)


func _draw_bonus_panel() -> void:
	var bonus_ids: Array[String] = []
	for id in _chunks.special_links:
		if not room_coords.has(id) and _graph.nodes.has(id):
			bonus_ids.append(id)

	if bonus_ids.is_empty():
		return

	var pad := 6.0
	var box := cell_size
	var panel_size := Vector2(bonus_ids.size() * (box + pad) + pad, box + pad * 2.0)
	var panel_pos := size - panel_size - Vector2(4.0, 4.0)

	draw_rect(Rect2(panel_pos, panel_size), Color(0, 0, 0, 0.5))
	draw_string(
		ThemeDB.fallback_font,
		panel_pos + Vector2(pad, -4.0),
		"BONUS",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		10,
		color_bonus_link
	)

	for i in bonus_ids.size():
		var bonus_id := bonus_ids[i]
		var rect := Rect2(panel_pos + Vector2(pad + i * (box + pad), pad), Vector2.ONE * box)

		var fill := color_unseen
		if bonus_id == current_room_id:
			fill = color_current
		elif discovered_rooms.has(bonus_id):
			fill = color_visited

		draw_rect(rect, fill)

		var accent: Variant = _get_highlight(bonus_id)
		if accent != null:
			draw_rect(rect.grow(2.0), accent, false, 2.0)

		if bonus_id == current_room_id:
			_draw_player_marker(rect.get_center())


# ---------------------------------------------------------
# HELPERS
# ---------------------------------------------------------
func _get_highlight(room_id: String) -> Variant:
	if highlights.has(room_id):
		return highlights[room_id]

	if _graph and _graph.nodes.has(room_id):
		var variant: RoomVariant = _graph.nodes[room_id]
		var def := variant.definition
		if def and def.resource_path != "":
			var key := def.resource_path.get_file().get_basename()
			if highlights.has(key):
				return highlights[key]

	for prefix in highlight_prefixes:
		if room_id.begins_with(prefix):
			return highlight_prefixes[prefix]

	return null


func _is_adjacent_to_discovered(target_id: String) -> bool:
	for visited_id in discovered_rooms:
		for conn in _graph.connections.get(visited_id, []):
			if conn.target_id == target_id:
				return true
	return false
