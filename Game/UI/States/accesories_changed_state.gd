class_name AccessoriesChangedState
extends RefCounted

var current_accessories: Array[ItemInstance] = []


func _init(accessories: Array[ItemInstance] = []):
	current_accessories = accessories
