class_name Minimap
extends Control

@export var chunk_manager: ChunkManager
@export var minimap_scale := 0.2

@export_category("Sizing")
@export var box_size := Vector2(16, 16)
@export var line_thickness := 4.0
@export_range(0.0, 10.0) var outline_thickness := 2.0

@export_category("Colors")
@export var color_current := Color("ffcc00")
@export var color_loaded := Color("ffffff")
@export var color_visited := Color("4a525a")
@export var color_line := Color("2d3135")
@export var color_outline := Color("111315")


func _ready() -> void:
	anchors_preset = PRESET_FULL_RECT


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if chunk_manager == null:
		return

	if chunk_manager.graph == null:
		return

	if chunk_manager.layout.is_empty():
		return

	if chunk_manager.current_room == null:
		return

	var ui_center := size / 2.0
	var layout := chunk_manager.layout
	var graph := chunk_manager.graph

	var current_room_id := chunk_manager.current_room.room_id

	var current_center_v3: Vector3 = layout.get(current_room_id, Vector3.ZERO)

	var cam_angle := 0.0

	if Game.instance:
		cam_angle = Game.instance.camera_rig.rotation.y

	# --------------------------------------------------
	# DRAW CONNECTIONS
	# --------------------------------------------------

	for id in graph.connections.keys():
		if not layout.has(id):
			continue

		for conn in graph.connections[id]:
			if not layout.has(conn.target_id):
				continue

			if not _is_room_visible(id) and not _is_room_visible(conn.target_id):
				continue

			var pos_a := _get_screen_pos(layout[id], current_center_v3, ui_center, cam_angle)

			var pos_b := _get_screen_pos(
				layout[conn.target_id], current_center_v3, ui_center, cam_angle
			)

			draw_line(pos_a, pos_b, color_outline, line_thickness + 2.0)

			draw_line(pos_a, pos_b, color_line, line_thickness)

	# --------------------------------------------------
	# DRAW ROOMS
	# --------------------------------------------------

	for id in layout.keys():
		if not _is_room_visible(id):
			continue

		var room_center := _get_screen_pos(layout[id], current_center_v3, ui_center, cam_angle)

		var box_rect := Rect2(room_center - box_size * 0.5, box_size)

		var target_color := color_loaded

		if id == current_room_id:
			target_color = color_current
		elif chunk_manager.visited_rooms.has(id):
			target_color = color_visited

		var outline_rect := box_rect.grow(outline_thickness)

		draw_rect(outline_rect, color_outline, true)

		draw_rect(box_rect, target_color, true)


func _is_room_visible(id: String) -> bool:
	if chunk_manager.current_room:
		if id == chunk_manager.current_room.room_id:
			return true

	if chunk_manager.loaded_rooms.has(id):
		return true

	if chunk_manager.visited_rooms.has(id):
		return true

	return false


func _get_screen_pos(
	room_pos_v3: Vector3, current_center_v3: Vector3, ui_center: Vector2, cam_angle: float
) -> Vector2:
	var relative := room_pos_v3 - current_center_v3

	var pos := Vector2(relative.x, relative.z) * minimap_scale

	var rotated := Vector2(
		pos.x * cos(cam_angle) - pos.y * sin(cam_angle),
		pos.x * sin(cam_angle) + pos.y * cos(cam_angle)
	)

	return rotated + ui_center
