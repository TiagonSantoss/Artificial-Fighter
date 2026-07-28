class_name DebugConsole
extends CanvasLayer

@onready var panel: PanelContainer = $PanelContainer
@onready var log_output: RichTextLabel = $PanelContainer/VBoxContainer/LogOutput
@onready var command_input: LineEdit = $PanelContainer/VBoxContainer/CommandInput

var command_registry: CommandRegistry


func _ready() -> void:
	command_registry = CommandRegistry.new()
	add_child(command_registry)

	panel.hide()
	process_mode = PROCESS_MODE_ALWAYS  # Allows console input even if game is paused

	command_input.text_submitted.connect(_on_command_submitted)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_QUOTELEFT or event.keycode == KEY_SECTION:
			toggle_console()


func toggle_console() -> void:
	var is_container_visible := not panel.visible
	panel.visible = is_container_visible

	if is_container_visible:
		command_input.grab_focus()
		command_input.clear()
	else:
		command_input.release_focus()


func _on_command_submitted(text: String) -> void:
	if text.strip_edges().is_empty():
		return

	_log_message("> " + text, Color.GRAY)
	command_input.clear()

	var game := get_tree().current_scene as Game
	var player := game.controlled_entity if game else null

	var response = command_registry.execute_command(text, player)
	if not response.is_empty():
		_log_message(response, Color.WHITE)


func _log_message(msg: String, color: Color) -> void:
	log_output.push_color(color)
	log_output.append_text(msg + "\n")
	log_output.pop()
