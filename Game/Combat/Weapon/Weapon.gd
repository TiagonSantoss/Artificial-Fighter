class_name Weapon
extends Node3D

const PROJECTILE_SCENE = preload("res://Game/Combat/Projectile/Projectile.tscn")

var definition: WeaponDefinition
var can_fire := true

@onready var sprite = $AnimatedSprite3D
@onready var muzzle = $Muzzle


func setup(weapon_definition):
	definition = weapon_definition
	_apply_visuals()


func _apply_visuals():
	sprite.sprite_frames = definition.sprite_frames
	sprite.texture_filter = definition.texture_filter
	sprite.modulate = definition.modulate
	sprite.billboard = definition.billboard
	sprite.scale = definition.sprite_scale
	sprite.play(definition.default_animation)

func fire(direction: Vector3):
	if not can_fire:
		return
	
	can_fire = false
	
	var projectile: Projectile = PROJECTILE_SCENE.instantiate()
	
	get_tree().current_scene.add_child(projectile)
	
	projectile.setup(
		muzzle.global_position,
		direction,
		definition.projectile
	)
	
	await get_tree().create_timer(definition.fire_rate).timeout
	can_fire = true
