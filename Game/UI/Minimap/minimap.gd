class_name Minimap
extends Control

@export var chunk_manager: ChunkManager
@export var minimap_scale := 0.2

@export_category("Sizing")
@export var box_size := Vector2(16, 16)
@export var line_thickness := 4.0
@export var outline_thickness := 2.0

@export_category("Colors")
@export var color_current := Color("ffcc00")    # Bright Amber/Gold
@export var color_loaded := Color("ffffff")     # Crisp White
@export var color_visited := Color("4a525a")    # Slate Dark Gray
@export var color_line := Color("2d3135")       # Deep Tech Gray
@export var color_outline := Color("111315")    # Dark outline contrast

func _ready() -> void:
	# Stretch completely inside its parent panel container frame
	anchors_preset = PRESET_FULL_RECT


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if not chunk_manager or chunk_manager.layout.is_empty() or not chunk_manager.graph:
		return

	var ui_center := size / 2.0
	var layout := chunk_manager.layout
	var graph := chunk_manager.graph
	
	var current_center_v3 := Vector3.ZERO
	if layout.has(chunk_manager.current_room_id):
		current_center_v3 = layout[chunk_manager.current_room_id]

	# STEP 1: DRAW THICK CONNECTIONS/HALLWAYS
	for id in graph.connections.keys():
		if not layout.has(id): continue
		for conn in graph.connections[id]:
			if not layout.has(conn.target_id): continue
			
			if _is_room_visible(id) or _is_room_visible(conn.target_id):
				var pos_a := _get_screen_pos(layout[id], current_center_v3, ui_center)
				var pos_b := _get_screen_pos(layout[conn.target_id], current_center_v3, ui_center)
				
				# Optional: Draw a dark underlying border line for depth shadow contrast
				draw_line(pos_a, pos_b, color_outline, line_thickness + 2.0)
				draw_line(pos_a, pos_b, color_line, line_thickness)

	# STEP 2: DRAW ROOM BOXES WITH OUTLINES
	for id in layout.keys():
		if not _is_room_visible(id): continue
			
		var room_center := _get_screen_pos(layout[id], current_center_v3, ui_center)
		var box_rect := Rect2(room_center - (box_size / 2.0), box_size)
		
		var target_color := color_loaded
		if id == chunk_manager.current_room_id:
			target_color = color_current
		elif chunk_manager.get("visited_rooms") and chunk_manager.visited_rooms.has(id):
			target_color = color_visited
			
		# Draw the background border drop outline box first
		var outline_rect := box_rect.grow(outline_thickness)
		draw_rect(outline_rect, color_outline, true)
		
		# Draw the actual core indicator square over it
		draw_rect(box_rect, target_color, true)

	# STEP 3: DRAW FIXED RADAR CROSSHAIR AT SCREEN CENTER
	_draw_radar_crosshair(ui_center)


func _is_room_visible(id: String) -> bool:
	if id == chunk_manager.current_room_id: return true
	if chunk_manager.loaded_rooms.has(id): return true
	if chunk_manager.get("visited_rooms") and chunk_manager.visited_rooms.has(id): return true
	return false


func _get_screen_pos(room_pos_v3: Vector3, current_center_v3: Vector3, ui_center: Vector2) -> Vector2:
	var relative_pos := room_pos_v3 - current_center_v3
	return Vector2(relative_pos.x * minimap_scale, relative_pos.z * minimap_scale) + ui_center


func _draw_radar_crosshair(center: Vector2) -> void:
	var cross_size := 6.0
	# Draw simple, subtle targeting ticks over the player box position
	draw_line(center - Vector2(cross_size + 4, 0), center - Vector2(4, 0), color_current, 1.5)
	draw_line(center + Vector2(4, 0), center + Vector2(cross_size + 4, 0), color_current, 1.5)
	draw_line(center - Vector2(0, cross_size + 4), center - Vector2(0, 4), color_current, 1.5)
	draw_line(center + Vector2(0, 4), center + Vector2(0, cross_size + 4), color_current, 1.5)
