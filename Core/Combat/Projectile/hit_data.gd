class_name HitData
extends RefCounted

var damage := 0
var damage_mult := 1.0

var direction := Vector3.ZERO
var knockback := 0.0
var knockback_multiplier := 1.0

var source_entity: Entity
var source_team

var projectile: RefCounted

var hit_position := Vector3.ZERO
var hit_normal := Vector3.UP

var critical := false
var frozen := false

var lifetime := 0.0

func get_final_damage() -> float:
	return damage * damage_mult

func get_final_knockback() -> float:
	return knockback * knockback_multiplier
