class_name GameOverScreen
extends Control

signal restart_requested

@export var flavor_messages: PackedStringArray = [
	"A dungeon vence denovo.",
	"Gizmo-chan está desapontada.",
	"Boa sorte na próxima.",
]
@export var stats_format := "Andares explorados: {floors}"  # {floors} is replaced by the number
@export var fade_time := 0.8  # only used when there is no "open" animation
@export var input_delay := 0.8  # stops button-mashing from restarting instantly

@onready var _root: Control = get_node_or_null("%Root")
@onready var _button: BaseButton = get_node_or_null("%RestartButton")
@onready var _message: Control = get_node_or_null("%Message")
@onready var _stats_number: Control = get_node_or_null("%StatsNumber")
@onready var _stats: Control = get_node_or_null("%Stats")
@onready var _anim: AnimationPlayer = get_node_or_null("%AnimationPlayer")

var _tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # children inherit it, so the UI works while paused

	if _root == null:
		for child in get_children():
			if child is Control:
				_root = child
				break
	if _root == null:
		push_error("GameOverScreen: add a Control named %Root (or any Control child)")
	if _button == null:
		push_error("GameOverScreen: add a button with the unique name %RestartButton")
	else:
		_button.pressed.connect(_on_restart_pressed)

	hide()


func open(floors_explored: int) -> void:
	if _message != null and not flavor_messages.is_empty():
		_message.set("text", flavor_messages[randi() % flavor_messages.size()])
	if _stats != null:
		_stats.set("text", stats_format.replace("{floors}", str(floors_explored)))

	if _button != null:
		_button.disabled = true

	# Gamepad aiming hides the cursor, bring it back for the button
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)

	if _tween != null:
		_tween.kill()

	if _anim != null and _anim.has_animation("open"):
		if _root != null:
			_root.modulate.a = 1.0
		show()
		_anim.play("open")
		await _anim.animation_finished
	else:
		if _root != null:
			_root.modulate.a = 0.0
		show()
		if _root != null:
			_tween = create_tween().set_ignore_time_scale(true)
			_tween.tween_property(_root, "modulate:a", 1.0, fade_time)
			await _tween.finished

	await get_tree().create_timer(input_delay, true, false, true).timeout

	if not visible or _button == null:
		return  # closed while waiting
	_button.disabled = false
	_button.grab_focus()  # Enter, Space and the gamepad A button now work


func close() -> void:
	if _tween != null:
		_tween.kill()
	if _anim != null:
		_anim.stop()
	hide()


func _on_restart_pressed() -> void:
	_button.disabled = true
	restart_requested.emit()
