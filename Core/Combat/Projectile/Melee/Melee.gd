class_name Melee
extends Node3D

const HIT_VFX_SCENE = preload("res://Utils/HitVFX.tscn")

var definition: MeleeDefinition

var lifetime_left := 0.0
var damage_multiplier := 1.0
var knock_multiplier := 1.0

var source_team
var source_entity: Entity
var already_hit := {}

var position_offset := Vector3.ZERO
var strike_direction := Vector3.FORWARD

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
):
	definition = melee_definition
	damage_multiplier = dmg_mult
	knock_multiplier = knock_mult
	
	source_entity = source
	source_team = source_t
	strike_direction = dir.normalized()
	
	# Make the strike follow the player's movement offset
	global_position = start_position
	if source_entity:
		position_offset = global_position - source_entity.global_position
	
	lifetime_left = definition.lifetime
	
	# Configure the Area3D's CollisionShape3D dynamically
	var area_shape := hitbox.get_node_or_null("CollisionShape3D")
	if area_shape and area_shape.shape:
		area_shape.shape = area_shape.shape.duplicate(true)
		
		if area_shape.shape is SphereShape3D:
			area_shape.shape.radius = definition.radius
	
	# Rotate the slash visual and hitbox to face the aim direction
	var angle := atan2(strike_direction.x, strike_direction.z)
	global_rotation.y = angle
	
	_apply_visuals()
	
	# Enable monitoring right away since this object was just instantiated to strike
	hitbox.monitoring = true

func build_hit_data() -> HitData:
	var hit = HitData.new()
	hit.damage = definition.damage
	hit.damage_mult = damage_multiplier
	hit.knockback = definition.knockback
	hit.knockback_multiplier = knock_multiplier
	hit.direction = strike_direction
	hit.source_entity = source_entity
	hit.source_team = source_team
	hit.projectile = self
	hit.lifetime = lifetime_left
	return hit

func _physics_process(delta):
	lifetime_left -= delta
	if lifetime_left <= 0.0:
		queue_free()
		return
	
	# Keep the slash attached to the moving player
	if is_instance_valid(source_entity):
		position_offset += strike_direction * definition.speed * delta
		global_position = source_entity.global_position + position_offset
	

func _on_hitbox_area_entered(area: Area3D) -> void:
	if not hitbox.monitoring:
		return
	
	if area == hitbox or already_hit.has(area):
		return
	
	print(area)
	
	# Look for the Projectile script on the parent node (since the child is the Area3D)
	var incoming_projectile: Projectile = null
	if area.get_parent() is Projectile:
		incoming_projectile = area.get_parent() as Projectile
	
	# --- PARRYING A PROJECTILE ---
	if incoming_projectile != null:
		# Prevent parrying your own team's projectiles
		if is_instance_valid(source_entity) and incoming_projectile.source_team == source_team:
			return
			
		var hit_pos = incoming_projectile.global_position
		already_hit[area] = true
		already_hit[incoming_projectile] = true
		
		_spawn_hit_vfx(hit_pos, Vector3.UP, definition.damage * 2.0)
		trigger_hitstop(0.06)
		
		var enemy = incoming_projectile.source_entity
		if is_instance_valid(enemy) and enemy.has_method("apply_hit"):
			var parry_hit = HitData.new()
			parry_hit.damage = definition.damage
			parry_hit.damage_mult = damage_multiplier
			parry_hit.knockback = definition.knockback * 1.2
			parry_hit.knockback_multiplier = knock_multiplier
			
			parry_hit.direction = (enemy.global_position - global_position).normalized()
			parry_hit.source_entity = source_entity
			parry_hit.source_team = source_team
			parry_hit.hit_position = enemy.global_position
			parry_hit.hit_normal = -parry_hit.direction
			
			enemy.apply_hit(parry_hit)
			
		incoming_projectile.queue_free()
		return
	
	# --- PARRYING AN ENEMY MELEE SWING (WEAPON CLASH) ---
	# (Applying the same parent logic if Melee also uses a child Area3D)
	var incoming_melee: Melee = null
	if area.get_parent() is Melee:
		incoming_melee = area.get_parent() as Melee
		
	if incoming_melee != null:
		if is_instance_valid(source_entity) and incoming_melee.source_team != source_team:
			already_hit[area] = true
			already_hit[incoming_melee] = true
			
			_spawn_hit_vfx(global_position, Vector3.UP, definition.damage)
			trigger_hitstop(0.05)
			
			var enemy = incoming_melee.source_entity
			if is_instance_valid(enemy) and enemy.has_method("apply_hit"):
				var clash_hit = HitData.new()
				clash_hit.damage = definition.damage
				clash_hit.damage_mult = damage_multiplier
				clash_hit.knockback = definition.knockback
				clash_hit.knockback_multiplier = knock_multiplier
				
				clash_hit.direction = (enemy.global_position - global_position).normalized()
				clash_hit.source_entity = source_entity
				clash_hit.source_team = source_team
				clash_hit.hit_position = enemy.global_position
				clash_hit.hit_normal = -clash_hit.direction
				
				enemy.apply_hit(clash_hit)
			return

func _on_hitbox_body_entered(body: Node3D) -> void:
	if not hitbox.monitoring:
		return
		
	if body == source_entity or already_hit.has(body):
		return
		
	# Team filtering
	if body.has_method("get_team"):
		if source_entity.is_friendly_to(body.team):
			return
			
	# DAMAGEABLE ENTITIES
	if body.has_method("apply_hit"):
		var hit_data := build_hit_data()
		hit_data.hit_position = body.global_position
		hit_data.hit_normal = (global_position - body.global_position).normalized()
		
		body.apply_hit(hit_data)
		_spawn_hit_vfx(hit_data.hit_position, hit_data.hit_normal, definition.damage)
		already_hit[body] = true
		
		trigger_hitstop(0.04)
		return
		
	# WORLD COLLISION
	if body.is_in_group("world"):
		var hit_pos = global_position + (strike_direction * definition.radius)
		_spawn_hit_vfx(hit_pos, -strike_direction, definition.damage)
		already_hit[body] = true
		return

func _apply_visuals():
	sprite.sprite_frames = definition.sprite_frames
	sprite.texture_filter = definition.texture_filter
	sprite.modulate = definition.modulate
	sprite.billboard = definition.billboard
	sprite.scale = definition.sprite_scale
	sprite.play(definition.default_animation)

func _spawn_hit_vfx(pos: Vector3, normal: Vector3, _damage: float) -> void:
	var vfx := HIT_VFX_SCENE.instantiate()
	get_tree().current_scene.add_child(vfx)
	vfx.global_position = pos
	vfx.rotation.y = randf() * TAU
	if vfx is Node3D and normal != Vector3.ZERO:
		vfx.look_at(pos + normal, Vector3.UP)
	vfx.play()

func trigger_hitstop(duration_seconds: float) -> void:
	var duration_ms := int(duration_seconds * 1000.0)
	OS.delay_msec(duration_ms)
