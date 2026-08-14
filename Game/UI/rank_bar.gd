extends Control

@onready var rank_texture: TextureRect = $RankTexture
@onready var progress_bar: ProgressBar = $Panel/MarginContainer/ProgressBar
@onready var progress_label: Label = $Panel/MarginContainer/ProgressBar/Label


func _ready() -> void:
	rank_texture.modulate.a = 0.0

	progress_bar.value = 0
	progress_label.text = "0 / 0"

	GState.rank_changed.connect(_on_rank_changed)
	GState.score_updated.connect(_on_score_updated)


func _on_rank_changed(state: RankState) -> void:
	var new_def = state.new_rank as RankDefinition
	var old_def = state.old_rank as RankDefinition

	if new_def == old_def:
		return

	if new_def.rank_image != null:
		rank_texture.texture = new_def.rank_image

	play_dmc_slam_animation()


func play_dmc_slam_animation() -> void:
	rank_texture.pivot_offset = rank_texture.size / 2.0

	var tween = create_tween()

	rank_texture.scale = Vector2(2.0, 2.0)
	rank_texture.modulate.a = 0.0
	rank_texture.rotation_degrees = randf_range(-15.0, 15.0)
	(
		tween
		. tween_property(rank_texture, "scale", Vector2(1.0, 1.0), 0.3)
		. set_trans(Tween.TRANS_SPRING)
		. set_ease(Tween.EASE_OUT)
	)
	tween.parallel().tween_property(rank_texture, "modulate:a", 1.0, 0.1)
	(
		tween
		. parallel()
		. tween_property(rank_texture, "rotation_degrees", 0.0, 0.2)
		. set_trans(Tween.TRANS_BACK)
		. set_ease(Tween.EASE_OUT)
	)


func _on_score_updated(current: float, floor_score: float, ceiling_score: float) -> void:
	if floor_score >= ceiling_score:
		progress_bar.max_value = 1
		progress_bar.value = 1
		progress_label.text = "max rank"
		return
	var points_into_rank = int(current - floor_score)
	var points_needed = int(ceiling_score - floor_score)

	progress_bar.max_value = points_needed
	progress_bar.value = points_into_rank

	progress_label.text = str(points_into_rank) + "  " + str(points_needed)
