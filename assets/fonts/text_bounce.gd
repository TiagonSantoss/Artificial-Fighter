@tool
class_name TextBounce
extends RichTextEffect

var bbcode := "bounce"


func _process_custom_fx(char_fx: CharFXTransform) -> bool:
	var speed: float = char_fx.env.get("speed", 8.0)
	var height: float = char_fx.env.get("height", 6.0)
	char_fx.offset.y = (
		-absf(sin(char_fx.elapsed_time * speed + char_fx.relative_index * 0.5)) * height
	)
	return true
