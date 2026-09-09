extends Label

@export var low_health_threshold: float = 100.0
@export var max_shake: float = 5.0

var actual_health: float = 500.0
var displayed_health: int = 500

var health_tween: Tween

var progress_bar_tween: Tween

@onready var original_position: Vector2 = position
@onready var progress_bar := $"../../"


func _ready() -> void:
	GState.health_changed.connect(_on_health_changed)
	text = str(actual_health)


func _on_health_changed(new_health: float) -> void:
	actual_health = new_health

	if health_tween and health_tween.is_valid():
		health_tween.kill()

	if progress_bar_tween and progress_bar_tween.is_valid():
		progress_bar_tween.kill()

	health_tween = create_tween()
	progress_bar_tween = create_tween()

	(
		health_tween
		. tween_property(self, "displayed_health", actual_health, 0.4)
		. set_trans(Tween.TRANS_QUINT)
		. set_ease(Tween.EASE_OUT)
	)

	(
		progress_bar_tween
		. tween_property(progress_bar, "value", actual_health, 0.4)
		. set_trans(Tween.TRANS_QUINT)
		. set_ease(Tween.EASE_OUT)
	)


func _process(_delta: float) -> void:
	text = str(round(displayed_health))

	if actual_health < low_health_threshold:
		_apply_wiggle()
	else:
		_reset_transform()


func _apply_wiggle() -> void:
	var random_x = randf_range(-max_shake, max_shake)
	var random_y = randf_range(-max_shake, max_shake)
	position = original_position + Vector2(random_x, random_y)
	rotation_degrees = randf_range(-3.0, 3.0)


func _reset_transform() -> void:
	position = original_position
	rotation_degrees = 0.0
