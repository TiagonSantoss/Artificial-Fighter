class_name Projectile
extends Node3D

enum HitResult {
	NONE,
	CONSUME,
	PIERCE,
	BOUNCE,
	REFLECT
}

const HIT_VFX_SCENE = preload("res://Utils/HitVFX.tscn")

var definition: ProjectileDefinition

var remaining_pierce := 0
var remaining_bounces := 0
var lifetime_left := 0.0
var damage_multiplier := 1.0
var knock_multiplier := 1.0

var velocity := Vector3.ZERO
var source_team
var source_entity: Entity
var already_hit := {}

var is_active := true

@onready var sprite: AnimatedSprite3D = $AnimatedSprite3D
@onready var hitbox: Area3D = $Area3D
@onready var shape_cast: ShapeCast3D = $ShapeCast3D

func setup(
	start_position: Vector3,
	dir: Vector3,
	projectile_definition: ProjectileDefinition,
	source: Entity,
	source_t,
	dmg_mult: float,
	knock_mult: float
	
):
	is_active = true
	if shape_cast.shape:
		shape_cast.shape = shape_cast.shape.duplicate(true)
	
	var area_shape := hitbox.get_node_or_null("CollisionShape3D")
	if area_shape and area_shape.shape:
		area_shape.shape = area_shape.shape.duplicate(true)
		
	#if projectile_definition == null:
	#	push_warning("Projectile setup was passed a null definition! Loading default config asset.")
	#	definition = load("res://assets/definitions/projectiles/bullet.tres")
	#else:
	definition = projectile_definition
	
	damage_multiplier = dmg_mult
	knock_multiplier = knock_mult
	
	global_position = start_position
	
	velocity = dir.normalized() * definition.speed
	
	remaining_pierce = definition.pierce + 1
	remaining_bounces = definition.bounce_count
	lifetime_left = definition.lifetime
	
	source_entity = source
	source_team = source_t
	if source != null:
		source_team = source_t
		shape_cast.add_exception(source)
		
		for child in source.get_children():
			if child is CollisionObject3D:
				shape_cast.add_exception(child)
	else:
		# Fallback team allocation if no wielder exists (e.g. environmental hazard)
		source_team = source_t #if source_t != null else 0
	
	var sphere := shape_cast.shape as SphereShape3D
	
	if sphere:
		sphere.radius = definition.radius
	
	print(source_entity)
	
	#shape_cast.add_exception(source)
	#for child in source.get_children():
	#		if child is CollisionObject3D:
	#			shape_cast.add_exception(child)
	
	var angle := atan2(dir.x, dir.z)
	global_rotation.y = angle
	
	_apply_visuals()

func build_hit_data() -> HitData:
	var hit = HitData.new()
	
	hit.damage = definition.damage
	hit.damage_mult = damage_multiplier
	hit.knockback = definition.knockback
	hit.knockback_multiplier = knock_multiplier
	
	hit.direction = velocity.normalized()
	
	hit.source_entity = source_entity
	hit.source_team = source_team
	
	hit.projectile = self
	
	hit.lifetime = lifetime_left
	
	return hit

func _physics_process(delta):
	if definition == null:
		return
	velocity.y -= (
		definition.gravity * delta
	)
	lifetime_left -= delta
	
	if lifetime_left <= 0.0:
		#queue_free()
		deactivate()
		return
	
	# drag should not affect gravity
	var horizontal := Vector3(
		velocity.x,
		0,
		velocity.z
	)
	
	horizontal *= exp(-definition.drag * delta)
	
	velocity.x = horizontal.x
	velocity.z = horizontal.z
	
	var motion: Vector3 = velocity * delta
	
	shape_cast.global_position = global_position
	shape_cast.target_position = motion #Vector3.FORWARD * motion.length()
	
	shape_cast.force_shapecast_update()
	
	
	if shape_cast.is_colliding():
		for i in range(shape_cast.get_collision_count()):
			if is_queued_for_deletion():
				return
			
			var collider = (shape_cast.get_collider(i))
			
			if collider == null:
				continue
			
			# don't hit self
			if collider == source_entity:
				continue
			
			# don't hit same target twice
			if already_hit.has(collider):
				continue
			
			# team filtering
			#if collider.has_method("get_team"):
				#if source_entity.is_friendly_to(collider.team):
					#continue
			
			var hit_data := build_hit_data()
			
			hit_data.hit_position = (shape_cast.get_collision_point(i))
			hit_data.hit_normal = (shape_cast.get_collision_normal(i))
			
			# WORLD COLLISION
			if collider.is_in_group("world"):
				_spawn_hit_vfx(hit_data.hit_position, hit_data.hit_normal, hit_data.damage)
				if remaining_bounces > 0:
					velocity = velocity.bounce(hit_data.hit_normal)
					remaining_bounces -= 1
					global_position += hit_data.hit_normal * 0.05
					_spawn_hit_vfx(hit_data.hit_position, hit_data.hit_normal, hit_data.damage)
					return
				
				deactivate()
				return
			
			# DAMAGEABLE
			if collider.has_method("apply_hit"):
				collider.apply_hit(hit_data)
				
				trigger_hitstop(0.06) # 60 milliseconds freeze
				
				_spawn_hit_vfx(hit_data.hit_position, hit_data.hit_normal, hit_data.damage)
				
				already_hit[collider] = true
				remaining_pierce -= 1
				
				if remaining_pierce <= 0:
					deactivate()
					return
			#TO DO, PARRIES
			#if collider is Projectile:
			#	#if collider == self:
			#	#	continue
			#	
			#	collider.queue_free()
			#	queue_free()
			#	return
	
	
	if is_queued_for_deletion():
		return
	
	global_position += motion
	# rotate to movement
	if velocity.length_squared() > 0.01:
		var dir := velocity.normalized()
		
		# Calculate the angle on the horizontal XZ plane
		var angle := atan2(dir.x, dir.z)
		
		# Rotate the entire projectile to face the target
		global_rotation.y = angle
		
		# If the punch is moving left relative to the screen/world,
		# you can flip the sprite or change the animation variant here
		if dir.x < 0:
			sprite.flip_h = true
			#sprite.play("punch_left")
		else:
			sprite.flip_h = false
			#sprite.play("punch_right")

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
	#vfx.scale = Vector3.ONE * clamp(damage * 0.08 * damage_multiplier, 0.5, damage * 0.08 * damage_multiplier)
	vfx.rotation.y = randf() * TAU
	
	# optional: face surface direction
	if vfx is Node3D:
		vfx.look_at(pos + normal, Vector3.UP)
	
	vfx.play()

var next_allowed_hitstop_time := 0.0

func trigger_hitstop(duration_seconds: float) -> void:
	var current_time := Time.get_unix_time_from_system()
	
	if current_time < next_allowed_hitstop_time:
		return
		
	next_allowed_hitstop_time = current_time + duration_seconds
	
	# Convert seconds (e.g. 0.06) to milliseconds (60)
	var duration_ms := int(duration_seconds * 1000.0)
	
	# This halts the engine execution entirely for a crisp frame freeze
	OS.delay_msec(duration_ms)

func deactivate() -> void:
	is_active = false
	# Teleport the bullet far away out of the player's view while it sleeps
	global_position = Vector3(9999, -9999, 9999)


func _on_visible_on_screen_notifier_3d_screen_exited() -> void:
	if not is_active:
		return
		
	deactivate()
