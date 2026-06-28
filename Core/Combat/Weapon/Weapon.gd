class_name Weapon
extends Node3D

const PROJECTILE_SCENE = preload("res://Core/Combat/Projectile/Projectile.tscn")
const MELEE_SCENE = preload("res://Core/Combat/Projectile/Melee/Melee.tscn")

var definition: WeaponDefinition
var can_fire := true
var wielder: Entity

var damage_multiplier := 1.0
var knockback_multiplier := 1.0
var pierce_multiplier := 1.0

@onready var sprite = $AnimatedSprite3D
@onready var muzzle = $Muzzle

func setup(weapon_definition, owner_entity):
	assert(weapon_definition != null, "Weapon initialized with a null definition!")
	
	if weapon_definition.is_melee:
		assert(weapon_definition.melee != null, "Melee weapon is missing its MeleeDefinition!")
	else:
		assert(weapon_definition.projectile != null, "Ranged weapon is missing its ProjectileDefinition!")
	
	definition = weapon_definition
	wielder = owner_entity
	damage_multiplier = weapon_definition.damage_multiplier
	pierce_multiplier = weapon_definition.pierce_multiplier
	knockback_multiplier = weapon_definition.knockback_multiplier
	_apply_visuals()


func _apply_visuals():
	sprite.sprite_frames = definition.sprite_frames
	sprite.texture_filter = definition.texture_filter
	sprite.modulate = definition.modulate
	sprite.billboard = definition.billboard
	sprite.scale = definition.sprite_scale
	sprite.position = definition.sprite_offset
	sprite.play(definition.default_animation)

func use_weapon(direction: Vector3):
	if definition.is_melee:
		swing(direction)
	else:
		fire(direction)

func fire(direction: Vector3):
	if wielder == null:
		push_error("Weapon fired without wielder (setup missing)")
		return
	
	if not can_fire:
		return
	
	can_fire = false
	
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
	
	var recoil_dir := -direction.normalized()
	wielder.movement_component.apply_impulse(recoil_dir * definition.recoil)
	
	await get_tree().create_timer(definition.fire_rate).timeout
	can_fire = true

func swing(direction: Vector3):
	if wielder == null:
		push_error("Weapon swung without wielder (setup missing)")
		return
		
	if not can_fire:
		return
		
	can_fire = false
	
	# 1. Instantiate the short-lived Melee strike instance
	var melee_strike: Melee = MELEE_SCENE.instantiate()
	
	# 2. Add it to the tree so its _ready and _physics_process kick off
	get_tree().current_scene.add_child(melee_strike)
	
	# 3. Match the exact setup parameters expected by your Melee class
	melee_strike.setup(
		muzzle.global_position,
		direction,
		definition.melee, # Make sure your WeaponDefinition holds a reference to a MeleeDefinition!
		wielder,
		wielder.team,
		damage_multiplier,
		knockback_multiplier
	)
	
	# 4. Optional: Give the player a little Soul Knight-style forward lunge impulse instead of recoil
	var lunge_dir := -direction.normalized()
	wielder.movement_component.apply_impulse(lunge_dir * definition.recoil)
	
	# 5. Cooldown block matching your firearm logic
	await get_tree().create_timer(definition.fire_rate).timeout
	can_fire = true

func update_visual_aim(dir: Vector3) -> void:
	# Rotate the weapon root node on the floor plane
	var angle_y := atan2(-dir.z, dir.x)
	global_rotation.y = angle_y
	
	# Prevent the 2D sprite from flipping upside down when aiming left
	sprite.flip_v = dir.x < 0
