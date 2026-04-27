class_name Projectile
extends Node3D

var definition: ProjectileDefinition

var damage: int
var speed: float
var pierce: int
var lifetime: float
var knockback: float

var direction: Vector3
var source_team
var source_entity: Entity

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
	var from = global_position
	var to = from + direction * speed * delta
	
	var space = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	
	var hit = space.intersect_ray(query)
	
	if hit:
		var target = hit.collider
		
		if target.has_method("on_projectile_hit"):
			var consumed = target.on_projectile_hit(self)
			
			if consumed:
				queue_free()
				return
	
	global_position = to

func _apply_visuals():
	sprite.sprite_frames = definition.sprite_frames
	sprite.texture_filter = definition.texture_filter
	sprite.modulate = definition.modulate
	sprite.billboard = definition.billboard
	sprite.scale = definition.sprite_scale
	sprite.play(definition.default_animation)
