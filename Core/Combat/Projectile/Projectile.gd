class_name Projectile
extends RefCounted

var definition: ProjectileDefinition

var position: Vector3
var velocity: Vector3
var direction: Vector3

var frame := 0
var animation_time := 0.0

var source_entity: Entity
var source_team

var remaining_pierce := 0
var remaining_bounces := 0
var lifetime_left := 0.0

var damage_multiplier := 1.0
var knockback_multiplier := 1.0
var drag_factor := 1.0

var already_hit := {}
var active_index := -1

var collision_shape := SphereShape3D.new()
var exclude: Array[RID] = []


func setup(request: ProjectileRequest) -> void:
	definition = request.definition
	position = request.position
	
	direction = request.direction.normalized()
	velocity = direction * definition.speed
	
	damage_multiplier = request.damage_multiplier
	knockback_multiplier = request.knockback_multiplier
	
	remaining_pierce = int((definition.pierce + 1) * request.pierce_multiplier)
	remaining_bounces = definition.bounce_count
	lifetime_left = definition.lifetime
	
	drag_factor = definition.drag
	
	source_entity = request.source_entity
	source_team = request.source_team
	
	already_hit.clear()
	collision_shape.radius = definition.radius
	exclude.clear()
	
	if source_entity:
		exclude.append(source_entity.get_rid())
		for child in source_entity.get_children():
			if child is CollisionObject3D:
				exclude.append(child.get_rid())


func reset() -> void:
	velocity = Vector3.ZERO
	direction = Vector3.ZERO
	lifetime_left = 0.0
	frame = 0
	animation_time = 0.0
	already_hit.clear()
	active_index = -1
	exclude.clear()
