class_name PyramidController
extends Controller

@export_category("Burst")
@export var attack_range := 40.0
@export var burst_duration := 3.0  # seconds spent firing
@export var fire_interval := 0.15  # time between shots during a burst
@export var rest_duration := 2.5  # seconds idle between bursts
@export var windup_time := 0.5  # warning before each burst starts

@export_category("Movement")
@export var stop_distance := 12.0  # stops walking when this close to the target
@export var walk_while_resting := true
@export var walk_while_bursting := false  # true = keeps walking during the burst
@export var burst_walk_multiplier := 0.4  # only used if walk_while_bursting is on

enum Phase { REST, WINDUP, BURST }

var target: Entity  # Game.spawn_enemy assigns this

var _phase := Phase.REST
var _phase_left := 0.0
var _fire_left := 0.0
var _initialized := false


func get_actions(actor: Entity, delta: float) -> Array[Action]:
	var actions: Array[Action] = []

	if not is_instance_valid(actor) or not is_instance_valid(target):
		return actions

	if not _initialized:
		_initialized = true
		# Random first delay, so several enemies don't all fire in sync
		_phase_left = rest_duration * randf_range(0.3, 1.0)

	_phase_left -= delta

	match _phase:
		Phase.REST:
			if walk_while_resting:
				_add_walk(actor, actions, 1.0)

			if _phase_left <= 0.0 and _can_engage(actor):
				_enter_windup(actor)

		Phase.WINDUP:
			# Standing still on purpose: this is the telegraph
			if _phase_left <= 0.0:
				_enter_burst()

		Phase.BURST:
			if walk_while_bursting:
				_add_walk(actor, actions, burst_walk_multiplier)

			_fire_left -= delta
			if _fire_left <= 0.0 and _has_weapon(actor) and has_clear_shot(actor):
				actions.append(AttackAction.new())
				_fire_left = fire_interval

			if _phase_left <= 0.0:
				_enter_rest()

	return actions


func _add_walk(actor: Entity, actions: Array[Action], speed_scale: float) -> void:
	var to_target := target.global_position - actor.global_position
	to_target.y = 0.0

	if to_target.length() <= stop_distance:
		return  # close enough, let friction stop it

	var move := actor.movement_component
	move.movement_velocity = to_target.normalized() * move.max_speed * speed_scale

	# Still returned so Entity doesn't apply friction this frame
	actions.append(MovementAction.new(to_target.normalized()))


# --------------------------------------------------
# PHASES
# --------------------------------------------------
func _enter_rest() -> void:
	_phase = Phase.REST
	_phase_left = rest_duration


func _enter_windup(actor: Entity) -> void:
	_phase = Phase.WINDUP
	_phase_left = windup_time
	SceneManager.spawn_effect(SceneManager.Fx.WARNING, actor.global_position + Vector3(0, 1.5, 0))
	FmodServer.play_one_shot("event:/SFX/UI/EnemyWarn")


func _enter_burst() -> void:
	_phase = Phase.BURST
	_phase_left = burst_duration
	_fire_left = 0.0  # first shot right away


func _can_engage(actor: Entity) -> bool:
	var dist := actor.global_position.distance_to(target.global_position)
	return dist <= attack_range and has_clear_shot(actor)


func _has_weapon(actor: Entity) -> bool:
	# AttackAction crashes if there is no equipped weapon
	return actor.weapon_component != null and actor.weapon_component.equipped_weapon != null


# --------------------------------------------------
# AIM (same as CubeController)
# --------------------------------------------------
func update_aim(actor: Entity) -> void:
	if is_instance_valid(target):
		var target_center := target.global_position
		target_center.y = actor.global_position.y
		aim_target = target_center

		if is_instance_valid(actor.mesh_instance):
			var mesh := actor.mesh_instance
			if mesh.global_position.distance_squared_to(target_center) > 0.01:
				var target_transform := mesh.global_transform.looking_at(target_center, Vector3.UP)
				target_transform = target_transform.rotated_local(Vector3.UP, PI)
				mesh.global_transform = mesh.global_transform.interpolate_with(
					target_transform, 0.1
				)


func has_clear_shot(actor: Entity) -> bool:
	if not is_instance_valid(target):
		return false

	var space_state := actor.get_world_3d().direct_space_state
	var origin := actor.global_position
	var target_center := target.global_position

	var dir_to_target := origin.direction_to(target_center)
	var right_offset := Vector3.UP.cross(dir_to_target).normalized() * 0.4
	var target_points = [target_center, target_center + right_offset, target_center - right_offset]

	for point in target_points:
		var query := PhysicsRayQueryParameters3D.create(origin, point)
		query.exclude = [actor]
		query.collision_mask = 3
		var result := space_state.intersect_ray(query)

		if not result.is_empty() and result.collider == target:
			return true

	return false
