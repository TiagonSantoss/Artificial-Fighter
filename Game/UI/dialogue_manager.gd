extends Node

const DIALOGUE_BOX = preload("res://Game/UI/text_box.tscn")


## Needs a BBCode formatted text!
func show_message(text: String):
	var text_box = DIALOGUE_BOX.instantiate()

	get_tree().current_scene.add_child(text_box)

	text_box.type_text(text)
