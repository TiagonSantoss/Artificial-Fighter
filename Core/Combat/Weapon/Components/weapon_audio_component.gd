class_name WeaponAudioComponent
extends WeaponComponent

@export var pool_size: int = 3

var _one_shot_pool: Array[AudioStreamPlayer3D] = []
var _next_player_idx: int = 0

@onready var loop_player: AudioStreamPlayer3D = $LoopPlayer


func _ready() -> void:
	for i in range(pool_size):
		var player := AudioStreamPlayer3D.new()
		player.bus = &"SFX"
		add_child(player)
		_one_shot_pool.append(player)


func play_shoot(stream: AudioStream) -> void:
	if not stream:
		return

	var player := _one_shot_pool[_next_player_idx]
	_next_player_idx = (_next_player_idx + 1) % pool_size

	player.stream = stream
	player.pitch_scale = randf_range(0.95, 1.05)
	player.play()


func start_loop(stream: AudioStream) -> void:
	if not loop_player.playing:
		loop_player.stream = stream
		loop_player.play()


func stop_loop() -> void:
	loop_player.stop()
