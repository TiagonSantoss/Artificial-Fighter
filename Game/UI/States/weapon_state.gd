class_name WeaponState
extends RefCounted

var entity: Entity
var weapon_sprite: AnimatedSprite3D


func _init(p_entity: Entity = null, p_weapon_sprite: AnimatedSprite3D = null) -> void:
	entity = p_entity
	weapon_sprite = p_weapon_sprite
