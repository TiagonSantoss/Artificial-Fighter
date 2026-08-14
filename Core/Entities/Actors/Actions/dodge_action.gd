class_name DodgeAction
extends Action

var dash_force: float
var iframe_duration: float


func _init(force: float = 30.0, duration: float = 0.4):
	dash_force = force
	iframe_duration = duration


func execute(actor: Entity, _delta: float) -> void:
	if not actor.controller or not actor.movement_component:
		return

	var target_pos: Vector3 = actor.controller.aim_target
	var dash_dir := target_pos - actor.global_position
	dash_dir.y = 0

	if dash_dir.length_squared() > 0.001:
		dash_dir = dash_dir.normalized()

		actor.movement_component.apply_dash(dash_dir, dash_force)

		if actor.has_method("start_dodge"):
			actor.start_dodge(iframe_duration)
