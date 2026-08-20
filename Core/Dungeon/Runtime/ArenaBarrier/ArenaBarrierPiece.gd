class_name ArenaBarrierPiece
extends Node3D

@onready var sprites: Array[AnimatedSprite3D] = []
@onready var meshes: Array[MeshInstance3D] = []
@onready var body: StaticBody3D = $StaticBody3D


func _ready() -> void:
	for child in get_children():
		if child is AnimatedSprite3D:
			sprites.append(child)
		if child is MeshInstance3D:
			meshes.append(child)


func set_active(active: bool) -> void:
	for s in sprites:
		s.visible = active

		if active:
			if s.sprite_frames and s.sprite_frames.has_animation("active"):
				s.play("active")
			else:
				s.play()
		else:
			if s.sprite_frames and s.sprite_frames.has_animation("inactive"):
				s.play("inactive")
			else:
				s.stop()

	if body:
		for c in body.get_children():
			if c is CollisionShape3D:
				c.set_deferred("disabled", not active)

	for m in meshes:
		m.visible = active
