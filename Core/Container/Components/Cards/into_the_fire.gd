class_name IntoTheFire
extends CardDefinition

const FIRE_EFFECT = preload("res://assets/items/effects/fire.tres")

@export var effect_duration: float = 3.0


func play(_caster: Entity, _target: Entity) -> void:
	print("--- [IntoTheFire] PLAYED ---")
	print("Caster: ", _caster)

	# 1. Test Screen Overlay
	_trigger_fire_screen_overlay(_caster, effect_duration)

	# 2. Get tree and search group
	var tree := _caster.get_tree()
	if tree == null:
		print("ERROR: Caster tree is null!")
		return

	var enemies := tree.get_nodes_in_group("enemies")
	print("Enemies found in group 'enemies': ", enemies.size())

	# Fallback check if your group is named "entities" instead
	if enemies.size() == 0:
		enemies = tree.get_nodes_in_group("entities")
		print("Fallback check - Entities found in group 'entities': ", enemies.size())

	for enemy in enemies:
		if enemy is Entity and enemy != _caster:
			print("Attempting to apply fire to enemy: ", enemy)
			_apply_fire_to_entity(enemy)


func _apply_fire_to_entity(enemy: Entity) -> void:
	var comp: Variant = enemy.get("effects_component")
	if comp == null and enemy.has_node("EffectsComponent"):
		comp = enemy.get_node("EffectsComponent")

	print("Enemy effects component found? ", comp != null)

	if comp != null and comp.has_method("add_effect"):
		comp.add_effect(FIRE_EFFECT, effect_duration)
		print("SUCCESS: Fire effect added to ", enemy)
	else:
		print("ERROR: Component missing or does not have 'add_effect' method!")


func _trigger_fire_screen_overlay(_caster: Entity, duration: float) -> void:
	print("Game.instance exists? ", Game.instance != null)

	if Game.instance and Game.instance.has_method("flash_screen_overlay"):
		print("Calling flash_screen_overlay on Game.instance")
		Game.instance.flash_screen_overlay(Color(1.0, 0.4, 0.0, 0.5), duration)
	else:
		print("ERROR: Game.instance is null OR missing flash_screen_overlay method!")
