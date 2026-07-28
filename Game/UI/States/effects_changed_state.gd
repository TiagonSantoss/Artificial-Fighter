class_name EffectsChangedState
extends RefCounted

var entity: Entity
var effect_instance: ItemInstance


func _init(p_entity: Entity = null, p_effect_instance: ItemInstance = null) -> void:
	entity = p_entity
	effect_instance = p_effect_instance
