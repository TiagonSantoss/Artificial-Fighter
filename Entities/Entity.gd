class_name Entity
extends CharacterBody3D

enum Team {
	PLAYER,
	ALLY,
	ENEMY
}

var definition: EntityDefinition
var controller: Controller

var health: int
var move_speed: float
var max_speed: float
var acceleration: float
var friction: float
var entity_id: int
var team

var grid_position: Vector3i
var equipped_weapon: Weapon

const WEAPON_SCENE = preload("res://Game/Combat/Weapon/Weapon.tscn")

@onready var weapon_socket = $WeaponSocket
@onready var sprite: AnimatedSprite3D = $AnimatedSprite3D

func setup(start_position: Vector3, entity_definition: EntityDefinition) -> void:
	definition = entity_definition
	global_position = start_position
	
	health = definition.max_health
	move_speed = definition.move_speed
	max_speed = definition.max_speed
	acceleration = definition.acceleration
	friction = definition.friction
	entity_id = definition.entity_id
	team = definition.team
	
	global_position = start_position
	
	grid_position = Grid.world_to_grid(global_position)
	
	if definition.controller:
		controller = definition.controller.duplicate()
	
	if definition.starting_weapon:
		equip_weapon(definition.starting_weapon)
	
	_apply_visuals()

func is_blocked(_pos: Vector3i) -> bool:
	return false 

func is_friendly_to(other_team) -> bool:
	match team:
		Team.PLAYER, Team.ALLY:
			match other_team:
				Team.PLAYER, Team.ALLY:
					return true

	return false

func _apply_visuals() -> void:
	sprite.sprite_frames = definition.sprite_frames
	sprite.texture_filter = definition.texture_filter
	sprite.modulate = definition.modulate
	sprite.billboard = definition.billboard
	sprite.scale = definition.sprite_scale
	sprite.play(definition.default_animation)

func equip_weapon(weapon_definition):
	if equipped_weapon:
		equipped_weapon.queue_free()
	
	equipped_weapon = WEAPON_SCENE.instantiate()
	
	weapon_socket.add_child(equipped_weapon)
	
	equipped_weapon.setup(weapon_definition, self)

func take_damage(amount):
	health -= amount
	print(health)
	
	if health <= 0:
		queue_free()

func on_projectile_hit(projectile) -> bool:
	if is_friendly_to(projectile.source_team):
		return false
	
	take_damage(
	projectile.damage *
	projectile.source_entity.equipped_weapon.damage_multiplier
	)
	return true 

func get_mouse_world():
	var cam = get_viewport().get_camera_3d()
	var mouse = get_viewport().get_mouse_position()
	
	var ray_origin = cam.project_ray_origin(mouse)
	var ray_dir = cam.project_ray_normal(mouse)
	
	var ground = Plane(Vector3.UP, global_position)
	
	return ground.intersects_ray(ray_origin, ray_dir)

func _physics_process(delta: float) -> void:
	var _had_movement := false
	
	if controller:
		var actions = controller.get_actions(self, delta)
		
		for action in actions:
			if action is MovementAction:
				_had_movement = true
			action.execute(self, delta)
	
	if not _had_movement:
		var horizontal := Vector3(velocity.x, 0, velocity.z)
		horizontal = horizontal.move_toward(Vector3.ZERO, friction * delta)
		velocity.x = horizontal.x
		velocity.z = horizontal.z
	
	var horizontal_speed := Vector3(velocity.x, 0, velocity.z)
	if horizontal_speed.length() > max_speed:
		horizontal_speed = horizontal_speed.normalized() * max_speed
		velocity.x = horizontal_speed.x
		velocity.z = horizontal_speed.z
	
	move_and_slide()
	
	grid_position = Grid.world_to_grid(global_position)
	
	#if controller is CompanionController:
		#print("WORLD:", global_position)
		#print("GRID:", grid_position)
	
	var target = get_mouse_world()
	if target:
		weapon_socket.look_at(target, Vector3.UP)
