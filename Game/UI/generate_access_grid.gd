extends Node3D

#FIX THAT
#THIS CODE IS ASS

# @export var columns: int = 5
# @export var spacing: Vector2 = Vector2(0.2, 0.2)


func _ready() -> void:
	# GState.accessories_changed.connect(_on_accessories_changed)
	pass

# func _on_accessories_changed(state: AccessoriesChangedState) -> void:
# 	_clear_grid()
# 	_build_grid(state.current_accessories)
#
#
# func _clear_grid() -> void:
# 	for child in get_children():
# 		if child is Sprite3D:
# 			child.queue_free()
#
#
# func _build_grid(items: Array[ItemInstance]) -> void:
# 	var total_items := items.size()
# 	if total_items == 0:
# 		return
#
# 	var total_rows: float = ceil(float(total_items) / float(columns))
# 	var start_x: float = -((columns - 1) * spacing.x) / 2.0
# 	var start_z: float = -((total_rows - 1) * spacing.y) / 2.0

# for i in range(total_items):
# 	var instance := items[i]
#
# 	if instance.definition != null and instance.definition.icon != null:
# 		var sprite := Sprite3D.new()
# 		sprite.texture = instance.definition.icon
# 		sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
# 		sprite.pixel_size = 0.05
#
# 		# 1. Create the Physics Area
# 		var area := Area3D.new()
#
# 		# 2. Create the Collision Box
# 		var collision := CollisionShape3D.new()
# 		var box_shape := BoxShape3D.new()
# 		# Adjust the size to match your sprite's visual dimensions in 3D space
# 		box_shape.size = Vector3(1.5, 1.5, 0.2)
# 		collision.shape = box_shape
#
# 		# 3. Assemble the node tree
# 		area.add_child(collision)
# 		sprite.add_child(area)
# 		add_child(sprite)
#
# 		# 4. Connect interaction signals
# 		# Using .bind() lets us pass the specific 'instance' or 'sprite' to the function
# 		area.input_event.connect(_on_item_clicked.bind(instance))
# 		area.mouse_entered.connect(_on_item_hovered.bind(sprite))
# 		area.mouse_exited.connect(_on_item_unhovered.bind(sprite))
#
# 		var current_row: int = i / columns
# 		var current_col: int = i % columns
#
# 		var pos_x: float = start_x + (current_col * spacing.x)
# 		var pos_z: float = start_z + (current_row * spacing.y)
#
# 		sprite.position = Vector3(pos_x, 0.0, pos_z)

# func _on_item_clicked(
# 	camera: Node,
# 	event: InputEvent,
# 	position: Vector3,
# 	normal: Vector3,
# 	shape_idx: int,
# 	instance: ItemInstance
# ) -> void:
# 	# Detect left mouse button clicks
# 	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
# 		print("Clicked on item: ", instance.definition.display_name)
# 		# Add your equip/unequip or info panel logic here
#
#
# func _on_item_hovered(sprite: Sprite3D) -> void:
# 	# Example hover effect: Scale the sprite up slightly
# 	var tween = create_tween()
# 	tween.tween_property(sprite, "scale", Vector3(1.2, 1.2, 1.2), 0.1)
#
#
# func _on_item_unhovered(sprite: Sprite3D) -> void:
# 	# Revert scale when mouse leaves
# 	var tween = create_tween()
# 	tween.tween_property(sprite, "scale", Vector3(1.0, 1.0, 1.0), 0.1)

#REWRITE THAT SHIT LATER
