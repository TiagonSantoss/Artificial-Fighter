class_name PlayerWallet
extends Resource

signal wallet_changed(currency: StringName, new_amount: int)

var _currencies: Dictionary = {}


func get_amount(currency: StringName) -> int:
	return _currencies.get(currency, 0)


func add(currency: StringName, amount: int) -> void:
	_currencies[currency] = get_amount(currency) + amount
	wallet_changed.emit(currency, _currencies[currency])


func can_afford(currency: StringName, cost: int) -> bool:
	return get_amount(currency) >= cost


func spend(currency: StringName, cost: int) -> bool:
	if not can_afford(currency, cost):
		return false
	add(currency, -cost)
	return true
