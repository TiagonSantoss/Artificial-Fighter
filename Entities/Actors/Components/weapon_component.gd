class_name WeaponComponent
extends EntityComponent

const WEAPON_SCENE = preload("res://Game/Combat/Weapon/Weapon.tscn")

var equipped_weapon: Weapon
var weapon_socket: Node3D

func set_weapon_socket(socket: Node3D) -> void:
	if socket == null:
		push_error("Weapon socket is null!")
		return
	weapon_socket = socket

func look_at_target(target: Vector3) -> void:
	if weapon_socket == null:
		return
	
	weapon_socket.look_at(target, Vector3.UP)

func equip_weapon(weapon_definition) -> void:
	if equipped_weapon:
		equipped_weapon.queue_free()
	
	equipped_weapon = WEAPON_SCENE.instantiate()
	
	weapon_socket.add_child(
		equipped_weapon
	)
	
	equipped_weapon.setup(
		weapon_definition,
		entity
	)

func get_damage_multiplier() -> float:
	if not equipped_weapon:
		return 1.0
	
	return equipped_weapon.damage_multiplier
