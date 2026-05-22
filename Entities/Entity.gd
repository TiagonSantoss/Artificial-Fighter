class_name Entity
extends CharacterBody3D

enum Team {
	PLAYER,
	ALLY,
	ENEMY
}

var definition: EntityDefinition
var controller: Controller

var gravity: float = float(
	ProjectSettings.get_setting(
		"physics/3d/default_gravity"
	)
)

var entity_id: int
var team: Team
var initialized := false

var grid_position: Vector3i

@onready var camera_pivot: Marker3D = $CameraPivot
@onready var sprite: AnimatedSprite3D = $AnimatedSprite3D
@onready var weapon_socket: Node3D = $CameraPivot/WeaponSocket

@onready var health_component: HealthComponent = $Components/HealthComponent
@onready var movement_component: MovementComponent = $Components/MovementComponent
@onready var animation_component: AnimationComponent = $Components/AnimationComponent
@onready var weapon_component: WeaponComponent = $Components/WeaponComponent

func setup(start_position: Vector3,entity_definition: EntityDefinition) -> void:
	definition = entity_definition
	
	global_position = start_position
	
	entity_id = definition.entity_id
	team = definition.team
	
	grid_position = Grid.world_to_grid(global_position)
	
	if definition.controller:
		controller = definition.controller.duplicate()
	
	health_component.setup(self)
	health_component.configure(definition.max_health)
	
	movement_component.setup(self)
	movement_component.configure(definition)
	
	animation_component.setup(self)
	animation_component.set_sprite(sprite)
	animation_component.configure_visuals(definition)
	
	weapon_component.setup(self)
	weapon_component.set_weapon_socket(weapon_socket)
	
	initialized = true
	
	if definition.starting_weapon:
		weapon_component.equip_weapon(
			definition.starting_weapon
		)
	
	health_component.died.connect(_on_died)

func _physics_process(delta: float) -> void:
	if not initialized:
		return
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	var had_movement := false
	
	if controller:
		var actions = controller.get_actions(
			self,
			delta
		)
		
		for action in actions:
			if action is MovementAction:
				had_movement = true
			action.execute(self, delta)
		
		var target = controller.get_aim_target(self)
		if target != null:
			weapon_component.look_at_target(target)
		
	if not had_movement:
		movement_component.apply_friction(delta)
	
	move_and_slide()
	
	var new_grid := Grid.world_to_grid(
		global_position
	)
	if new_grid != grid_position:
		grid_position = new_grid
	
	animation_component.update_animation()

func is_friendly_to(other_team) -> bool:
	match team:
		Team.PLAYER, Team.ALLY:
			match other_team:
				Team.PLAYER, Team.ALLY:
					return true
	
	return false

func on_projectile_hit(projectile) -> bool:
	if is_friendly_to(projectile.source_team):
		return false
	
	var damageVar: int = (
		projectile.damage *
		projectile.source_entity
			.weapon_component
			.get_damage_multiplier()
	)
	
	health_component.damage(damageVar)
	
	return true

func damage(amount: int) -> void:
	health_component.damage(amount)

func _on_died() -> void:
	queue_free()
