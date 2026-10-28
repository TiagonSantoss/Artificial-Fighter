class_name BackSlashBehavior
extends BehaviorDefinition

@export var back_damage_multiplier := 0.75


func on_melee_spawned(context, shot, melee, instance) -> void:
	if melee.has_meta("is_duplicate"):
		return

	# 1. Instantiate a FRESH copy of the scene
	var scene = load(melee.scene_file_path)
	var back_melee = scene.instantiate()
	back_melee.set_meta("is_duplicate", true)

	# 2. ADD TO TREE FIRST!
	melee.get_parent().add_child(back_melee)

	# 3. MIRROR THE STARTING POSITION (The Fix!)
	var reversed_dir = -melee.strike_direction

	# Find how far in front of the player the original strike spawned
	var player_pos = melee.source_entity.global_position
	var offset_from_player = melee.global_position - player_pos

	# Subtract that offset to push the new slash behind the player
	var back_position = player_pos - offset_from_player

	# 4. Setup using the mirrored position
	back_melee.setup(
		back_position,
		reversed_dir,
		melee.definition,
		melee.source_entity,
		melee.source_team,
		melee.damage_multiplier * back_damage_multiplier,
		melee.knock_multiplier
	)

	# 5. Flip the slash sprite safely
	if is_instance_valid(back_melee.sprite) and is_instance_valid(melee.sprite):
		back_melee.sprite.flip_h = not melee.sprite.flip_h

	# 6. Spawn the phantom weapon visual
	if is_instance_valid(melee.source_entity.weapon_component):
		var weapon = melee.source_entity.weapon_component.equipped_weapon
		if (
			weapon
			and weapon.visual_component
			and weapon.visual_component.has_method("create_phantom_weapon")
		):
			weapon.visual_component.create_phantom_weapon(reversed_dir, 0.0)
