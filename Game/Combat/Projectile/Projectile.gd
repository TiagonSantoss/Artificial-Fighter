class_name Projectile
extends Node3D

var definition: ProjectileDefinition

var damage: int
var speed: float
var pierce: int
var lifetime: float
var knockback: float

var direction: Vector3

@onready var sprite: AnimatedSprite3D = $AnimatedSprite3D
@onready var hitbox: Area3D = $Area3D


func setup(
	start_position: Vector3,
	dir: Vector3,
	projectile_definition: ProjectileDefinition
):
	definition = projectile_definition
	
	global_position = start_position
	direction = dir.normalized()
	
	damage = definition.damage
	speed = definition.speed
	pierce = definition.pierce
	lifetime = definition.lifetime
	knockback = definition.knockback

	_apply_visuals()

	await get_tree().create_timer(lifetime).timeout
	queue_free()


func _physics_process(delta):
	global_position += direction * speed * delta


func _apply_visuals():
	sprite.sprite_frames = definition.sprite_frames
	sprite.texture_filter = definition.texture_filter
	sprite.modulate = definition.modulate
	sprite.billboard = definition.billboard
	sprite.play(definition.default_animation)
