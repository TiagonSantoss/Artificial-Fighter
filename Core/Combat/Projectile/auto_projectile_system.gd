extends Node3D

var active_projectiles: Array[Projectile] = []

var space_state: PhysicsDirectSpaceState3D
var ray := PhysicsRayQueryParameters3D.new()
var hit_data := HitData.new()


func _ready():
	space_state = get_world_3d().direct_space_state

	# Configure your global ray settings once to save execution time
	ray.collide_with_areas = true
	ray.collide_with_bodies = true


func _handle_projectile_hit(
	projectile: Projectile, collider: Node, hit_pos: Vector3, hit_norm: Vector3
) -> bool:
	# 🟢 FIXED CRASH CHECK: If the source entity was freed (e.g. boss died), safely clear the reference
	if not is_instance_valid(projectile.source_entity):
		projectile.source_entity = null

	if projectile.already_hit.has(collider):
		return false

	# Team check
	if collider.has_method("get_team"):
		if is_instance_valid(projectile.source_entity):
			if projectile.source_entity.is_friendly_to(collider.get_team()):
				return false
		elif projectile.source_team == collider.get_team():
			return false

	# Build hit data safely
	hit_data.damage = projectile.definition.damage
	hit_data.damage_mult = projectile.damage_multiplier
	hit_data.knockback = projectile.definition.knockback
	hit_data.knockback_multiplier = projectile.knockback_multiplier
	hit_data.stun_duration = projectile.stun_duration
	hit_data.direction = projectile.velocity.normalized()

	# Since we cleared it above if it was dead, this is now 100% safe to assign
	hit_data.source_entity = projectile.source_entity

	hit_data.source_team = projectile.source_team
	hit_data.projectile = projectile
	hit_data.lifetime = projectile.lifetime_left
	hit_data.hit_position = hit_pos
	hit_data.hit_normal = hit_norm

	# Apply damage directly if supported
	if collider.has_method("apply_hit"):
		collider.apply_hit(hit_data)
	elif collider.get_parent() and collider.get_parent().has_method("apply_hit"):
		collider.get_parent().apply_hit(hit_data)

	#AutoHitVFXPool.spawn(hit_pos, hit_norm)

	projectile.already_hit[collider] = true
	projectile.remaining_pierce -= 1

	if projectile.remaining_pierce <= 0:
		release(projectile)
		return true  # Signal that projectile was deleted

	return false


func spawn(request: ProjectileRequest) -> Projectile:
	var p := Projectile.new()
	p.setup(request)
	p.active_index = active_projectiles.size()
	active_projectiles.append(p)
	return p


func release(projectile: Projectile) -> void:
	var idx := projectile.active_index
	var last := active_projectiles.size() - 1
	if idx != last:
		active_projectiles[idx] = active_projectiles[last]
		active_projectiles[idx].active_index = idx
	active_projectiles.pop_back()
	projectile.active_index = -1


func _physics_process(delta: float) -> void:
	# print("Active Projectiles:", active_projectiles.size())
	for i in range(active_projectiles.size() - 1, -1, -1):
		_update_projectile(active_projectiles[i], delta)


func _update_projectile(projectile: Projectile, delta: float) -> void:
	# 1. LIFETIME / PHYSICS UPDATES
	projectile.velocity.y -= projectile.definition.gravity * delta
	projectile.lifetime_left -= delta

	if projectile.lifetime_left <= 0.0:
		release(projectile)
		return

	projectile.velocity.x *= projectile.drag_factor
	projectile.velocity.z *= projectile.drag_factor

	var start := projectile.position
	var end := start + projectile.velocity * delta

	# 2. UNIFIED RAYCAST COLLISION (Hits entities AND world surfaces)
	ray.from = start
	ray.to = end
	ray.exclude = projectile.exclude

	var hit := space_state.intersect_ray(ray)

	# 🟢 FIXED SAFE CHECK: Fetch as a basic Variant first, check validity, then cast safely
	if projectile.has_meta("source_behavior_component"):
		var component_raw = projectile.get_meta("source_behavior_component", null)
		if is_instance_valid(component_raw):
			var component = component_raw as WeaponBehaviorComponent
			if component:
				component.update_live_projectile(projectile, delta)

	if not hit.is_empty():
		var collider: Node = hit.collider
		projectile.position = hit.position

		# Check if the entity hit can take damage
		if (
			collider.has_method("apply_hit")
			or (collider.get_parent() and collider.get_parent().has_method("apply_hit"))
		):
			var was_deleted = _handle_projectile_hit(projectile, collider, hit.position, hit.normal)
			if was_deleted:
				return

		# var parent_node: Node3D = collider.get_parent()
		#
		# # if parent_node is Melee:
		# # 	var guard_area := parent_node as Melee
		# # 	var total_incoming_dmg := projectile.definition.damage * projectile.damage_multiplier
		# # 	if guard_area.source_team != projectile.source_team:
		# # 		var _was_parried = guard_area.process_projectile_impact(
		# # 			hit.position, projectile.source_entity, total_incoming_dmg
		# # 		)
		# #
		# # 		release(projectile)
		# # 		return

		# If it didn't hit a damageable target, or had pierce leftover, execute bounce/wall code
		if projectile.remaining_bounces > 0:
			projectile.velocity = projectile.velocity.bounce(hit.normal)
			projectile.remaining_bounces -= 1
			projectile.position += hit.normal * 0.05
			return

		# Structural wall impact fallback
		#AutoHitVFXPool.spawn(hit.position, hit.normal)
		release(projectile)
		return

	# No collisions occurred, move forward cleanly
	projectile.position = end
