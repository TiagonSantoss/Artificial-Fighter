class_name EchoSlashBehavior
extends BehaviorDefinition

@export var echo_delay := 0.15
@export var echo_damage_multiplier := 0.5


func on_melee_spawned(context, shot, melee, instance) -> void:
	if melee.has_meta("is_duplicate"):
		return

	# We use a separate function to handle the delay so we don't hold up this frame
	_spawn_echo(melee)


func _spawn_echo(original_melee) -> void:
	# Wait for the delay
	await original_melee.get_tree().create_timer(echo_delay, false).timeout

	# Check if the source entity is still alive/valid before spawning the echo
	if not is_instance_valid(original_melee.source_entity):
		return

	var echo_melee = original_melee.duplicate()
	echo_melee.set_meta("is_duplicate", true)

	# Re-setup the echo. Notice we use source_entity.global_position so
	# it spawns where the player is NOW, not where they were 0.15s ago.
	echo_melee.setup(
		original_melee.source_entity.global_position,
		original_melee.strike_direction,
		original_melee.definition,
		original_melee.source_entity,
		original_melee.source_team,
		original_melee.damage_multiplier * echo_damage_multiplier,
		original_melee.knock_multiplier
	)

	original_melee.get_parent().call_deferred("add_child", echo_melee)
