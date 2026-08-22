class_name CurrencyComponent
extends EntityComponent

var player_wallet := GameAutoLoad.wallet


func collect_item(world_item: WorldItem) -> void:
	if entity.entity_id == 0 or entity.entity_id == 1:
		var item_data = world_item.get_instance()

		if item_data is CurrencyItemInstance:
			if player_wallet:
				player_wallet.add(item_data.currency_type, item_data.amount)

				world_item.queue_free()
			else:
				push_error("CurrencyComponent: No PlayerWallet assigned!")
