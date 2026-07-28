class_name EntityWeaponComponent
extends EntityComponent


class OrbitSlot:
	var angle_offset: float
	var radius: float
	var height: float


const WEAPON_SCENE = preload("res://Core/Combat/Weapon/Weapon.tscn")

@export var orbit_radius := 0.15
@export var orbit_speed := 5.0
@export var orbit_height := 0.0
var side_offset := 0.12
var forward_offset := 0.20

var orbit_angle := 0.0
var aim_direction := Vector3.FORWARD

var equipped_weapon: Weapon
var weapon_socket: Marker3D
var orbit_socket: Marker3D


func set_sockets(socket: Marker3D, orbit: Marker3D) -> void:
	if socket == null:
		push_error("Weapon socket is null!")
		return
	weapon_socket = socket
	orbit_socket = orbit


func equip_weapon(weapon_definition) -> void:
	if equipped_weapon:
		equipped_weapon.queue_free()

	equipped_weapon = WEAPON_SCENE.instantiate()

	weapon_socket.add_child(equipped_weapon)

	equipped_weapon.setup(weapon_definition, entity)


func get_damage_multiplier() -> float:
	if not equipped_weapon:
		return 1.0

	return equipped_weapon.damage_multiplier


func update_aim(target: Vector3) -> void:
	if weapon_socket == null:
		return

	var dir := target - weapon_socket.global_position
	if dir.length_squared() > 0.001:
		aim_direction = dir.normalized()

	if equipped_weapon and equipped_weapon.has_method("update_aim"):
		equipped_weapon.update_aim(aim_direction)


func update(delta: float) -> void:
	if orbit_socket == null:
		return

	var right := Vector3(aim_direction.z, 0.0, -aim_direction.x).normalized()

	var target_pos := aim_direction * forward_offset + right * side_offset
	target_pos.y = orbit_height

	orbit_socket.position = orbit_socket.position.lerp(target_pos, 20.0 * delta)
