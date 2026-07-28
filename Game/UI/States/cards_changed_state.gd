class_name CardsChangedState
extends RefCounted

var entity: Entity
var card_instance: ItemInstance


func _init(p_entity: Entity = null, p_card_instance: ItemInstance = null) -> void:
	entity = p_entity
	card_instance = p_card_instance
