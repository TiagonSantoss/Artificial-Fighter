extends BulletMLBulletInstance
# This inherits all variables like _angle, _speed, and the built-in tweens automatically!

var real_3d_projectile: Projectile = null
var base_y_height := 0.5

func _ready() -> void:
	super._ready()
	
	real_3d_projectile = ProjectilePool.get_projectile()
	
	# CRITICAL FIX 1: If the pool returned null, create a fallback on the spot
	if real_3d_projectile == null:
		var fallback_scene = load("res://Core/Combat/Projectile/Projectile.tscn")
		real_3d_projectile = fallback_scene.instantiate()
	
	# CRITICAL FIX 2: Ensure the real 3D projectile is added to the active scene layout tree!
	if real_3d_projectile.get_parent() != null:
		real_3d_projectile.get_parent().remove_child(real_3d_projectile)
	get_tree().current_scene.add_child(real_3d_projectile)
	
	var wielder_entity: Entity = null
	var spawn_parent = get_parent()
	if spawn_parent and spawn_parent.has_meta("wielder"):
		wielder_entity = spawn_parent.get_meta("wielder") as Entity
		
	var spawn_pos_3d := Vector3(global_position.x, 0.5, global_position.y)
	var travel_direction_3d := Vector3(velocity.x, 0, velocity.y).normalized()
	if travel_direction_3d == Vector3.ZERO:
		travel_direction_3d = Vector3.FORWARD
	
	# --- THE DYNAMIC WEAPON LOOKUP ---
	var active_bullet_definition: ProjectileDefinition = null
	if is_instance_valid(wielder_entity) and wielder_entity.has_method("get_current_projectile_definition"):
		active_bullet_definition = wielder_entity.get_current_projectile_definition()
		
	if active_bullet_definition == null:
		active_bullet_definition = load("res://assets/definitions/projectiles/bullet.tres")
	# ---------------------------------
	
	# Extract multipliers safely without scope crashes
	var dmg_m := 1.0
	var knock_m := 1.0
	if is_instance_valid(wielder_entity) and is_instance_valid(wielder_entity.weapon_component):
		var w_comp = wielder_entity.weapon_component
		var current_weapon = w_comp.equipped_weapon if "equipped_weapon" in w_comp else w_comp.get_node_or_null("Weapon")
		if is_instance_valid(current_weapon):
			dmg_m = current_weapon.damage_multiplier
			knock_m = current_weapon.knockback_multiplier
	
	if wielder_entity:
		real_3d_projectile.setup(
			spawn_pos_3d,
			travel_direction_3d, 
			active_bullet_definition, 
			wielder_entity,
			wielder_entity.team,
			dmg_m,
			knock_m
		)
	else:
		real_3d_projectile.setup(
			spawn_pos_3d,
			travel_direction_3d, 
			active_bullet_definition, 
			null,
			0, 
			1.0,
			1.0
		)

func _physics_process(delta: float) -> void:
	# 1. Let the base plugin calculate move_and_slide() on the 2D grid plane first
	super._physics_process(delta)
	
	# 2. If our real 3D projectile is valid and flying, update its position to match the ghost
	if is_instance_valid(real_3d_projectile) and real_3d_projectile.is_active:
		real_3d_projectile.global_position.x = global_position.x
		real_3d_projectile.global_position.z = global_position.y
		
		# Match visual billboard rolling using the internal _angle variable
		if rotates:
			# The plugin's calculation adds an angular offset (-90 deg), so we read the true _angle
			real_3d_projectile.sprite.rotation.z = _angle
	else:
		# If the 3D projectile hit something in the 3D world and deactivated, kill the ghost
		destroy()

# Triggered when the BulletML runner finishes or runs a vanish action
func destroy() -> void:
	if is_instance_valid(real_3d_projectile):
		real_3d_projectile.deactivate()
		
	# Call the plugin's native clean up method (emits signals and runs queue_free)
	super.destroy()
