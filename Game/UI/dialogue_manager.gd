extends Node

const DIALOGUE_BOX = preload("res://Game/UI/text_box.tscn")


## Needs a BBCode formatted text!
func show_messages(lines: Array[String]) -> void:
	get_tree().paused = true

	var box = DIALOGUE_BOX.instantiate()
	add_child(box)

	box.start_messages(lines)
