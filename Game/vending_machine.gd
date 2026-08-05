class_name VendingMachine
extends Area3D

signal interacted(player: Node)

@export var world_item_scene: PackedScene = preload("res://Game/World/WorldItem.tscn")
@export var possible_items: Array[ItemDefinition] = []
@export var drop_force := 4.0


func interact(player: Node) -> void:
	interacted.emit(player)
	spawn_item()


func spawn_item() -> void:
	if possible_items.is_empty() or world_item_scene == null:
		return

	var def = possible_items.pick_random()
	if def == null:
		return

	var instance = def.create_instance()

	var drop_position := global_position + global_transform.basis.z * 0.8 + Vector3(0, 0.5, 0)
	var impulse := (global_transform.basis.z + Vector3(0, 1.0, 0)).normalized() * drop_force

	WorldItemSpawner.drop(instance, drop_position, get_tree().current_scene, impulse)
