class_name HitVFX
extends Node3D

@onready var particles: GPUParticles3D = $GPUParticles3D

func play() -> void:
	particles.restart()
	particles.emitting = true

	await get_tree().create_timer(1.5).timeout
	queue_free()
