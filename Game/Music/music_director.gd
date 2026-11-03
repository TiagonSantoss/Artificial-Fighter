extends Node

enum Mood { EXPLORE, COMBAT }

const PARAM_NAME := "MusicType"
const START_VALUE := 6

var labels := {
	0: "TheVibeMusic",
	1: "Touro",
	2: "MAXIMUS RAGE",
	3: "Deiz Mosquitos No meu QUARTO",
	4: "ESTACAO DE JOGOS",
	5: "Frutiger",
	6: "Wiiu",
	7: "Silence",
}

var explore_values: Array[int] = [3, 4, 6, 7]
var combat_values: Array[int] = [0, 1, 2, 5]

var mood: int = -1
var rng := RandomNumberGenerator.new()
var last_value := -1
var current_value := -1
var is_playing := false
var first_pick := true


func _ready() -> void:
	rng.randomize()
	_set_track(START_VALUE)


func set_mood(new_mood: Mood) -> void:
	if new_mood == mood:
		return
	mood = new_mood
	_play_next()


func stop_all() -> void:
	var emitter := _get_emitter()
	if emitter and is_playing:
		emitter.stop()
	is_playing = false
	current_value = -1
	mood = -1
	first_pick = true


func _play_next() -> void:
	var emitter := _get_emitter()
	if emitter == null:
		return

	var value: int
	if first_pick and mood == Mood.EXPLORE:
		value = START_VALUE
	else:
		value = _pick_value()
	first_pick = false
	if not is_playing:
		emitter.play()

	last_value = value
	current_value = value
	is_playing = true


func _set_track(value: int) -> void:
	var label: String = labels.get(value, "")

	if label != "":
		FmodServer.set_global_parameter_by_name_with_label(PARAM_NAME, label)
	else:
		FmodServer.set_global_parameter_by_name(PARAM_NAME, value)


func _pick_value() -> int:
	var pool := combat_values if mood == Mood.COMBAT else explore_values
	if pool.size() == 1:
		return pool[0]

	var value := pool[rng.randi_range(0, pool.size() - 1)]
	while value == last_value:
		value = pool[rng.randi_range(0, pool.size() - 1)]
	return value


func _get_emitter() -> Node:
	var emitter = GameAutoLoad.emitter
	return emitter if is_instance_valid(emitter) else null
