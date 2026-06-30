class_name WeaponAttackContext
extends RefCounted

enum AttackType {
	PROJECTILE,
	MELEE
}

var weapon: Weapon
var wielder: Entity

var origin: Vector3
var direction: Vector3
var recoil: float

var projectile_definition: ProjectileDefinition
var attack_type: AttackType

var damage_multiplier: float
var knockback_multiplier: float
var pierce_multiplier: float

var shots: Array[AttackShot] = []

var cancelled := false

func add_shot(shot: AttackShot) -> void:
	shots.append(shot)

func clear_shots() -> void:
	shots.clear()

func remove_shot(shot: AttackShot) -> void:
	shots.erase(shot)
