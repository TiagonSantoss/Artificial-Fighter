extends TextureRect

var frame_width := 500.0
var frame_height := 502.0

var columns := 3

var tween: Tween

@onready var reaction_node = self
@onready var atlas: AtlasTexture = reaction_node.texture
@onready var original_pos: Vector2 = reaction_node.position


func _ready() -> void:
	GState.health_changed.connect(_on_health_changed)


func _on_health_changed(new_health: float) -> void:
	if tween and tween.is_running():
		tween.kill()

	tween = get_tree().create_tween()

	var frame_index := 0

	frame_index = randi_range(1, 5)

	var current_col = frame_index % columns
	var current_row = int(float(frame_index) / columns)

	(
		tween
		. tween_property(reaction_node, "offset_transform_position", Vector2(0, 35), 0.3)
		. set_trans(Tween.TRANS_ELASTIC)
		. set_ease(Tween.EASE_OUT_IN)
	)

	(
		tween
		. tween_property(reaction_node, "offset_transform_position", Vector2.ZERO, .7)
		. set_trans(Tween.TRANS_ELASTIC)
		. set_ease(Tween.EASE_IN_OUT)
		. from(Vector2(0, 35))
	)

	atlas.region.position.x = current_col * frame_width
	atlas.region.position.y = current_row * frame_height

	await get_tree().create_timer(0.7).timeout

	if new_health >= 50.0:
		frame_index = 0
	elif new_health >= 10:
		frame_index = 3
	elif new_health <= 0:
		frame_index = 4

	current_col = frame_index % columns
	current_row = int(float(frame_index) / columns)

	atlas.region.position.x = current_col * frame_width
	atlas.region.position.y = current_row * frame_height
