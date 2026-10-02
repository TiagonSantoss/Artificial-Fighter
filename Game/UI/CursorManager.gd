extends Node

var arrow_cursor = preload("res://assets/sprites/UI/cursor_normal.PNG")
var click_cursor = preload("res://assets/sprites/UI/cursor_selecionado2.PNG")
var hover_cursor = preload("res://assets/sprites/UI/cursor_selecionado.PNG")
var aim_cursor = preload("res://assets/sprites/UI/cursor_mira.PNG")

# UI cursors usually point from a specific corner or offset
var ui_hotspot = Vector2(0, 20)

# Aim cursors MUST be centered! (Change 16, 16 to half of your image's width/height)
var aim_hotspot = Vector2(16, 16)


func _ready():
	# 1. Register the standard UI arrow
	Input.set_custom_mouse_cursor(arrow_cursor, Input.CURSOR_ARROW, ui_hotspot)

	# 2. Register the UI hover/click hand
	Input.set_custom_mouse_cursor(hover_cursor, Input.CURSOR_POINTING_HAND, ui_hotspot)

	# 3. Register the AIM cursor to Godot's built-in CROSSHAIR shape
	Input.set_custom_mouse_cursor(aim_cursor, Input.CURSOR_CROSS, aim_hotspot)


func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var hovered_node = get_viewport().gui_get_hovered_control()

		if (
			hovered_node != null
			and hovered_node.mouse_default_cursor_shape == Control.CURSOR_POINTING_HAND
		):
			if event.pressed:
				Input.set_custom_mouse_cursor(click_cursor, Input.CURSOR_POINTING_HAND, ui_hotspot)
			else:
				Input.set_custom_mouse_cursor(hover_cursor, Input.CURSOR_POINTING_HAND, ui_hotspot)
