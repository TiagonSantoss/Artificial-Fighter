class_name EffectsComponent
extends EntityComponent

var effects = CollectibleContainer.new(10)  # Set capacity to desired max active status effects


func _ready() -> void:
	effects.added.connect(_on_effect_added)
	effects.removed.connect(_on_effect_removed)


func _on_effect_added(instance: ItemInstance) -> void:
	var effect := instance.definition as EffectDefinition
	if effect != null:
		effect.on_added(entity, instance)
		var state := EffectsChangedState.new(entity, instance)
		GState.effects_changed.emit(state)


func _on_effect_removed(instance: ItemInstance) -> void:
	var effect := instance.definition as EffectDefinition
	if effect != null:
		effect.on_removed(entity, instance)
		var state := EffectsChangedState.new(entity, instance)
		GState.effects_changed.emit(state)


func update(delta: float) -> void:
	for instance in effects.contents:
		var effect := instance.definition as EffectDefinition
		if effect == null:
			continue

		effect.update(entity, instance, delta)


func add_effect(effect_def: EffectDefinition, _duration: float = 0.0) -> void:
	if effect_def == null:
		return

	var instance := ItemInstance.new()
	instance.definition = effect_def

	effects.add(instance)
