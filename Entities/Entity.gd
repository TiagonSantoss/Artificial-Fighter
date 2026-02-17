class_name Entity
extends CharacterBody3D

var definition: EntityDefinition
var controller: Controller
var health: int

func _init(start_position: Vector3i, entity_definition: EntityDefinition) -> void:
	definition = entity_definition
	
	texture = definition.texture
	modulate = definition.color
	
	health = definition.max_health
	
	if definition.controller:
		controller = definition.controller.duplicate()

func move(direction: Vector3, _delta: float) -> void:
	input_direction = direction

func apply_movement(delta: float) -> void:
	var target_velocity = input_direction * speed
	
	if input_direction != Vector3.ZERO:
		velocity.x = move_toward(velocity.x, target_velocity.x, acceleration * delta)
		velocity.z = move_toward(velocity.z, target_velocity.z, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, friction * delta)
		velocity.z = move_toward(velocity.z, 0, friction * delta)

	move_and_slide()
