class_name BallBehavior
extends BehaviorDefinition

@export_category("Settings")
@export var charge_duration := 0.5
@export var fling_speed := 50.0


func before_attack(context: WeaponAttackContext, _instance: ItemInstance) -> void:
	var wielder := _get_wielder(context, _instance)
	if not is_instance_valid(wielder):
		return

	var movement_comp := _get_movement_component(wielder)
	if not is_instance_valid(movement_comp):
		return

	# 1. Capture the direction before freezing
	var move_dir := Vector3.FORWARD
	if (
		"movement_velocity" in movement_comp
		and not movement_comp.movement_velocity.is_zero_approx()
	):
		move_dir = movement_comp.movement_velocity.normalized()
	elif "last_direction" in movement_comp and not movement_comp.last_direction.is_zero_approx():
		move_dir = movement_comp.last_direction
	elif "velocity" in wielder and not wielder.velocity.is_zero_approx():
		move_dir = wielder.velocity.normalized()

	# 2. Halt current velocities
	movement_comp.movement_velocity = Vector3.ZERO
	movement_comp.external_velocity = Vector3.ZERO
	if "velocity" in wielder:
		wielder.velocity = Vector3.ZERO

	# 3. Store original speeds and lock them to 0 so player inputs cannot override the freeze
	var original_move_speed = movement_comp.move_speed if "move_speed" in movement_comp else 0.0
	var original_max_speed = movement_comp.max_speed if "max_speed" in movement_comp else 0.0

	if "move_speed" in movement_comp:
		movement_comp.move_speed = 0.0
	if "max_speed" in movement_comp:
		movement_comp.max_speed = 0.0

	# 4. Wait for the charge duration
	var tree := wielder.get_tree()
	if tree:
		await tree.create_timer(charge_duration).timeout

		if is_instance_valid(movement_comp) and is_instance_valid(wielder):
			# Restore original movement speeds
			if "move_speed" in movement_comp:
				movement_comp.move_speed = original_move_speed
			if "max_speed" in movement_comp:
				movement_comp.max_speed = original_max_speed

			# 5. Release the charge: fire the impulse forward
			movement_comp.apply_impulse(move_dir * fling_speed)


func _get_movement_component(wielder: Node) -> Node:
	if wielder.has_node("MovementComponent"):
		return wielder.get_node("MovementComponent")
	if "movement_component" in wielder and is_instance_valid(wielder.movement_component):
		return wielder.movement_component
	for child in wielder.get_children():
		if (
			child is MovementComponent
			or (child.get_script() and child.get_script().get_global_name() == &"MovementComponent")
		):
			return child
	return null


func _get_wielder(context: WeaponAttackContext, instance: ItemInstance) -> Node:
	if "wielder" in context and is_instance_valid(context.wielder):
		return context.wielder
	elif "owner" in instance and is_instance_valid(instance.owner):
		return instance.owner
	return null
