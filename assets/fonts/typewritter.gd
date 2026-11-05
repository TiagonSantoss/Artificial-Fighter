class_name Typewriter
extends RichTextLabel

signal started
signal typing_finished
signal character_shown(index: int, character: String)

@export var chars_per_second := 40.0
@export var punctuation_delay := {".": 0.25, "!": 0.25, "?": 0.25, ",": 0.12, "…": 0.25}

var _plain := ""  # the text without any tags, one entry per visible character
var _pauses := {}  # visible character count -> extra seconds
var _accum := 0.0
var _pause_left := 0.0
var _typing := false


func _ready() -> void:
	bbcode_enabled = true
	install_effect(TextBounce.new())  # optional, see the effects section below
	set_process(false)


func type(raw: String) -> void:
	text = _parse(raw)
	visible_characters = 0
	_accum = 0.0
	_pause_left = _pauses.get(0, 0.0)  # a {pause} at the very start
	_typing = true
	set_process(true)
	started.emit()


func skip() -> void:
	if not _typing:
		return
	visible_characters = -1  # show everything
	_finish()


func is_typing() -> bool:
	return _typing


func _process(delta: float) -> void:
	if _pause_left > 0.0:
		_pause_left -= delta
		return

	_accum += delta
	var interval := 1.0 / chars_per_second

	while _accum >= interval and visible_characters < _plain.length():
		_accum -= interval
		visible_characters += 1

		var index := visible_characters - 1
		var ch := _plain[index]
		character_shown.emit(index, ch)

		var delay: float = _pauses.get(visible_characters, 0.0) + punctuation_delay.get(ch, 0.0)
		if delay > 0.0:
			_pause_left = delay
			_accum = 0.0
			break

	if visible_characters >= _plain.length():
		_finish()


func _finish() -> void:
	_typing = false
	set_process(false)
	finished.emit()


# Strips {pause=x} tags and records where they were. BBCode [tags] pass through untouched.
func _parse(raw: String) -> String:
	_pauses.clear()
	var out := ""
	var plain := ""
	var i := 0

	while i < raw.length():
		var c := raw[i]

		if c == "[":
			var end := raw.find("]", i)
			if end != -1:
				out += raw.substr(i, end - i + 1)
				i = end + 1
				continue
		elif c == "{":
			var end := raw.find("}", i)
			if end != -1:
				var cmd := raw.substr(i + 1, end - i - 1)
				if cmd.begins_with("pause="):
					_pauses[plain.length()] = float(cmd.get_slice("=", 1))
				i = end + 1
				continue

		out += c
		plain += c
		i += 1

	_plain = plain
	return out
