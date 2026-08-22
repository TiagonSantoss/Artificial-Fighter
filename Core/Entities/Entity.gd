class_name Entity
extends CharacterBody3D

enum Team { PLAYER, ALLY, ENEMY }

enum HitResult { NONE, CONSUME, PIERCE, BOUNCE, REFLECT }

const HIT_VFX_SCENE = preload("res://Utils/HitVFX.tscn")
const CHIP_DAMAGE_RATIO := 0.25
const DEFAULT_PARRY_WINDOW := 0.2  # Slightly more forgiving for player bodies than melee clashes

var is_blocking := false
var parry_window_left := 0.0

var definition: EntityDefinition
var controller: Controller

var gravity: float = float(ProjectSettings.get_setting("physics/3d/default_gravity"))

var entity_id: int
var team: Team
var initialized := false

var grid_position: Vector3i

var current_interactable: Node = null

var is_in_hitstop := false

var is_dashing := false

var is_invincible: bool = false
var iframe_duration: float = 1.0
var stun_left := 0.0

@onready var camera_pivot: Marker3D = $CameraPivot

@onready var sprite: AnimatedSprite3D = $AnimatedSprite3D
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D

@onready var weapon_socket: Marker3D = $OrbitSocket/WeaponSocket
@onready var orbit_socket: SpringArm3D = $OrbitSocket
@onready var hit_box_shape: CollisionShape3D = get_node_or_null("hitbox")

@onready var emitter: FmodEventEmitter3D = $Emitter

@onready var health_component: HealthComponent = $Components/HealthComponent
@onready var movement_component: MovementComponent = $Components/MovementComponent
@onready var animation_component: AnimationComponent = $Components/AnimationComponent
@onready var weapon_component: EntityWeaponComponent = $Components/WeaponComponent
@onready var visual_effects_component: VisualEffectsComponent = $Components/VisualEffectsComponent
@onready var effects_component: EffectsComponent = $Components/EffectsComponent
@onready var audio_component: EntityAudioComponent = $Components/AudioComponent
@onready var cards_component: CardsComponent = $Components/CardsComponent
@onready var accessories_component: AccessoriesComponent = $Components/AccessoriesComponent
@onready var rank_component: RankComponent = $Components/RankComponent
@onready var currency_component: CurrencyComponent = $Components/CurrencyComponent


func setup(start_position: Vector3, entity_definition: EntityDefinition) -> void:
	definition = entity_definition
	global_position = start_position

	entity_id = definition.entity_id
	team = definition.team
	grid_position = Grid.world_to_grid(global_position)

	if definition.controller:
		controller = definition.controller.duplicate()

	animation_component.setup(self)
	animation_component.set_visual_nodes(sprite, mesh_instance)
	var active_visuals := animation_component.configure_visuals(definition)

	# hitbox shenaningans
	if is_instance_valid(hit_box_shape):
		hit_box_shape.position = definition.hitbox_offset

		if definition.hitbox_shape_override:
			hit_box_shape.shape = definition.hitbox_shape_override.duplicate()
		else:
			var box_shape := BoxShape3D.new()
			box_shape.size = definition.hitbox_size
			hit_box_shape.shape = box_shape

	visual_effects_component.setup(self)
	visual_effects_component.setup_visuals(active_visuals)

	health_component.setup(self)
	health_component.configure(definition.max_health)

	movement_component.setup(self)
	movement_component.configure(definition)

	weapon_component.setup(self)
	orbit_socket.position = Vector3.ZERO
	weapon_component.set_sockets(weapon_socket, orbit_socket)

	effects_component.setup(self)
	accessories_component.setup(self)
	audio_component.setup(self)

	rank_component.setup(self)
	currency_component.setup(self)

	await get_tree().physics_frame

	initialized = true

	if definition.starting_weapon:
		weapon_component.equip_weapon(definition.starting_weapon)

	health_component.died.connect(_on_died)


func start_dodge(duration: float) -> void:
	is_dashing = true
	# Wait for the i-frames to finish
	await get_tree().create_timer(duration, false).timeout
	is_dashing = false


func is_friendly_to(other_team: Team) -> bool:
	if team == Team.ENEMY:
		return other_team == Team.ENEMY

	return other_team != Team.ENEMY


