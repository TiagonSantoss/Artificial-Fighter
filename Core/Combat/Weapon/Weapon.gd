class_name Weapon
extends Node3D

var definition: WeaponDefinition  # ye

var wielder: Entity

var damage_multiplier := 1.0
var knockback_multiplier := 1.0
var pierce_multiplier := 1.0
var speed_multiplier := 1.0
var default_behaviors: Array[BehaviorDefinition]

@onready var visual_component: WeaponVisualComponent = $WeaponComponent/VisualComponent
@onready var attack_component: WeaponAttackComponent = $WeaponComponent/AttackComponent
@onready var behavior_component: WeaponBehaviorComponent = $WeaponComponent/BehaviorComponent
@onready var audio_component: WeaponAudioComponent = $WeaponComponent/AudioComponent


func _process(delta: float) -> void:
	if wielder == null:
		return

	_update_aim()
	visual_component.update(delta)
	attack_component.update(delta)
	behavior_component.update(delta)


func setup(weapon_definition, owner_entity):
	assert(weapon_definition != null)

	if weapon_definition.is_melee:
		assert(weapon_definition.melee != null)
	else:
		assert(weapon_definition.projectile != null)

	definition = weapon_definition
	wielder = owner_entity

	damage_multiplier = definition.damage_multiplier
	knockback_multiplier = definition.knockback_multiplier
	pierce_multiplier = definition.pierce_multiplier
	speed_multiplier = definition.speed_multiplier

	default_behaviors = definition.default_behaviors

	visual_component.setup(self)
	attack_component.setup(self)

	if default_behaviors:
		equip_default_behaviors()

	visual_component.apply_definition()

	set_process(true)


func equip_default_behaviors() -> void:
	for behavior in default_behaviors:
		var instance := ItemInstance.new()
		instance.definition = behavior
		equip_behavior(instance)


func equip_behavior(instance: ItemInstance) -> bool:
	return behavior_component.add_behavior(instance)


func unequip_behavior(instance: ItemInstance) -> bool:
	return behavior_component.remove_behavior(instance)


func _update_aim() -> void:
	var cam: Camera3D = get_viewport().get_camera_3d()
	if cam == null:
		return

	var mouse := get_viewport().get_mouse_position()
	var screen_pos := cam.unproject_position(global_position)
	var screen_dir := mouse - screen_pos

	if screen_dir.length() < 0.001:
		return

	screen_dir = screen_dir.normalized()

	var cam_forward := -cam.global_transform.basis.z
	var cam_right := cam.global_transform.basis.x

	cam_forward.y = 0
	cam_right.y = 0

	cam_forward = cam_forward.normalized()
	cam_right = cam_right.normalized()

	var world_dir := (cam_right * screen_dir.x + cam_forward * -screen_dir.y).normalized()

	visual_component.update_aim(world_dir)
