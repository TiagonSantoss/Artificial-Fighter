class_name EvilSwordController
extends Controller

@export_category("Boss Settings")
@export var windup_time := 1.5  # stands still and slowly spins before bouncing
@export var spin_speed := 12.0  # radians per second
@export var contact_damage := 20.0
@export var contact_knockback := 12.0
@export var hit_radius := 2.5
@export var hit_interval := 1.2  # keep this above your players' iframe_duration (1.0)
@export var parry_stun := 2.0  # boss freezes this long when a hit gets parried
@export var bounce_duration := 8.0  # seconds spent bouncing before it stops
@export var rest_duration := 3.0  # seconds it stands still before bouncing again

enum Phase { STANDING, BOUNCING }

var _phase := Phase.STANDING
var _phase_left := 0.0
var _phase_total := 1.0

var target: Entity  # Game.spawn_enemy assigns this

var _heading := Vector3.ZERO
var _started := false
var _windup_left := 0.0
var _hit_cooldowns := {}  # victim instance id -> seconds left


func get_actions(actor: Entity, delta: float) -> Array[Action]:
	var actions: Array[Action] = []

	if not is_instance_valid(target):
		return actions

	if not _started:
		_started = true
		_enter_standing(actor, windup_time)
		SceneManager.spawn_effect(
			SceneManager.Fx.WARNING, actor.global_position + Vector3(0, 2.0, 0)
		)
		FmodServer.play_one_shot("event:/SFX/UI/Warn")

	_tick_hit_cooldowns(delta)
	_phase_left -= delta
	var sprite = actor.animation_component.sprite

	if _phase == Phase.STANDING:
		# spin ramps up as the rest ends, telegraphing the restart
		var t := 1.0 - clampf(_phase_left / _phase_total, 0.0, 1.0)
		sprite.rotate_z(spin_speed * lerpf(0.1, 0.5, t) * delta)
		if _phase_left <= 0.0:
			_enter_bouncing()
		return actions

	if _phase_left <= 0.0:
		_enter_standing(actor, rest_duration)
		return actions

	sprite.rotate_z(spin_speed * delta)
	_handle_bounce(actor)

	var move := actor.movement_component
	move.movement_velocity = _heading * move.max_speed
	actions.append(MovementAction.new(_heading))

	_hit_nearby(actor)
	return actions


func _enter_standing(actor: Entity, duration: float) -> void:
	_phase = Phase.STANDING
	_phase_total = maxf(duration, 0.001)
	_phase_left = duration
	actor.movement_component.movement_velocity = Vector3.ZERO


func _enter_bouncing() -> void:
	_phase = Phase.BOUNCING
	_phase_total = bounce_duration
	_phase_left = bounce_duration
	_heading = _random_heading()


# --------------------------------------------------
# BOUNCE
# --------------------------------------------------
func _random_heading() -> Vector3:
	# Off-axis on purpose, an axis-aligned start would just ping-pong between two walls
	var angle := randf_range(PI / 6.0, PI / 3.0) + randi_range(0, 3) * (PI / 2.0)
	return Vector3(cos(angle), 0.0, sin(angle))


func _handle_bounce(actor: Entity) -> void:
	# Slide collisions come from the previous frame's move_and_slide
	for i in actor.get_slide_collision_count():
		var normal := actor.get_slide_collision(i).get_normal()
		normal.y = 0.0  # ignore floor hits

		if normal.length_squared() < 0.25:
			continue

		normal = normal.normalized()

		# Only reflect if moving into the wall (corners reflect twice, like the logo)
		if _heading.dot(normal) < 0.0:
			_heading = _heading.bounce(normal).normalized()
			SceneManager.shake(0.15, 0.1)


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

	# ADAPT: I haven't seen HitData, so the damage and knockback field names are guesses
	var hit := HitData.new()
	hit.source_entity = actor
	hit.source_team = actor.team
	hit.direction = dir
	hit.hit_position = victim.global_position + Vector3(0, 1.0, 0)
	hit.damage = contact_damage
	hit.knockback = contact_knockback

	var was_parrying: bool = victim.parry_window_left > 0.0
	victim.apply_hit(hit)

	# Parry punishes the boss: it freezes and the player gets a free window
	if was_parrying:
		actor.stun_duration = maxf(actor.stun_duration, parry_stun)
