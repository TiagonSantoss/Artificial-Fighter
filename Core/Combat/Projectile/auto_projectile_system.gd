extends Node3D

enum HitOutcome { IGNORED, HIT, DESTROYED }
const MAX_PASS_THROUGH := 4

var active_projectiles: Array[Projectile] = []

var space_state: PhysicsDirectSpaceState3D
var ray := PhysicsRayQueryParameters3D.new()
# var hit_data := HitData.new()


func _ready():
	space_state = get_world_3d().direct_space_state

	# Configure your global ray settings once to save execution time
	ray.collide_with_areas = true
	ray.collide_with_bodies = true


func _handle_projectile_hit(
	projectile: Projectile, target: Node, hit_pos: Vector3, hit_norm: Vector3
) -> HitOutcome:
	if not is_instance_valid(projectile.source_entity):
		projectile.source_entity = null

	if projectile.already_hit.has(target):
		return HitOutcome.IGNORED

	if target.has_method("get_team"):
		var target_team = target.get_team()
		if is_instance_valid(projectile.source_entity):
			if projectile.source_entity.is_friendly_to(target_team):
				return HitOutcome.IGNORED
		elif projectile.source_team == target_team:
			return HitOutcome.IGNORED

	var hit_data := HitData.new()
	hit_data.damage = projectile.definition.damage
	hit_data.damage_mult = projectile.damage_multiplier
	hit_data.knockback = projectile.definition.knockback
	hit_data.knockback_multiplier = projectile.knockback_multiplier
	hit_data.stun_duration = projectile.stun_duration
	hit_data.direction = projectile.velocity.normalized()
	hit_data.source_entity = projectile.source_entity
	hit_data.source_team = projectile.source_team
	hit_data.projectile = projectile
	hit_data.lifetime = projectile.lifetime_left
	hit_data.hit_position = hit_pos
	hit_data.hit_normal = hit_norm

	var result = target.apply_hit(hit_data)
	projectile.already_hit[target] = true

	if result == Entity.HitResult.NONE:
		return HitOutcome.IGNORED

	projectile.remaining_pierce -= 1
	if projectile.remaining_pierce <= 0:
		release(projectile)
		return HitOutcome.DESTROYED

	return HitOutcome.HIT


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


func _get_hit_target(collider: Node) -> Node:
	if collider.has_method("apply_hit"):
		return collider
	var parent := collider.get_parent()
	if parent != null and parent.has_method("apply_hit"):
		return parent
	return null


func _update_projectile(projectile: Projectile, delta: float) -> void:
	projectile.velocity.y -= projectile.definition.gravity * delta
	projectile.lifetime_left -= delta

	if projectile.lifetime_left <= 0.0:
		release(projectile)
		return

	projectile.velocity.x *= projectile.drag_factor
	projectile.velocity.z *= projectile.drag_factor

	# Moved up so behavior changes to velocity apply this same frame
	if projectile.has_meta("source_behavior_component"):
		var component_raw = projectile.get_meta("source_behavior_component", null)
		if is_instance_valid(component_raw):
			var component = component_raw as WeaponBehaviorComponent
			if component:
				component.update_live_projectile(projectile, delta)

	var start := projectile.position
	var end := start + projectile.velocity * delta

	for _i in MAX_PASS_THROUGH:
		ray.from = start
		ray.to = end
		ray.exclude = projectile.exclude

		ray.collision_mask = (
			(1 << (Game.LAYER_WORLD - 1))
			| (1 << (Game.LAYER_PLAYER - 1))
			| (1 << (Game.LAYER_ENEMY - 1))
		)

		var hit := space_state.intersect_ray(ray)
		if hit.is_empty():
			break

		var collider: Node = hit.collider
		var target := _get_hit_target(collider)

		if target != null:
			var outcome := _handle_projectile_hit(projectile, target, hit.position, hit.normal)
			if outcome == HitOutcome.DESTROYED:
				return
			# IGNORED (friendly / already hit / i-frames) or pierced: fly through it
			projectile.exclude.append(hit.rid)
			start = hit.position
			continue

		if collider is Area3D:
			# pickups, trigger zones, interaction areas: not solid
			projectile.exclude.append(hit.rid)
			start = hit.position
			continue

		# Solid world geometry
		if projectile.remaining_bounces > 0:
			projectile.velocity = projectile.velocity.bounce(hit.normal)
			projectile.remaining_bounces -= 1
			projectile.position = hit.position + hit.normal * 0.05
			return

		release(projectile)
		return

	projectile.position = end
