class_name SharedStats
extends Resource

@export var max_health: int = 2
var current_health: int = max_health

@export var cards: Array = []
@export var items: Array = []
@export var weapons: Array = []

func take_damage(amount: int) -> void:
	current_health -= amount
	if current_health <= 0:
		current_health = 0

func heal(amount: int) -> void:
	current_health = min(current_health + amount, max_health)

func add_card(card) -> void:
	if card not in cards:
		cards.append(card)

func add_item(item) -> void:
	if item not in items:
		items.append(item)
