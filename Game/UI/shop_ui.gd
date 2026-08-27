extends Control

@export var master_item_pool: Array[ShopOffer] = []
@export var shop_slots_count: int = 4

var current_selected_offer: ShopOffer

@onready var buy_button: Button = $Panel/MarginContainer/HBoxContainer/description/buy_button
@onready var shop_items_container: FlowContainer = $Panel/MarginContainer/HBoxContainer/items


func _ready() -> void:
	buy_button.pressed.connect(_on_buy_button_pressed)
	GState.shop_item_selected.connect(_on_item_selected)

	generate_random_shop_offers()


func generate_random_shop_offers() -> void:
	if master_item_pool.is_empty():
		return

	var shuffled_pool = master_item_pool.duplicate()
	shuffled_pool.shuffle()

	var selected_offers: Array[ShopOffer] = []
	for i in range(min(shop_slots_count, shuffled_pool.size())):
		selected_offers.append(shuffled_pool[i])

	if shop_items_container.has_method("populate_shop"):
		shop_items_container.populate_shop(selected_offers)


func _on_item_selected(offer: ShopOffer) -> void:
	current_selected_offer = offer


func _on_buy_button_pressed() -> void:
	if current_selected_offer == null:
		print("No item selected or selected slot is empty!")
		return

	_spawn_item(current_selected_offer)


func _spawn_item(offer: ShopOffer) -> void:
	var instance = offer.item_to_sell.create_instance()
	WorldItemSpawner.drop(instance, GameAutoLoad.player.global_position)
