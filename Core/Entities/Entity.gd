class_name Entity
extends CharacterBody3D

enum Team {
	PLAYER,
	ALLY,
	ENEMY
}

enum HitResult {
	NONE,
	CONSUME,
	PIERCE,
	BOUNCE,
	REFLECT
}

const HIT_VFX_SCENE = preload("res://Utils/HitVFX.tscn")

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

var current_interactable: Node = null

@onready var camera_pivot: Marker3D = $CameraPivot
@onready var sprite: AnimatedSprite3D = $AnimatedSprite3D
@onready var weapon_socket: Marker3D = $OrbitSocket/WeaponSocket
@onready var orbit_socket: Marker3D = $OrbitSocket
@onready var fake_shadow: Sprite3D = $FakeShadow

@onready var health_component: HealthComponent = $Components/HealthComponent
@onready var movement_component: MovementComponent = $Components/MovementComponent
@onready var animation_component: AnimationComponent = $Components/AnimationComponent
@onready var weapon_component: EntityWeaponComponent = $Components/WeaponComponent
@onready var visual_effects_component: VisualEffectsComponent = $Components/VisualEffectsComponent
@onready var effects_component: EffectsComponent = $Components/EffectsComponent


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
	weapon_socket.position = Vector3.ZERO
	orbit_socket.position = Vector3.ZERO
	weapon_component.set_sockets(weapon_socket, orbit_socket)
	
	visual_effects_component.setup(self)
	visual_effects_component.set_sprite(sprite)
	
	effects_component.setup(self)
	
	initialized = true
	
	if definition.starting_weapon:
		weapon_component.equip_weapon(
			definition.starting_weapon
		)
	
	health_component.died.connect(_on_died)

func is_friendly_to(other_team: Team) -> bool:
	if team == Team.ENEMY:
		return other_team == Team.ENEMY

	return other_team != Team.ENEMY

func apply_hit(hit: HitData):
	if hit.source_team == team:
		return HitResult.NONE
	
	if health_component:
		health_component.damage(hit.get_final_damage())
		visual_effects_component.flash_red(0.1)
	
	if movement_component:
		movement_component.apply_impulse(hit.direction * hit.get_final_knockback())

func _on_died() -> void:
	#_spawn_hit_vfx()
	queue_free()

func get_team():
	return team

func _ready():
	$InteractionArea.area_entered.connect(_on_interaction_entered)
	$InteractionArea.area_exited.connect(_on_interaction_exited)

func _on_interaction_entered(area: Area3D) -> void:
	if area.has_method("interact"):
		current_interactable = area

func _on_interaction_exited(area: Area3D) -> void:
	if area == current_interactable:
		current_interactable = null

func _physics_process(delta: float) -> void:
	if not initialized:
		return
	
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
		
		
		controller.update_aim(self)
		
		if controller.aim_target != null:
			weapon_component.update_aim(controller.aim_target)
	
	if not had_movement:
		movement_component.apply_friction(delta)
	
	movement_component.update(delta)
	
	#visual_effects_component.update(delta)
	effects_component.update(delta)
	
	weapon_component.update(delta)
	
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	move_and_slide()
	
	#var new_grid := Grid.world_to_grid(
	#	global_position
	#)
	
	#if new_grid != grid_position:
	#	grid_position = new_grid
	
	animation_component.update_animation()

func _spawn_hit_vfx() -> void:
	var vfx := HIT_VFX_SCENE.instantiate()
	get_tree().current_scene.add_child(vfx)
	vfx.reparent(self)
	vfx.rotation.y = randf() * TAU
	
	#if vfx is Node3D:
	#	vfx.look_at(pos + normal, Vector3.UP)
	
	vfx.play()
