extends Node3D

var active_projectiles: Array[Projectile] = []

var space_state: PhysicsDirectSpaceState3D
var ray := PhysicsRayQueryParameters3D.new()

var hit_data := HitData.new()


func _ready():
	space_state = get_world_3d().direct_space_state
	
	#ProjectileRenderer.render(active_projectiles)

func _closest_point_on_segment(p: Vector3, a: Vector3, b: Vector3) -> Vector3:
	var ab := b - a
	var length_sq := ab.length_squared()
	
	if length_sq < 0.00001:
		return a
	
	var t := clampf((p - a).dot(ab) / length_sq, 0.0, 1.0)
	return a + ab * t

func _handle_projectile_hit(projectile: Projectile, collider: Node) -> void:
	if projectile.already_hit.has(collider):
		return
	
	# team check
	if collider.has_method("get_team"):
		if is_instance_valid(projectile.source_entity):
			if projectile.source_entity.is_friendly_to(collider.get_team()):
				return
	
	# build hit data
	hit_data.damage = projectile.definition.damage
	hit_data.damage_mult = projectile.damage_multiplier
	
	hit_data.knockback = projectile.definition.knockback
	hit_data.knockback_multiplier = projectile.knockback_multiplier
	
	hit_data.direction = projectile.velocity.normalized()
	hit_data.source_entity = projectile.source_entity
	hit_data.source_team = projectile.source_team
	hit_data.projectile = projectile
	
	# apply damage
	if collider.has_method("apply_hit"):
		collider.apply_hit(hit_data)
	
	projectile.already_hit[collider] = true
	projectile.remaining_pierce -= 1
	
	if projectile.remaining_pierce <= 0:
		release(projectile)

func update_render(projectiles: Array[Projectile], mm: MultiMesh) -> void:
	for i in projectiles.size():
		var p := projectiles[i]
		
		var transform = Transform3D(
			Basis.IDENTITY,
			p.position
		)
		
		mm.set_instance_transform(i, transform)
		
		# frame + optional data
		mm.set_instance_custom_data(i, Color(
			float(p.frame),
			0.0,
			0.0,
			0.0
		))

func spawn(request: ProjectileRequest) -> Projectile:
	var p := Projectile.new()
	p.setup(request)
	
	p.active_index = active_projectiles.size()
	active_projectiles.append(p)
	
	return p

func on_collision(area: Node) -> void:
	var incoming_projectile: Projectile = null
	
	if area != null:
		incoming_projectile = area.get_meta("projectile", null)
	
	if incoming_projectile == null:
		return
	
	_handle_projectile_hit(incoming_projectile, area)

func release(projectile: Projectile) -> void:
	var idx := projectile.active_index
	var last := active_projectiles.size() - 1
	
	if idx != last:
		active_projectiles[idx] = active_projectiles[last]
		active_projectiles[idx].active_index = idx
	
	active_projectiles.pop_back()
	projectile.active_index = -1
	
	#AutoProjectilePool.release(projectile)


func _physics_process(delta: float) -> void:
	print("Active Projectiles:", active_projectiles.size())
	for i in range(active_projectiles.size() - 1, -1, -1):
		_update_projectile(active_projectiles[i], delta)
	
	# render pass (MultiMesh)
	

func _update_projectile(projectile: Projectile, delta: float) -> void:
	# -------------------------
	# LIFETIME / PHYSICS
	# -------------------------
	projectile.velocity.y -= projectile.definition.gravity * delta
	projectile.lifetime_left -= delta
	
	if projectile.lifetime_left <= 0.0:
		release(projectile)
		return
	
	# drag only horizontal
	projectile.velocity.x *= projectile.drag_factor
	projectile.velocity.z *= projectile.drag_factor
	
	var start := projectile.position
	var end := start + projectile.velocity * delta
	
	# -------------------------
	# ANIMATION (MULTIMESH FRIENDLY)
	# -------------------------
	#projectile.animation_time += delta
	
	#var fps := projectile.definition.animation_fps
	#var frame := int(projectile.animation_time * fps) % projectile.definition.total_frames
	
	# store for renderer (NOT AnimatedSprite3D anymore)
	#projectile.frame = frame
	
	# -------------------------
	# WORLD COLLISION (RAY)
	# -------------------------
	
	ray.from = start
	ray.to = end
	ray.exclude = projectile.exclude
	
	var hit := space_state.intersect_ray(ray)
	
	if not hit.is_empty():
		projectile.position = hit.position
		
		if projectile.remaining_bounces > 0:
			projectile.velocity = projectile.velocity.bounce(hit.normal)
			projectile.remaining_bounces -= 1
			
			projectile.position += hit.normal * 0.05
			return
		
		AutoHitVFXPool.spawn(hit.position, hit.normal)
		release(projectile)
		return
	
	# -------------------------
	# ENTITY COLLISION (GRID OPT)
	# -------------------------
	
	var nearby := EntityGrid.query_segment(start, end)
	
	for entity in nearby:
		if entity == projectile.source_entity:
			continue
		
		if projectile.already_hit.has(entity):
			continue
		
		# team check
		if entity.has_method("get_team"):
			if is_instance_valid(projectile.source_entity):
				if projectile.source_entity.is_friendly_to(entity.get_team()):
					continue
			elif projectile.source_team == entity.get_team():
				continue
		
		var closest = _closest_point_on_segment(entity.position, start, end)
		
		var radius = projectile.definition.radius + entity.hit_radius
		
		if closest.distance_squared_to(entity.position) > radius * radius:
			continue
		
		# -------------------------
		# HIT DATA
		# -------------------------
		hit_data.damage = projectile.definition.damage
		hit_data.damage_mult = projectile.damage_multiplier
		
		hit_data.knockback = projectile.definition.knockback
		hit_data.knockback_multiplier = projectile.knockback_multiplier
		
		hit_data.direction = projectile.velocity.normalized()
		
		hit_data.source_entity = projectile.source_entity
		hit_data.source_team = projectile.source_team
		
		hit_data.projectile = projectile
		hit_data.lifetime = projectile.lifetime_left
		
		hit_data.hit_position = closest
		hit_data.hit_normal = (entity.position - closest).normalized()
		
		entity.apply_hit(hit_data)
		
		AutoHitVFXPool.spawn(hit_data.hit_position, hit_data.hit_normal)
		
		projectile.already_hit[entity] = true
		projectile.remaining_pierce -= 1
		
		if projectile.remaining_pierce <= 0:
			release(projectile)
			return
	
	# -------------------------
	# FINAL POSITION UPDATE (CPU → renderer sync)
	# -------------------------
	projectile.position = end
