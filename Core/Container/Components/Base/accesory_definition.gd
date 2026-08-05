class_name AccessoryDefinition
extends ItemDefinition

@export var passive_effects: Array[EffectDefinition] = []


func on_equip(entity: Entity, instance: ItemInstance) -> void:
	var effects_comp: EffectsComponent = entity.get_node_or_null("Components/EffectsComponent")
	if effects_comp == null:
		return

	var applied_instances: Array[ItemInstance] = []

	for effect_def in passive_effects:
		var effect_instance := effects_comp.add_effect(effect_def)
		if effect_instance != null:
			applied_instances.append(effect_instance)

	instance.metadata["applied_effects"] = applied_instances


func on_unequip(entity: Entity, instance: ItemInstance) -> void:
	var effects_comp: EffectsComponent = entity.get_node_or_null("Components/EffectsComponent")
	if effects_comp == null:
		return

	var applied_instances: Array = instance.metadata.get("applied_effects", [])
	for effect_instance in applied_instances:
		effects_comp.remove_effect_instance(effect_instance)

	instance.metadata.erase("applied_effects")
