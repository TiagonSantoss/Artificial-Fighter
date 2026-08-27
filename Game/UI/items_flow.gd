class_name ShopItems
extends FlowContainer

@export var item_ui_scene: PackedScene

var tween: Tween
@onready var items: Array[Node] = []


func populate_shop(offers: Array[ShopOffer]) -> void:
	for child in get_children():
		child.queue_free()

	for offer in offers:
		if offer == null:
			continue

		var new_item_ui = item_ui_scene.instantiate()
		add_child(new_item_ui)
		new_item_ui.setup(offer)

	await get_tree().create_timer(1.0).timeout

	items = get_children()

	for c: Control in items:
		c.offset_transform_enabled = true
		c.offset_transform_scale = Vector2.ZERO

	if tween and tween.is_running():
		tween.kill()

	tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.set_parallel(true)

	var idx := 0
	for c: Control in items:
		tween.tween_property(c, "offset_transform_scale", Vector2.ONE, 0.05).set_delay(idx * 0.05)
		(
			tween
			. tween_property(c, "offset_transform_position_ratio:x", 0.0, 0.25)
			. from(randf_range(-1.0, 1.0))
			. set_delay(idx * 0.05)
		)
		idx += 1
