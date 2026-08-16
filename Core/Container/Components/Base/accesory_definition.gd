class_name AccessoryDefinition
extends ItemDefinition

@export var passive_effects: Array[EffectDefinition] = []

@export var behaviors: Array[BehaviorDefinition] = []


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

	var weapon_manager = entity.weapon_component
	if weapon_manager and weapon_manager.equipped_weapon:
		var behavior_comp = weapon_manager.equipped_weapon.get_node_or_null(
			"WeaponComponent/BehaviorComponent"
		)

		if behavior_comp != null:
			var applied_behaviors: Array = []
			for behavior_def in behaviors:
				var new_behavior_instance = ItemInstance.new()

				new_behavior_instance.definition = behavior_def

				var success = behavior_comp.add_behavior(new_behavior_instance)

				if success:
					applied_behaviors.append(new_behavior_instance)


func on_unequip(entity: Entity, instance: ItemInstance) -> void:
	var effects_comp: EffectsComponent = entity.get_node_or_null("Components/EffectsComponent")
	if effects_comp == null:
		return

	var applied_instances: Array = instance.metadata.get("applied_effects", [])
	for effect_instance in applied_instances:
		effects_comp.remove_effect_instance(effect_instance)

	instance.metadata.erase("applied_effects")

	var weapon_manager = entity.weapon_component
	if weapon_manager and weapon_manager.equipped_weapon:
		var behavior_comp = weapon_manager.equipped_weapon.get_node_or_null(
			"WeaponComponent/BehaviorComponent"
		)

		var applied_behaviors: Array = instance.metadata.get("applied_behaviors", [])
		for behavior_instance in applied_behaviors:
			behavior_comp.remove_behavior(behavior_instance)
		instance.metadata.erase("applied_behaviors")
