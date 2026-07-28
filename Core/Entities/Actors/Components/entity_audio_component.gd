class_name EntityAudioComponent
extends EntityComponent

@export var sfx_library: Dictionary[String, AudioStream] = {}
@export var pool_size: int = 4

var _pool: Array[AudioStreamPlayer3D] = []
var _next_player_idx: int = 0


func _ready() -> void:
	# Create a pool of players to handle overlapping sounds (e.g., rapid fire)
	for i in range(pool_size):
		var player := AudioStreamPlayer3D.new()
		player.bus = &"SFX"  # Routes directly to your Godot Audio Bus
		add_child(player)
		_pool.append(player)


## Plays a sound with optional pitch variation
func play_sfx(sfx_name: String, pitch_min: float = 0.95, pitch_max: float = 1.05) -> void:
	if not sfx_library.has(sfx_name):
		push_warning("SFX not found in library: ", sfx_name)
		return

	var player := _pool[_next_player_idx]
	_next_player_idx = (_next_player_idx + 1) % pool_size

	player.stream = sfx_library[sfx_name]
	player.pitch_scale = randf_range(pitch_min, pitch_max)
	player.play()
