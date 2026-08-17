class_name AttackShot
extends RefCounted

var direction: Vector3

var damage_multiplier := 1.0
var knockback_multiplier := 1.0
var pierce_multiplier := 1.0
var speed_multiplier := 1.0

var projectile: ProjectileDefinition
var melee: MeleeDefinition

var metadata := {}


func clone() -> AttackShot:
	var copy := AttackShot.new()

	copy.direction = direction
	copy.damage_multiplier = damage_multiplier
	copy.knockback_multiplier = knockback_multiplier
	copy.pierce_multiplier = pierce_multiplier
	copy.speed_multiplier = speed_multiplier
	copy.projectile = projectile
	copy.melee = melee

	return copy
