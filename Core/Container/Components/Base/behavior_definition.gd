class_name BehaviorDefinition
extends ItemDefinition

enum WeaponType { ANY, MELEE, PROJECTILE }

@export var allowed_weapon_type: WeaponType = WeaponType.ANY


func can_apply_to(weapon: Weapon) -> bool:
	if allowed_weapon_type == WeaponType.ANY:
		return true
	if allowed_weapon_type == WeaponType.MELEE and weapon.definition.is_melee:
		return true
	if allowed_weapon_type == WeaponType.PROJECTILE and not weapon.definition.is_melee:
		return true
	return false


func before_attack(_context: WeaponAttackContext, _instance: ItemInstance) -> void:
	pass


func on_projectile_spawned(
	_context: WeaponAttackContext,
	_shot: AttackShot,
	_projectile: Projectile,
	_instance: ItemInstance
) -> void:
	pass


func update_live_projectile(
	_projectile: Projectile, _delta: float, _instance: ItemInstance
) -> void:
	pass


func on_melee_spawned(
	_context: WeaponAttackContext, _shot: AttackShot, _melee: Melee, _instance: ItemInstance
) -> void:
	pass


func after_attack(_context: WeaponAttackContext, _instance: ItemInstance) -> void:
	pass


func on_equipped(_weapon: Weapon, _instance: ItemInstance) -> void:
	pass
