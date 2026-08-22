class_name CurrencyItemInstance
extends ItemInstance

var amount: int = 1


func get_currency_type() -> StringName:
	var def = definition as CurrencyDefinition
	if def:
		return def.currency_type
	return &""
