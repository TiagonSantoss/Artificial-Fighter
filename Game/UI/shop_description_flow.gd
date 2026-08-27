class_name ShopDescriptions extends VFlowContainer

var tween: Tween

@onready var items: Array[Node]
@onready var desc: RichTextLabel = $Info


func _ready() -> void:
	await get_tree().create_timer(1.0).timeout

	desc.bbcode_enabled = true
	GState.shop_item_selected.connect(display_item_info)

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


func display_item_info(offer: ShopOffer) -> void:
	var item_def = offer.item_to_sell

	if offer == null or offer.item_to_sell == null:
		desc.text = "[color=gray]Empty Slot[/color]"
		return

	var new_text := (
		"[color=green]%s[/color] \n \n %s \n \n [color=gold]costs: %d %s[/color]"
		% [item_def.display_name, item_def.shop_description, offer.price, offer.currency_required]
	)

	desc.text = new_text

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
