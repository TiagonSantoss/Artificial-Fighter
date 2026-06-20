class_name ArenaBarrierPiece
extends Node3D

@onready var sprite: AnimatedSprite3D = $AnimatedSprite3D
@onready var body: StaticBody3D = $StaticBody3D

func set_active(active: bool) -> void:
	if sprite:
		sprite.visible = active
		if active:
			sprite.play()
		else:
			sprite.stop()
	
	for c in body.get_children():
		if c is CollisionShape3D:
			c.set_deferred("disabled", not active)
