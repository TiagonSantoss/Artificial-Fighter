class_name WorldItem
extends Area3D

signal picked_up(instance: ItemInstance)

enum State { IDLE, TOSS, MAGNET }

@export_group("Pickup Settings")
@export var collection_distance := 0.6
@export var arc_strength := 2.5  # Lateral curve strength
@export var magnet_speed := 12.0  # Speed factor for pull

@export_group("Lifetime")
@export var can_despawn := true
@export var lifetime := 15.0  # Seconds before auto-despawn

@export_group("Physics")
@export var toss_gravity := 18.0  # Renamed to prevent Area3D property conflict

var instance: ItemInstance
var state := State.IDLE

# Toss parameters
var toss_velocity := Vector3.ZERO

# Magnet parameters
var target_entity: Entity = null
var magnet_start_pos := Vector3.ZERO
var magnet_side_dir := Vector3.ZERO
var magnet_t := 0.0

# Hover bobbing
var hover_time := 0.0
var initial_y := 0.0

@onready var sprite: Sprite3D = $Sprite3D
@onready var spark: GPUParticles3D = $Spark
@onready var trail: GPUParticles3D = $TrailParticles


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	initial_y = global_position.y

	if instance != null:
		_apply_instance()


func _process(delta: float) -> void:
	# Billboard sprite to camera
	var cam := get_viewport().get_camera_3d()
	if cam and sprite:
		sprite.look_at(cam.global_position)

	match state:
		State.IDLE:
			_process_idle(delta)
		State.TOSS:
			_process_toss(delta)
		State.MAGNET:
			_process_magnet(delta)


func _process_idle(delta: float) -> void:
	hover_time += delta
	# Subtle floating animation
	sprite.position.y = sin(hover_time * 3.0) * 0.15

	# Auto-despawn timer
	if can_despawn:
		lifetime -= delta
		if lifetime <= 0.0:
			queue_free()


func _process_toss(delta: float) -> void:
	toss_velocity.y -= toss_gravity * delta
	global_position += toss_velocity * delta

	# Stop toss when hitting ground height
	if global_position.y <= initial_y:
		global_position.y = initial_y
		state = State.IDLE


func _process_magnet(delta: float) -> void:
	if not is_instance_valid(target_entity):
		state = State.IDLE
		if trail:
			trail.emitting = false
		return

	var target_pos := target_entity.global_position + Vector3(0, 0.8, 0)
	var total_dist := magnet_start_pos.distance_to(target_pos)

	# Increment progress along path
	magnet_t += (delta * magnet_speed) / maxf(total_dist, 1.0)
	magnet_t = clamp(magnet_t, 0.0, 1.0)

	# 1. Linear interpolation toward target position
	var current_linear_pos := magnet_start_pos.lerp(target_pos, magnet_t)

	# 2. Apply lateral arc offset (peaks halfway through journey)
	var arc_offset := magnet_side_dir * (sin(magnet_t * PI) * arc_strength)

	global_position = current_linear_pos + arc_offset

	# Check for pickup completion
	if global_position.distance_to(target_pos) < collection_distance or magnet_t >= 1.0:
		_collect_item(target_entity)


func push_item(impulse: Vector3) -> void:
	toss_velocity = impulse
	initial_y = global_position.y
	state = State.TOSS


func _on_body_entered(body: Node) -> void:
	if instance == null or state == State.MAGNET:
		return

	if body is Entity:
		target_entity = body
		magnet_start_pos = global_position
		magnet_t = 0.0

		# Calculate a lateral direction vector relative to target
		var to_target = (body.global_position - global_position).normalized()
		magnet_side_dir = to_target.cross(Vector3.UP).normalized()

		# Randomly select left or right curve direction
		if randf() > 0.5:
			magnet_side_dir = -magnet_side_dir

		if magnet_side_dir.length_squared() < 0.01:
			magnet_side_dir = Vector3.RIGHT

		state = State.MAGNET
		if trail:
			trail.emitting = true


func _collect_item(body: Entity) -> void:
	# Attempt equipping to weapon component first
	if body.weapon_component != null:
		if body.weapon_component.equipped_weapon.equip_behavior(instance):
			_finalize_pickup()
			return

	# Fallback to general inventory
	if body.has_method("inventory") or "inventory" in body:
		if body.inventory.add(instance):
			_finalize_pickup()
			return

	# If inventory full, abort magnet phase
	state = State.IDLE
	if trail:
		trail.emitting = false


func _finalize_pickup() -> void:
	picked_up.emit(instance)
	queue_free()


func _apply_instance() -> void:
	var def := instance.definition
	if def == null:
		return

	if def.icon:
		sprite.texture = def.icon

	sprite.scale = Vector3.ONE * 0.5

	if spark:
		spark.emitting = true


func set_instance(new_instance: ItemInstance) -> void:
	instance = new_instance
	if is_inside_tree():
		_apply_instance()
