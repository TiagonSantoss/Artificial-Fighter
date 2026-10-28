extends Node

var rng := RandomNumberGenerator.new()


func set_run_seed(_seed: int) -> void:
	rng.seed = _seed
