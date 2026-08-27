extends PanelContainer

var offer: ShopOffer

@onready var icon_rect: TextureRect = $Item/TextureButton
@onready var name_label: RichTextLabel = $Item/Name
@onready var description_label: RichTextLabel = $Item/Description

@onready var button: Button = $Button


func _ready() -> void:
	button.pressed.connect(_on_button_pressed)


func setup(new_offer: ShopOffer) -> void:
	offer = new_offer

	if offer and offer.item_to_sell:
		name_label.text = offer.item_to_sell.display_name
		description_label.text = offer.item_to_sell.description
		icon_rect.texture = offer.item_to_sell.icon


func _on_button_pressed() -> void:
	if offer:
		GState.shop_item_selected.emit(offer)
