class_name Melee
extends Node3D

const CHIP_DAMAGE_RATIO := 0.25

var definition: MeleeDefinition
var lifetime_left := 0.0
var damage_multiplier := 1.0
var knock_multiplier := 1.0

var source_team
var source_entity: Entity
var already_hit := {}

var position_offset := Vector3.ZERO
var strike_direction := Vector3.FORWARD

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
	if is_instance_valid(area_shape):
		area_shape.position = definition.hitbox_offset

		if definition.hitbox_shape_override:
			area_shape.shape = definition.hitbox_shape_override.duplicate()
		else:
			var box_shape := BoxShape3D.new()
			box_shape.size = definition.hitbox_size
			area_shape.shape = box_shape

	global_rotation.y = atan2(strike_direction.x, strike_direction.z)
	_apply_visuals()
	hitbox.monitoring = true


func _physics_process(delta: float) -> void:
	lifetime_left -= delta
	if lifetime_left <= 0.0:
		queue_free()
		return

	if is_instance_valid(source_entity):
		position_offset += strike_direction * definition.speed * delta
		global_position = source_entity.global_position + position_offset


func _on_hitbox_area_entered(area: Area3D) -> void:
	if not hitbox.monitoring or area == hitbox or already_hit.has(area):
		return

	var target_parent := area.get_parent()
	if target_parent is Melee:
		var incoming_melee := target_parent as Melee
		if _is_friendly(incoming_melee):
			return

		_register_hit([area, incoming_melee])
		_trigger_hitstop(0.06)

		if (
			is_instance_valid(incoming_melee.source_entity)
			and incoming_melee.source_entity.has_method("apply_hit")
		):
			var clash_hit := create_hit_data(incoming_melee.global_position, 0.5)
			clash_hit.damage *= CHIP_DAMAGE_RATIO
			incoming_melee.source_entity.apply_hit(clash_hit)

		call_deferred("queue_free")


func _on_hitbox_body_entered(body: Node3D) -> void:
	if not hitbox.monitoring or body == source_entity or already_hit.has(body):
		return

	if _is_friendly(body):
		return

	if body.has_method("apply_hit"):
		_register_hit([body])
		var hit_data := create_hit_data(body.global_position)
		body.apply_hit(hit_data)

		if body.is_in_group("enemies"):
			GState.enemy_damaged.emit(23.0)
		return

	if body.is_in_group("world"):
		_register_hit([body])


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
	hit.stun_duration = definition.stun_duration
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
	# sprite.play(definition.default_animation)


func _trigger_hitstop(duration_seconds: float) -> void:
	if is_in_hitstop or Engine.time_scale < 1.0:
		return

	is_in_hitstop = true
	Engine.time_scale = 0.05

	await get_tree().create_timer(duration_seconds, true, false, true).timeout

	if is_in_hitstop:
		Engine.time_scale = 1.0
		is_in_hitstop = false


func _exit_tree() -> void:
	if is_in_hitstop and Engine.time_scale < 1.0:
		Engine.time_scale = 1.0
