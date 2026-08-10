class_name Melee
extends Node3D

const HIT_VFX_SCENE = preload("res://Utils/HitVFX.tscn")
const CHIP_DAMAGE_RATIO := 0.25
const DEFAULT_PARRY_WINDOW := 0.03

var definition: MeleeDefinition
var lifetime_left := 0.0
var damage_multiplier := 1.0
var knock_multiplier := 1.0

var source_team
var source_entity: Entity
var already_hit := {}

var position_offset := Vector3.ZERO
var strike_direction := Vector3.FORWARD

var parry_window_left := 0.0
var is_in_hitstop := false

@onready var sprite: AnimatedSprite3D = $AnimatedSprite3D
@onready var hitbox: Area3D = $Area3D


func _ready() -> void:
	hitbox.area_entered.connect(_on_hitbox_area_entered)
	hitbox.body_entered.connect(_on_hitbox_body_entered)


func setup(
	start_position: Vector3,
	dir: Vector3,
	melee_definition: MeleeDefinition,
	source: Entity,
	source_t,
	dmg_mult: float,
	knock_mult: float
) -> void:
	definition = melee_definition
	damage_multiplier = dmg_mult
	knock_multiplier = knock_mult
	source_entity = source
	source_team = source_t
	strike_direction = dir.normalized()

	global_position = start_position
	if is_instance_valid(source_entity):
		position_offset = global_position - source_entity.global_position

	lifetime_left = definition.lifetime

	var area_shape := hitbox.get_node_or_null("CollisionShape3D")
	if area_shape and area_shape.shape is SphereShape3D:
		area_shape.shape = area_shape.shape.duplicate(true)
		area_shape.shape.radius = definition.radius

	global_rotation.y = atan2(strike_direction.x, strike_direction.z)
	_apply_visuals()
	hitbox.monitoring = true

	parry_window_left = DEFAULT_PARRY_WINDOW


func _physics_process(delta: float) -> void:
	lifetime_left -= delta
	if lifetime_left <= 0.0:
		queue_free()
		return

	if parry_window_left > 0.0:
		parry_window_left = maxf(0.0, parry_window_left - delta)

	# print(parry_window_left)

	if is_instance_valid(source_entity):
		position_offset += strike_direction * definition.speed * delta
		global_position = source_entity.global_position + position_offset


# --- MELEE VS MELEE (CLASHING ONLY) ---


func _on_hitbox_area_entered(area: Area3D) -> void:
	if not hitbox.monitoring or area == hitbox or already_hit.has(area):
		return

	var target_parent := area.get_parent()
	if target_parent is Melee:
		var incoming_melee := target_parent as Melee
		if _is_friendly(incoming_melee):
			return

		var is_perfect_parry := parry_window_left > 0.0

		if is_perfect_parry:
			# --- PERFECT PARRY VS MELEE ---
			print("MELEE PERFECT PARRY!")
			incoming_melee.queue_free()
			_trigger_hitstop(6.0)  # ~7 frames: punchy enough for a parry without dragging
		else:
			# --- STANDARD CLASH ---
			print("STANDARD CLASH")
			_register_hit([area, incoming_melee])
			_trigger_hitstop(0.06)  # ~3-4 frames: crisp fighting-game hitpause


# --- MELEE VS ENTITIES & WORLD ---


func _on_hitbox_body_entered(body: Node3D) -> void:
	if not hitbox.monitoring or body == source_entity or already_hit.has(body):
		return

	if _is_friendly(body):
		return

	if body.has_method("apply_hit"):
		_register_hit([body])
		var hit_data := create_hit_data(body.global_position)
		body.apply_hit(hit_data)

		return

	if body.is_in_group("world"):
		_register_hit([body])


# --- PUBLIC API FOR PROJECTILE PARRIES ---
# The Projectile Manager calls this when a raycast hits our Area3D!


func process_projectile_impact(
	projectile_pos: Vector3, enemy_source: Entity, incoming_damage: float
) -> bool:
	var is_perfect_parry := parry_window_left > 0.0

	if is_perfect_parry:
		# --- PERFECT PARRY ---
		_trigger_hitstop(6.0)
		print("PERFECT PARRY!")
		return true
	else:
		# --- STANDARD BLOCK ---
		# Normal block visual/sound feedback (no counter-attack)
		if is_instance_valid(source_entity) and source_entity.has_method("apply_hit"):
			var chip_hit := HitData.new()
			chip_hit.damage = incoming_damage * CHIP_DAMAGE_RATIO
			chip_hit.damage_mult = 1.0
			chip_hit.hit_position = projectile_pos
			chip_hit.source_entity = enemy_source
			chip_hit.attack_source = self

			source_entity.apply_hit(chip_hit)

		print("Standard Block - Took ", incoming_damage * CHIP_DAMAGE_RATIO, " chip damage.")
		return false


# --- HELPER FUNCTIONS ---


func create_hit_data(target_pos: Vector3, knockback_scale: float = 1.0) -> HitData:
	var hit := HitData.new()
	hit.damage = definition.damage
	hit.damage_mult = damage_multiplier
	hit.knockback = definition.knockback * knockback_scale
	hit.knockback_multiplier = knock_multiplier
	hit.direction = (
		(target_pos - global_position).normalized()
		if target_pos != Vector3.ZERO
		else strike_direction
	)
	hit.source_entity = source_entity if is_instance_valid(source_entity) else null
	hit.source_team = source_team
	hit.attack_source = self
	hit.lifetime = lifetime_left
	hit.hit_position = target_pos
	hit.hit_normal = -hit.direction
	return hit


func _is_friendly(target: Node) -> bool:
	if not is_instance_valid(source_entity):
		return false
	if "source_team" in target and target.source_team == source_team:
		return true
	if target.has_method("get_team") and source_entity.has_method("is_friendly_to"):
		return source_entity.is_friendly_to(target.get_team())
	return false


func _register_hit(nodes: Array) -> void:
	for node in nodes:
		already_hit[node] = true


func _apply_visuals() -> void:
	sprite.sprite_frames = definition.sprite_frames
	sprite.texture_filter = definition.texture_filter
	sprite.modulate = definition.modulate
	sprite.billboard = definition.billboard
	sprite.scale = definition.sprite_scale
	sprite.play(definition.default_animation)


## UNUSED FUNC
# func _spawn_hit_vfx(pos: Vector3, normal: Vector3, _damage: float) -> void:
# 	var vfx := HIT_VFX_SCENE.instantiate()
# 	get_tree().current_scene.add_child(vfx)
# 	vfx.global_position = pos
# 	vfx.rotation.y = randf() * TAU
# 	if vfx is Node3D and normal != Vector3.ZERO and not normal.is_equal_approx(Vector3.ZERO):
# 		vfx.look_at(pos + normal, Vector3.UP)
# 	vfx.play()


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


func _exit_tree() -> void:
	# Safety net: Guarantee time scale is restored if this node is destroyed mid-hitstop
	if is_in_hitstop and Engine.time_scale < 1.0:
		Engine.time_scale = 1.0
