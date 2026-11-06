class_name TextureBox
extends CanvasLayer

@onready var rich_text: Typewriter = $window/MarginContainer/RichTextLabel
@onready var close_button: Button = $window/Button
@onready var anim_player: AnimationPlayer = $AnimationPlayer

var messages: Array[String] = []
var current_index: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	if close_button:
		close_button.pressed.connect(close_dialogue)

	rich_text.meta_clicked.connect(_on_meta_clicked)


func _input(event: InputEvent) -> void:
	if get_tree().paused and event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		advance_dialogue()


func close_dialogue() -> void:
	get_tree().paused = false
	queue_free()


func start_messages(lines: Array[String]) -> void:
	messages = lines
	current_index = 0
	_play_current_message()


func _play_current_message() -> void:
	if not is_node_ready():
		await ready

	rich_text.type(messages[current_index])


func advance_dialogue() -> void:
	if rich_text.is_typing():
		rich_text.skip()
		return

	current_index += 1

	if current_index < messages.size():
		_play_current_message()
	else:
		get_tree().paused = false
		queue_free()


func _on_meta_clicked(meta_data: Variant) -> void:
	var command := str(meta_data)

	if command.begins_with("anim_"):
		var anim_name := command.trim_prefix("anim_")

		if anim_player.has_animation(anim_name):
			anim_player.play(anim_name)
		else:
			push_warning("Animation not found: " + anim_name)
