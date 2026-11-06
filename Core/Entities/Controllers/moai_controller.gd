class_name MoaiController
extends Controller

@export_category("Rush")
@export var aim_time := 1.8  # standing still, turning toward the target
@export var lock_time := 0.5  # last part of the aim: direction frozen + warning (dodge window)
@export var turn_speed := 3.0  # radians per second while aiming
@export var charge_duration := 1.2  # how long the rush lasts
@export var charge_speed_multiplier := 2.0  # multiplies the entity's max_speed
@export var recover_time := 1.5  # standing still after the rush
@export var stop_on_wall := true  # slamming into a wall ends the rush early
@export var rotate_actor := true  # rotate the entity itself to face the heading

@export_category("Contact Damage")
@export var contact_hitbox_enabled := true
@export var contact_damage := 20.0
@export var contact_knockback := 12.0
@export var hit_radius := 2.5
@export var hit_interval := 1.2  # keep this above your players' iframe_duration
@export var parry_stun := 2.0  # boss freezes this long when a hit gets parried

enum Phase { AIM, CHARGE, RECOVER }

var target: Entity  # Game.spawn_enemy assigns this

var _phase := Phase.AIM
var _phase_left := 0.0
var _phase_total := 1.0
var _facing := Vector3.ZERO
var _locked := false
var _initialized := false
var _hit_cooldowns := {}  # victim instance id -> seconds left


func get_actions(actor: Entity, delta: float) -> Array[Action]:
	var actions: Array[Action] = []

	if not is_instance_valid(target):
		return actions

	if not _initialized:
		_initialized = true
		_facing = _flat_dir_to_target(actor)
		if _facing == Vector3.ZERO:
			_facing = _flatten(-actor.global_transform.basis.z)
		_enter_aim(actor)

	_tick_hit_cooldowns(delta)
	_phase_left -= delta

	match _phase:
		Phase.AIM:
			_process_aim(actor, delta)
		Phase.CHARGE:
			_process_charge(actor, actions)
		Phase.RECOVER:
			if _phase_left <= 0.0:
				_enter_aim(actor)

	if rotate_actor and _facing != Vector3.ZERO:
		actor.rotation.y = atan2(-_facing.x, -_facing.z)

	return actions


# The weapon follows the facing direction, so the sword always points where it rushes
func update_aim(actor: Entity) -> void:
	var pos := actor.global_position + _facing * 10.0
	pos.y = actor.weapon_socket.global_position.y
	aim_target = pos


# --------------------------------------------------
# PHASES
# --------------------------------------------------
func _enter_aim(actor: Entity) -> void:
	_phase = Phase.AIM
	_phase_total = maxf(aim_time, 0.001)
	_phase_left = aim_time
	_locked = false
	actor.movement_component.movement_velocity = Vector3.ZERO


func _enter_charge() -> void:
	_phase = Phase.CHARGE
	_phase_total = charge_duration
	_phase_left = charge_duration
	_hit_cooldowns.clear()  # every rush can hit again


func _enter_recover(actor: Entity) -> void:
	_phase = Phase.RECOVER
	_phase_total = maxf(recover_time, 0.001)
	_phase_left = recover_time
	actor.movement_component.movement_velocity = Vector3.ZERO


func _process_aim(actor: Entity, delta: float) -> void:
	if _phase_left > lock_time:
		_turn_toward_target(actor, delta)
	elif not _locked:
		# Direction is frozen from here on, this is the player's window to dodge
		_locked = true
		SceneManager.spawn_effect(
			SceneManager.Fx.WARNING, actor.global_position + Vector3(0, 2.0, 0)
		)
		FmodServer.play_one_shot("event:/SFX/UI/Warn")

	if _phase_left <= 0.0:
		_enter_charge()


func _process_charge(actor: Entity, actions: Array[Action]) -> void:
	var elapsed := _phase_total - _phase_left
	if _phase_left <= 0.0 or (stop_on_wall and elapsed > 0.1 and _hit_wall(actor)):
		_enter_recover(actor)
		return

	# Constant speed straight ahead, no steering while rushing
	var move := actor.movement_component
	move.movement_velocity = _facing * move.max_speed * charge_speed_multiplier

	# Still returned so Entity doesn't apply friction this frame
	actions.append(MovementAction.new(_facing))

	if actor.weapon_component.equipped_weapon != null:
		actions.append(AttackAction.new())

	if contact_hitbox_enabled:
		_hit_nearby(actor)


# --------------------------------------------------
# FACING
# --------------------------------------------------
func _flatten(v: Vector3) -> Vector3:
	v.y = 0.0
	if v.length_squared() < 0.0001:
		return Vector3.ZERO
	return v.normalized()


func _flat_dir_to_target(actor: Entity) -> Vector3:
	if not is_instance_valid(target):
		return Vector3.ZERO
	return _flatten(target.global_position - actor.global_position)


func _turn_toward_target(actor: Entity, delta: float) -> void:
	var desired := _flat_dir_to_target(actor)
	if desired == Vector3.ZERO or _facing == Vector3.ZERO:
		return

	var angle := _facing.signed_angle_to(desired, Vector3.UP)
	var step := clampf(angle, -turn_speed * delta, turn_speed * delta)
	_facing = _facing.rotated(Vector3.UP, step).normalized()


func _hit_wall(actor: Entity) -> bool:
	# Slide collisions come from the previous frame's move_and_slide
	for i in actor.get_slide_collision_count():
		var normal := actor.get_slide_collision(i).get_normal()
		normal.y = 0.0  # ignore floor hits

		if normal.length_squared() < 0.25:
			continue

		if _facing.dot(normal.normalized()) < -0.5:  # roughly head-on
			SceneManager.shake(0.25, 0.15)
			return true
	return false


# --------------------------------------------------
# CONTACT DAMAGE
# --------------------------------------------------
func _tick_hit_cooldowns(delta: float) -> void:
	for id in _hit_cooldowns.keys():
		_hit_cooldowns[id] -= delta
		if _hit_cooldowns[id] <= 0.0:
			_hit_cooldowns.erase(id)


func _hit_nearby(actor: Entity) -> void:
	var query := PhysicsShapeQueryParameters3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = hit_radius
	query.shape = sphere
	query.transform = Transform3D(Basis.IDENTITY, actor.global_position + Vector3(0, 1.0, 0))
	query.collision_mask = 1 << (Game.LAYER_PLAYER - 1)  # players and allies
	query.exclude = [actor.get_rid()]

	for result in actor.get_world_3d().direct_space_state.intersect_shape(query):
		var victim = result.get("collider")
		if not (victim is Entity) or victim == actor or victim.team == actor.team:
			continue

		var id: int = victim.get_instance_id()
		if _hit_cooldowns.has(id):
			continue

		_hit_cooldowns[id] = hit_interval
		_hit_victim(actor, victim)


func _hit_victim(actor: Entity, victim: Entity) -> void:
	var dir := actor.global_position.direction_to(victim.global_position)
	dir.y = 0.0
	dir = dir.normalized()

	var hit := HitData.new()
	hit.source_entity = actor
	hit.source_team = actor.team
	hit.direction = dir
	hit.hit_position = victim.global_position + Vector3(0, 1.0, 0)
	hit.damage = contact_damage
	hit.knockback = contact_knockback

	var was_parrying: bool = victim.parry_window_left > 0.0
	victim.apply_hit(hit)

	# Parry punishes the boss: the rush is cancelled and it freezes
	if was_parrying:
		actor.stun_duration = maxf(actor.stun_duration, parry_stun)
		_enter_recover(actor)
