class_name ProjectileRequest
extends RefCounted

var position: Vector3
var direction: Vector3

var definition: ProjectileDefinition

var source_entity: Entity
var source_team

var damage_multiplier := 1.0
var knockback_multiplier := 1.0
var speed_multiplier = 1.0

var pierce_multiplier := 1.0
