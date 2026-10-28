class_name Chest
extends Area3D

signal interacted(player: Node)

@export var loot_table: LootTable
@export var animation_player: AnimationPlayer
@export var drop_force := 4.0

@export var chest_id: String = ""

var is_open: bool = false


func _ready() -> void:
	if chest_id == "":
		var pos = global_position.round()
		chest_id = "chest_" + str(pos.x) + "_" + str(pos.y) + "_" + str(pos.z)

	if RunManager.opened_chests.has(chest_id):
		is_open = true

		if animation_player and animation_player.has_animation("open"):
			animation_player.current_animation = "open"
			animation_player.seek(animation_player.current_animation_length, true)


func interact(player: Node) -> void:
	if is_open:
		return

	is_open = true

	RunManager.opened_chests[chest_id] = true

	interacted.emit(player)

	if animation_player and animation_player.has_animation("open"):
		animation_player.play("open")
		SceneManager.shake(0.2, 0.2)
		await animation_player.animation_finished

	spawn_item()


func spawn_item() -> void:
	if loot_table == null:
		push_warning("Chest has no loot table assigned!")
		return

	var def = loot_table.get_random_item()
	if def == null:
		return

	var instance = def.create_instance()

	var drop_position := global_position + Vector3(0, 0.8, 0)

	var impulse := (global_transform.basis.z * 0.5 + Vector3(0, 1.0, 0)).normalized() * drop_force

	WorldItemSpawner.drop(instance, drop_position, get_tree().current_scene, impulse)
