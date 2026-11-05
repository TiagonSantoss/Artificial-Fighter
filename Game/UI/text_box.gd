class_name TextureBox
extends TextureRect

@onready var rich_text: Typewriter = $MarginContainer/RichTextLabel


func type_text(message: String) -> void:
	if not is_node_ready():
		await ready

	rich_text.type(message)

	await rich_text.finished

	await get_tree().create_timer(5.0).timeout

	queue_free()
