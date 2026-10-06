class_name CardsComponent
extends EntityComponent

# Total hand capacity limit
var hand = CollectibleContainer.new(4)

# Max allowed cards per axis direction
@export var max_cards_per_axis: int = 2


func _ready() -> void:
	hand.added.connect(_on_card_added)
	hand.removed.connect(_on_card_removed)


func can_add_card(instance: ItemInstance) -> bool:
	if instance == null or not (instance.definition is CardDefinition):
		return false

	var def := instance.definition as CardDefinition

	# "ANY" cards can be added as long as the overall hand isn't full
	if def.allowed_axis == CardDefinition.CardAxis.ANY:
		return hand.contents.size() < hand.capacity

	# Count how many cards of this specific axis are currently in hand
	var axis_count = 0
	for card in hand.contents:
		if card != null and card.definition is CardDefinition:
			var card_def = card.definition as CardDefinition
			if card_def.allowed_axis == def.allowed_axis:
				axis_count += 1

	# Reject if this axis has reached its limit (e.g., max 2 X-cards)
	if axis_count >= max_cards_per_axis:
		return false

	return true


func _on_card_added(instance: ItemInstance) -> void:
	var active_entity := _get_active_entity()
	print("CARD ADDED:", instance)

	if instance != null and instance.definition is CardDefinition:
		var state := CardsChangedState.new(active_entity, instance)
		GState.cards_changed.emit(state)


func _on_card_removed(instance: ItemInstance) -> void:
	var active_entity := _get_active_entity()

	if instance != null and instance.definition is CardDefinition:
		var state := CardsChangedState.new(active_entity, instance)
		GState.cards_changed.emit(state)


func get_cards() -> Array[ItemInstance]:
	var card_list: Array[ItemInstance] = []
	for instance in hand.contents:
		if instance != null and instance.definition is CardDefinition:
			card_list.append(instance)
	return card_list


# Helper to ensure entity is never null during signal emission
func _get_active_entity() -> Entity:
	if entity != null:
		return entity

	if owner is Entity:
		return owner as Entity

	if get_parent() is Entity:
		return get_parent() as Entity

	if get_parent() != null and get_parent().get_parent() is Entity:
		return get_parent().get_parent() as Entity

	return null
