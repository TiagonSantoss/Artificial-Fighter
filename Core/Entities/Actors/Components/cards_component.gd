class_name CardsComponent
extends EntityComponent

# Container capacity limit (e.g., 5 cards in hand)
var hand = CollectibleContainer.new(5)


func _ready() -> void:
	hand.added.connect(_on_card_added)
	hand.removed.connect(_on_card_removed)


func _on_card_added(instance: ItemInstance) -> void:
	# Ensure entity reference is populated (fallback to parent/owner if needed)
	var active_entity := _get_active_entity()
	print("CARD ADDED:", instance)

	if instance != null:
		print(
			"Def class: ",
			(
				instance.definition.get_script().get_global_name()
				if instance.definition and instance.definition.get_script()
				else "No Script"
			)
		)
		print("Is CardDefinition? ", instance.definition is CardDefinition)

	if instance != null and instance.definition is CardDefinition:
		var state := CardsChangedState.new(active_entity, instance)
		print("Emitting GState.cards_changed with entity: ", active_entity)
		GState.cards_changed.emit(state)

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

	# Fallback if component entity variable wasn't set yet
	if owner is Entity:
		return owner as Entity

	if get_parent() is Entity:
		return get_parent() as Entity

	if get_parent() != null and get_parent().get_parent() is Entity:
		return get_parent().get_parent() as Entity

	return null
