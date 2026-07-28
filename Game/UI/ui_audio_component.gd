class_name UIAudioComponent
extends Node

@export var pool_size: int = 4
@export_enum("Master", "SFX", "UI") var audio_bus: String = "SFX"

var _one_shot_pool: Array[AudioStreamPlayer] = []
var _next_player_idx: int = 0


func _ready() -> void:
	for i in range(pool_size):
		var player := AudioStreamPlayer.new()
		player.bus = audio_bus
		add_child(player)
		_one_shot_pool.append(player)


func play_sound(stream: AudioStream, pitch_min: float = 0.95, pitch_max: float = 1.05) -> void:
	if stream == null:
		return

	var player := _one_shot_pool[_next_player_idx]
	_next_player_idx = (_next_player_idx + 1) % pool_size

	player.stream = stream
	player.pitch_scale = randf_range(pitch_min, pitch_max)
	player.play()
