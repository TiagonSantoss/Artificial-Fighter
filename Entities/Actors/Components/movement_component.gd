class_name MovementComponent
extends EntityComponent

var move_speed: float
var max_speed: float
var acceleration: float
var friction: float
var jump_force: float

var last_direction: Vector3 = Vector3.ZERO

func configure(definition: EntityDefinition):
	move_speed = definition.move_speed
	max_speed = definition.max_speed
	acceleration = definition.acceleration
	friction = definition.friction
	jump_force = definition.jump_force

func apply_movement(direction: Vector3, delta: float) -> void:
	if direction.length() > 0.01:
		last_direction = direction.normalized()
	var dir := direction.normalized()
	
	entity.velocity += (
		direction * acceleration * delta
	)
	
	if dir.length() > 0.01:
		last_direction = dir
		
	
	var horizontal := Vector3(
		entity.velocity.x,
		0,
		entity.velocity.z
	)
	
	if horizontal.length() > max_speed:
		horizontal = (
			horizontal.normalized() * max_speed
		)
	
	entity.velocity.x = horizontal.x
	entity.velocity.z = horizontal.z

func apply_friction(delta: float):
	if entity == null:
		push_error("MovementComponent: entity is null. Did you forget setup()?")
		return
	var horizontal := Vector3(
		entity.velocity.x,
		0,
		entity.velocity.z
	)
	
	horizontal = horizontal.move_toward(
		Vector3.ZERO,
		friction * delta
	)
	
	entity.velocity.x = horizontal.x
	entity.velocity.z = horizontal.z
	
	if horizontal.length() < 0.01:
		last_direction = Vector3.ZERO

func jump():
	if entity.is_on_floor():
		entity.velocity.y = jump_force

func move(direction: Vector3, delta: float) -> void:
	var dir := direction.normalized()
	
	entity.velocity.x = move_toward(
		entity.velocity.x,
		dir.x * max_speed,
		acceleration * delta
	)
	
	entity.velocity.z = move_toward(
		entity.velocity.z,
		dir.z * max_speed,
		acceleration * delta
	)
