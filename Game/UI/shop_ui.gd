extends Control

@export var master_item_pool: Array[ShopOffer] = []
@export var shop_slots_count: int = 4

@export_category("Currency UI")
@export var display_currency: StringName = &"cc"
@export var currency_label: String = "CC"
@export var balance_label: Label  # optional, assign in the inspector

var current_selected_offer: ShopOffer

@onready var buy_button: Button = $Panel/MarginContainer/HBoxContainer/description/buy_button
@onready var shop_items_container: FlowContainer = $Panel/MarginContainer/HBoxContainer/items


func _ready() -> void:
	hide()

	buy_button.pressed.connect(_on_buy_button_pressed)
	GState.shop_item_selected.connect(_on_item_selected)
	GState.shop_activation_requested.connect(_on_shop_activation_requested)
	GameAutoLoad.wallet.wallet_changed.connect(_on_wallet_changed)

	generate_random_shop_offers()
	_refresh_ui()


func _on_shop_activation_requested(is_active: bool) -> void:
	visible = is_active
	if is_active:
		_refresh_ui()


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
	_refresh_ui()


func _on_wallet_changed(_currency: StringName, _new_amount: int) -> void:
	_refresh_ui()


func _on_buy_button_pressed() -> void:
	var offer := current_selected_offer
	if offer == null or offer.item_to_sell == null:
		return

	var buyer := GameAutoLoad.controlled_entity
	if not is_instance_valid(buyer):
		return

	if not GameAutoLoad.try_spend(offer.currency_required, offer.price):
		SceneManager.shake(5, 0.1)
		FmodServer.play_one_shot("event:/SFX/UI/CantAfford")
		return

	var instance := offer.item_to_sell.create_instance()
	FmodServer.play_one_shot("event:/SFX/UI/Purchase")
	WorldItemSpawner.drop(instance, buyer.global_position)


func _refresh_ui() -> void:
	var wallet := GameAutoLoad.wallet

	if balance_label:
		balance_label.text = "%s: %d" % [currency_label, wallet.get_amount(display_currency)]

	var offer := current_selected_offer
	if offer == null or offer.item_to_sell == null:
		buy_button.disabled = true
		buy_button.text = "Select an item"
		return

	if wallet.can_afford(offer.currency_required, offer.price):
		buy_button.disabled = false
		buy_button.text = "Buy (%d %s)" % [offer.price, currency_label]
	else:
		buy_button.disabled = true
		buy_button.text = "Not enough %s (%d)" % [currency_label, offer.price]