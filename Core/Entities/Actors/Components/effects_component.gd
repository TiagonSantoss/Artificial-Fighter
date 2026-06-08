class_name EffectsComponent
extends EntityComponent

signal effects_changed

var effects = CollectibleContainer.new(2)

func _ready():
	effects.added.connect(_on_effect_added)
	effects.removed.connect(_on_effect_removed)

func _on_effect_added(instance: ItemInstance) -> void:
	var effect := instance.definition as EffectDefinition
	if effect == null:
		return
	
	effect.on_added(entity,instance)
	
	effects_changed.emit()

func _on_effect_removed(instance: ItemInstance) -> void:
	var effect := instance.definition as EffectDefinition
	if effect == null:
		return
	
	effect.on_removed(
		entity,
		instance
	)
	
	effects_changed.emit()

func update(delta: float) -> void:
	for instance in effects.contents:
		var effect := instance.definition as EffectDefinition
		if effect == null:
			continue
		
		effect.update(
			entity,
			instance,
			delta
		)
