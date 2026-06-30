class_name VendingMachine
extends Area3D

@export var possible_items: Array[ItemDefinition]
@export var drop_force := 2.0

signal interacted(player: Node)

func _apply_throw_force(item: WorldItem) -> void:
	var dir := Vector3(
		randf_range(-1, 1),
		randf_range(0.5, 1.0),
		randf_range(-1, 1)
	).normalized()

	item.push_item(dir * drop_force)

func interact(player: Node) -> void:
	emit_signal("interacted", player)
	spawn_item()

func spawn_item():
	var def = possible_items.pick_random()
	
	var instance = def.create_instance()
	
	var item := WorldItemSpawner.drop(
		instance,
		global_position,
		get_tree().current_scene
	)
	
	_apply_throw_force(item)