func apply_hit(hit: HitData):
	if is_invincible:
		return HitResult.NONE

	if hit.source_team == team:
		return HitResult.NONE

	if is_dashing:
		return HitResult.NONE

	if controller is CompanionController:
		return HitResult.NONE

	if is_blocking:
		if parry_window_left > 0.0:
			audio_component.play_sfx("ParrySound")
			visual_effects_component.flash_blue()
			_trigger_hitstop(0.1)

			GState.enemy_parried.emit(25.0)
			return HitResult.CONSUME

		else:
			# print("ENTITY BLOCKED!")
			var chip_damage = hit.get_final_damage() * CHIP_DAMAGE_RATIO

			if health_component:
				health_component.damage(chip_damage)

			audio_component.play_sfx("BlockSound")
			visual_effects_component.flash_gray()
			if movement_component:
				movement_component.apply_impulse(hit.direction * hit.get_final_knockback() * 0.5)

			return HitResult.CONSUME

	if health_component:
		health_component.damage(hit.get_final_damage())
		visual_effects_component.flash_red()
		audio_component.play_sfx("EntityHurt")

		start_iframes()

		var incoming_stun = hit.stun_duration
		stun_left = maxf(stun_left, incoming_stun)

	if movement_component:
		movement_component.apply_impulse(hit.direction * hit.get_final_knockback())

	return HitResult.CONSUME


func start_iframes():
	is_invincible = true

	visual_effects_component.start_blinking(iframe_duration)

	await get_tree().create_timer(iframe_duration).timeout

	is_invincible = false


func _on_died() -> void:
	var drop_amount = definition.get_randomized_drop()

	if drop_amount > 0 and definition.drop_currency_def:
		var coin_data = definition.drop_currency_def.create_currency_drop(drop_amount)

		WorldItemSpawner.drop(coin_data, global_position)

	queue_free()


func get_team():
	return team


func _ready():
	$InteractionArea.area_entered.connect(_on_interaction_entered)
	$InteractionArea.area_exited.connect(_on_interaction_exited)

	GState.enemy_damaged.connect(_on_enemy_damaged)
	GState.enemy_parried.connect(_on_enemy_parried)


func _on_enemy_damaged(points: float):
	add_style_points(points)


func _on_enemy_parried(points: float):
	add_style_points(points)


func add_style_points(points: float):
	rank_component.add_points(points)


func _on_interaction_entered(area: Area3D) -> void:
	if area.has_method("interact"):
		current_interactable = area

	if team != Team.PLAYER or team != Team.ALLY:
		return

	var world_item = area as WorldItem
	if not world_item:
		world_item = area.get_parent() as WorldItem

	if world_item and world_item.instance is CurrencyItemInstance:
		var coin_data = world_item.instance as CurrencyItemInstance
		var currency_name = coin_data.get_currency_type()

		GameAutoLoad.add_money(currency_name, coin_data.amount)
		print(GameAutoLoad.wallet.get_amount("Cash Cards"))

		# audio_component.play_sfx("CoinPickup")

		world_item.queue_free()


func _on_interaction_exited(area: Area3D) -> void:
	if area == current_interactable:
		current_interactable = null


func trigger_guard() -> void:
	is_blocking = true


func _physics_process(delta: float) -> void:
	if not initialized:
		return

	var had_movement := false

	var was_blocking = is_blocking
	is_blocking = false

	if controller:
		var actions = controller.get_actions(self, delta)
		for action in actions:
			if action is MovementAction:
				had_movement = true
			action.execute(self, delta)

		controller.update_aim(self)
		if controller.aim_target != null:
			weapon_component.update_aim(controller.aim_target)

			var aim_pos = controller.aim_target
			aim_pos.y = orbit_socket.global_position.y

			var look_away_pos = (
				orbit_socket.global_position + (orbit_socket.global_position - aim_pos)
			)

			if orbit_socket.global_position.distance_to(look_away_pos) > 0.01:
				orbit_socket.look_at(look_away_pos, Vector3.UP)

	if is_blocking and not was_blocking:
		parry_window_left = DEFAULT_PARRY_WINDOW
		print("PARRY WINDOW STARTED")
		visual_effects_component.set_blocking_visuals(true)

	# 3. Tick down the parry window (or reset it if we let go of block)
	if is_blocking and parry_window_left > 0.0:
		parry_window_left = maxf(0.0, parry_window_left - delta)
	elif not is_blocking:
		parry_window_left = 0.0
		visual_effects_component.set_blocking_visuals(false)

	if not had_movement:
		movement_component.apply_friction(delta)

	movement_component.update(delta)
	effects_component.update(delta)
	weapon_component.update(delta)

	if not is_on_floor():
		velocity.y -= gravity * delta

	move_and_slide()

	if is_instance_valid(mesh_instance) and mesh_instance.visible:
		animation_component.rotate_mesh_towards_velocity(mesh_instance, velocity, delta)

	animation_component.update_animation()


func _trigger_hitstop(duration_seconds: float) -> void:
	# Prevent overlapping hitstops from breaking the time scale reset
	if is_in_hitstop or Engine.time_scale < 1.0:
		return

	is_in_hitstop = true
	Engine.time_scale = 0.05

	# Real-world timer that ignores Engine.time_scale
	await get_tree().create_timer(duration_seconds, true, false, true).timeout

	# Only reset if we are still the active hitstop handler
	if is_in_hitstop:
		Engine.time_scale = 1.0
		is_in_hitstop = false
