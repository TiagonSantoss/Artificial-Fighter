extends Node3D


func _ready() -> void:
	GameAutoLoad.entities = $Entities
	GameAutoLoad.player_spawn = $PlayerSpawn
	GameAutoLoad.play_intro()
