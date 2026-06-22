class_name Weapon
extends Node3D

const PROJECTILE_SCENE = preload("res://Core/Combat/Projectile/Projectile.tscn")

var definition: WeaponDefinition
var can_fire := true
var wielder: Entity

var damage_multiplier := 1.0
var knockback_multiplier := 1.0
var pierce_multiplier := 1.0

var bulletml_emitter: Node = null

@onready var sprite = $AnimatedSprite3D
@onready var muzzle = $Muzzle

func setup(weapon_definition, owner_entity):
	definition = weapon_definition
	wielder = owner_entity
	damage_multiplier = weapon_definition.damage_multiplier
	pierce_multiplier = weapon_definition.pierce_multiplier
	knockback_multiplier = weapon_definition.knockback_multiplier
	
	if is_instance_valid(wielder):
		bulletml_emitter = wielder.get_node_or_null("BulletMLBulletEmitter")
	_apply_visuals()


func _apply_visuals():
	sprite.sprite_frames = definition.sprite_frames
	sprite.texture_filter = definition.texture_filter
	sprite.modulate = definition.modulate
	sprite.billboard = definition.billboard
	sprite.scale = definition.sprite_scale
	sprite.position = definition.sprite_offset
	sprite.play(definition.default_animation)

func fire(direction: Vector3):
	if wielder == null:
		push_error("Weapon fired without wielder (setup missing)")
		return
		
	if not can_fire:
		return
		
	can_fire = false
	
	# --- IF BULLETML EXISTS, USE IT ---
	if is_instance_valid(bulletml_emitter):
		# Pass the wielder entity context to the emitter metadata safely
		print("started firing bulletML")
		bulletml_emitter.set_meta("wielder", wielder)
		bulletml_emitter.start()
		
	# --- OTHERWISE, FIRE STANDARD PROJECTILE ---
	else:
		var projectile: Projectile = PROJECTILE_SCENE.instantiate()
		get_tree().current_scene.add_child(projectile)
		
		projectile.setup(
			muzzle.global_position,
			direction,
			definition.projectile,
			wielder,
			wielder.team,
			damage_multiplier,
			knockback_multiplier
		)
	
	# Recoil and fire-rate cooldowns apply to both methods perfectly!
	var recoil_dir := -direction.normalized()
	wielder.movement_component.apply_impulse(recoil_dir * definition.recoil)
	
	await get_tree().create_timer(definition.fire_rate).timeout
	can_fire = true

func update_visual_aim(dir: Vector3) -> void:
	# Rotate the weapon root node on the floor plane
	var angle_y := atan2(-dir.z, dir.x)
	global_rotation.y = angle_y
	
	# Prevent the 2D sprite from flipping upside down when aiming left
	sprite.flip_v = dir.x < 0
