class_name Entity
extends CharacterBody3D

var definition: EntityDefinition
var controller: Controller

var health: int
var move_speed: float
var max_speed: float
var acceleration: float
var friction: float

@onready var sprite: AnimatedSprite3D = $AnimatedSprite3D

func setup(start_position: Vector3, entity_definition: EntityDefinition) -> void:
	definition = entity_definition
	global_position = start_position
	
	health = definition.max_health
	move_speed = definition.move_speed
	max_speed = definition.max_speed
	acceleration = definition.acceleration
	friction = definition.friction
	
	if definition.controller:
		controller = definition.controller.duplicate()
	
	_apply_visuals()

func _apply_visuals() -> void:
	sprite.sprite_frames = definition.sprite_frames
	sprite.texture_filter = definition.texture_filter
	sprite.modulate = definition.modulate
	sprite.billboard = definition.billboard
	sprite.play(definition.default_animation)

func _physics_process(delta: float) -> void:
	var had_movement := false
	
	if controller:
		var actions = controller.get_actions(self, delta)
		
		for action in actions:
			if action is MovementAction:
				had_movement = true
			
			action.execute(self, delta)

	# Apply friction if no movement input
	var horizontal := Vector3(velocity.x, 0, velocity.z)
	horizontal = horizontal.move_toward(
		Vector3.ZERO,
		friction * delta
	)
	velocity.x = horizontal.x
	velocity.z = horizontal.z

	#Clamp speed
	var horizontal_speed := Vector3(velocity.x, 0, velocity.z)
	print(horizontal_speed)
	
	if horizontal_speed.length() > max_speed:
		horizontal_speed = horizontal_speed.normalized() * max_speed
		velocity.x = horizontal_speed.x
		velocity.z = horizontal_speed.z

	move_and_slide()
