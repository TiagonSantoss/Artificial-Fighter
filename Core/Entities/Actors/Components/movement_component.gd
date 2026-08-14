class_name MovementComponent
extends EntityComponent

const BLOCK_SPEED_MULTIPLIER := 0.4

var move_speed: float
var max_speed: float
var acceleration: float
var friction: float
var jump_force: float

var last_direction := Vector3.ZERO
var movement_velocity := Vector3.ZERO
var external_velocity := Vector3.ZERO


func configure(definition: EntityDefinition):
	move_speed = definition.move_speed
	max_speed = definition.max_speed
	acceleration = definition.acceleration
	friction = definition.friction
	jump_force = definition.jump_force


func apply_movement(direction: Vector3, delta: float) -> void:
	if entity.get("is_dashing"):
		return

	var current_max_speed = max_speed
	var current_acceleration = acceleration

	if entity.get("is_blocking"):
		current_max_speed *= BLOCK_SPEED_MULTIPLIER
		current_acceleration *= BLOCK_SPEED_MULTIPLIER

	if direction.length() > 0.01:
		last_direction = direction.normalized()

	var dir := direction.normalized()

	movement_velocity += (dir * current_acceleration * delta)

	var horizontal := Vector3(movement_velocity.x, 0, movement_velocity.z)

	if horizontal.length() > current_max_speed:
		horizontal = (horizontal.normalized() * current_max_speed)

	movement_velocity.x = horizontal.x
	movement_velocity.z = horizontal.z


func apply_friction(delta: float):
	var horizontal := Vector3(movement_velocity.x, 0, movement_velocity.z)

	horizontal = horizontal.move_toward(Vector3.ZERO, friction * delta)

	movement_velocity.x = horizontal.x
	movement_velocity.z = horizontal.z

	if horizontal.length() < 0.01:
		last_direction = Vector3.ZERO


func jump():
	if entity.is_on_floor():
		entity.velocity.y = jump_force


func apply_impulse(force: Vector3):
	external_velocity += force


func update(delta: float):
	entity.velocity.x = movement_velocity.x + external_velocity.x
	entity.velocity.z = movement_velocity.z + external_velocity.z

	external_velocity.x = move_toward(external_velocity.x, 0.0, friction * delta)
	external_velocity.z = move_toward(external_velocity.z, 0.0, friction * delta)


func apply_dash(direction: Vector3, force: float) -> void:
	external_velocity = direction * force
	movement_velocity = Vector3.ZERO
	last_direction = direction
