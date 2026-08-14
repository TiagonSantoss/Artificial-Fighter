extends Control

@onready var rank_texture = $RankTexture
@onready var progress_bar = $ProgressBar
@onready var progress_label = $ProgressLabel  # The text showing "X / Y"


func _ready():
	GState.rank_changed.connect(_on_rank_changed)
	GState.score_updated.connect(_on_score_updated)  # Connect the new signal


func _on_score_updated(current: float, floor_score: float, ceiling_score: float):
	# Handle the scenario where the player hit the maximum rank (SSS)
	if floor_score == ceiling_score:
		progress_bar.max_value = 1
		progress_bar.value = 1
		progress_label.text = "MAX RANK"
		return

	# Calculate how many points we have earned in THIS specific rank tier
	var points_into_rank = current - floor_score

	# Calculate how many total points this specific rank tier requires
	var points_needed = ceiling_score - floor_score

	# Update the Progress Bar visual
	progress_bar.max_value = points_needed
	progress_bar.value = points_into_rank

	# Update the text (round the floats to whole numbers so it looks clean!)
	progress_label.text = str(round(points_into_rank)) + " / " + str(round(points_needed))


func _on_rank_changed(state: RankState):
	# Cast the variables back to RankDefinitions so the editor knows what they are
	var new_def = state.new_rank as RankDefinition
	var old_def = state.old_rank as RankDefinition

	# Optional: Ignore if the rank didn't actually change
	if new_def == old_def:
		return

	# 1. Swap the image!
	rank_texture.texture = new_def.rank_image

	# 2. Play the DMC-style pop animation
	play_dmc_slam_animation()


func play_dmc_slam_animation():
	# Make sure the texture scales from its center, not the top-left corner
	rank_texture.pivot_offset = rank_texture.size / 2.0

	# Kill any currently running tweens so they don't glitch out
	var tween = create_tween()

	# Start the image at 200% size and completely transparent
	rank_texture.scale = Vector2(2.0, 2.0)
	rank_texture.modulate.a = 0.0

	# Animate 1: Slam the scale down to 100% with a bounce effect
	(
		tween
		. tween_property(rank_texture, "scale", Vector2(1.0, 1.0), 0.3)
		. set_trans(Tween.TRANS_SPRING)
		. set_ease(Tween.EASE_OUT)
	)

	# Animate 2: Fade it in at the exact same time (using parallel)
	tween.parallel().tween_property(rank_texture, "modulate:a", 1.0, 0.1)

	# Optional Animate 3: Add a slight rotation shake
	rank_texture.rotation_degrees = randf_range(-15.0, 15.0)
	(
		tween
		. parallel()
		. tween_property(rank_texture, "rotation_degrees", 0.0, 0.2)
		. set_trans(Tween.TRANS_BACK)
		. set_ease(Tween.EASE_OUT)
	)
