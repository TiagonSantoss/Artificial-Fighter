class_name IntoTheFire
extends CardDefinition

const FIRE_EFFECT = preload("res://assets/items/effects/fire.tres")

@export var effect_duration: float = 3.0


func play(_caster: Entity, target: Entity = null, _throw_direction: Vector3 = Vector3.ZERO) -> void:
	if target != null:
		print("Into the Fire hit: ", target.name)
		_apply_fire_to_entity(target)
	else:
		print("Into the Fire activated (No direct target hit).")

	_trigger_fire_screen_overlay(_caster, effect_duration)

	if target != null:
		_apply_fire_to_entity(target)


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
	print("Game.instance exists? ", GameAutoLoad != null)

	if GameAutoLoad and GameAutoLoad.has_method("flash_screen_overlay"):
		print("Calling flash_screen_overlay on Game.instance")
		GameAutoLoad.flash_screen_overlay(Color(1.0, 0.4, 0.0, 0.5), duration)
	else:
		print("ERROR: Game.instance is null OR missing flash_screen_overlay method!")
