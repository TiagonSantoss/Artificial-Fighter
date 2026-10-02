extends Control

@export var damaged_frame_indices: Array[int] = [11, 12, 13]
@export var rank_frame_indices: Array[int] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
@export var max_rank: int = 10

var frame_width := 450.0
var frame_height := 450.0
var columns := 4

var tween: Tween
var bar_tween: Tween

var is_currently_damaged := false
var current_rank := -1  # Starts unranked (-1)

@onready var reaction_node = $Blue
@onready var atlas: AtlasTexture = reaction_node.texture
@onready var progress_bar: ProgressBar = $Panel/MarginContainer/ProgressBar


func _ready() -> void:
	reaction_node.offset_transform_enabled = true

	GState.player_damaged.connect(_on_player_damaged)
	GState.rank_changed.connect(_on_rank_changed)

	_update_idle_face()


# Helper function to handle the grid math and visibility
func set_atlas_frame(index: int) -> void:
	if index < 0:
		visible = false
		return

	visible = true
	var current_col = index % columns
	var current_row = int(float(index) / columns)
	atlas.region.position.x = current_col * frame_width
	atlas.region.position.y = current_row * frame_height


# Helper to safely set the face and progress bar based on the current rank
func _update_idle_face() -> void:
	if progress_bar:
		progress_bar.max_value = max_rank
		var target_value = max(0, current_rank)

		# Smoothly tween the progress bar value so it counts up nicely!
		if bar_tween and bar_tween.is_valid():
			bar_tween.kill()
		bar_tween = create_tween()
		bar_tween.tween_property(progress_bar, "value", target_value, 0.2).set_ease(Tween.EASE_OUT)

	if current_rank < 0:
		set_atlas_frame(-1)
		return

	var highest_safe_index = min(max_rank, rank_frame_indices.size() - 1)
	var safe_rank = clampi(current_rank, 0, highest_safe_index)

	var target_frame = rank_frame_indices[safe_rank]
	set_atlas_frame(target_frame)


func _on_rank_changed(new_rank: int, old_rank: int) -> void:
	current_rank = new_rank

	if is_currently_damaged:
		return

	_update_idle_face()

	# Happy bounce on rank up (only when visible / rank >= 0)
	if new_rank > old_rank and new_rank >= 0:
		if tween and tween.is_running():
			tween.kill()

		tween = create_tween()
		reaction_node.offset_transform_position = Vector2(0, -20)

		(
			tween
			. tween_property(reaction_node, "offset_transform_position", Vector2.ZERO, 0.4)
			. set_trans(Tween.TRANS_BOUNCE)
			. set_ease(Tween.EASE_OUT)
		)


func _on_player_damaged(iframe_time: float) -> void:
	is_currently_damaged = true

	if tween and tween.is_running():
		tween.kill()

	# FORCE visible immediately so the damage face actually renders on screen!
	visible = true

	var random_face = damaged_frame_indices.pick_random()
	set_atlas_frame(random_face)

	# Update progress bar immediately to 0 on hit
	if progress_bar:
		progress_bar.value = 0

	reaction_node.offset_transform_position = Vector2(0, 60)
	tween = create_tween()
	(
		tween
		. tween_property(reaction_node, "offset_transform_position", Vector2.ZERO, 0.4)
		. set_trans(Tween.TRANS_ELASTIC)
		. set_ease(Tween.EASE_OUT)
	)

	# Wait out the iframe duration while showing the ouch face
	await get_tree().create_timer(iframe_time, false).timeout

	is_currently_damaged = false

	# Revert to idle face (which will now hide the node since rank reset to -1)
	_update_idle_face()
