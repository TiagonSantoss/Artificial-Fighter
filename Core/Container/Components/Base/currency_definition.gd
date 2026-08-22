class_name CurrencyDefinition
extends ItemDefinition

@export var currency_type: StringName = &"Cash Cards"


func create_instance() -> ItemInstance:
	var instance := CurrencyItemInstance.new()
	instance.definition = self
	return instance


func create_currency_drop(drop_amount: int) -> CurrencyItemInstance:
	var instance := create_instance() as CurrencyItemInstance
	instance.amount = drop_amount
	return instance
