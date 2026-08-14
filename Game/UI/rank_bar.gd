extends Control

# --- NODE REFERENCES ---
@onready var rank_texture: TextureRect = $RankTexture
@onready var progress_bar: ProgressBar = $Panel/MarginContainer/ProgressBar
@onready var progress_label: Label = $Panel/MarginContainer/ProgressBar/Label


func _ready() -> void:
	# 1. Hide the texture at the very start of the game
	rank_texture.modulate.a = 0.0

	# 2. Reset the progress bar visually
	progress_bar.value = 0
	progress_label.text = "0 / 0"

	GState.rank_changed.connect(_on_rank_changed)
	GState.score_updated.connect(_on_score_updated)


# --- RANK ANIMATION LOGIC ---
func _on_rank_changed(state: RankState) -> void:
	var new_def = state.new_rank as RankDefinition
	var old_def = state.old_rank as RankDefinition

	# Ignore if the rank didn't actually change (safety check)
	if new_def == old_def:
		return

	# Swap the image to the new rank's texture
	if new_def.rank_image != null:
		rank_texture.texture = new_def.rank_image

	# Trigger the Devil May Cry style pop-in animation
	play_dmc_slam_animation()


func play_dmc_slam_animation() -> void:
	# Set pivot to center so it scales outward, not down from the corner
	rank_texture.pivot_offset = rank_texture.size / 2.0

	# Create a new tween (this automatically overwrites old ones to prevent glitches)
	var tween = create_tween()

	# Reset starting position for the animation (200% size, invisible)
	rank_texture.scale = Vector2(2.0, 2.0)
	rank_texture.modulate.a = 0.0
	rank_texture.rotation_degrees = randf_range(-15.0, 15.0)

	# Step 1: Slam scale down to 100% with a bouncy spring effect
	(
		tween
		. tween_property(rank_texture, "scale", Vector2(1.0, 1.0), 0.3)
		. set_trans(Tween.TRANS_SPRING)
		. set_ease(Tween.EASE_OUT)
	)

	# Step 2: Fade it in at the exact same time
	tween.parallel().tween_property(rank_texture, "modulate:a", 1.0, 0.1)

	# Step 3: Snap the rotation back to 0 degrees for extra impact
	(
		tween
		. parallel()
		. tween_property(rank_texture, "rotation_degrees", 0.0, 0.2)
		. set_trans(Tween.TRANS_BACK)
		. set_ease(Tween.EASE_OUT)
	)


# --- PROGRESS BAR LOGIC ---
func _on_score_updated(current: float, floor_score: float, ceiling_score: float) -> void:
	if floor_score >= ceiling_score:
		progress_bar.max_value = 1
		progress_bar.value = 1
		progress_label.text = "max rank"
		return

	# Use int() to completely remove any .0 decimals
	var points_into_rank = int(current - floor_score)
	var points_needed = int(ceiling_score - floor_score)

	progress_bar.max_value = points_needed
	progress_bar.value = points_into_rank

	# Add the slash and spaces in the middle!
	progress_label.text = str(points_into_rank) + " / " + str(points_needed)
