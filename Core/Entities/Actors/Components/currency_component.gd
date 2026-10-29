class_name CurrencyComponent
extends EntityComponent

var player_wallet := GameAutoLoad.wallet


func collect_item(world_item: WorldItem) -> bool:
	if entity.entity_id != 0 and entity.entity_id != 1:
		return false

	var item_data := world_item.instance as CurrencyItemInstance
	if item_data == null:
		return false

	if player_wallet == null:
		push_error("CurrencyComponent: wallet is null!")
		return false

	player_wallet.add(item_data.get_currency_type(), item_data.amount)
	return true
