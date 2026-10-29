class_name WeaponInventoryComponent
extends EntityComponent

const WEAPON_SCENE = preload("res://Core/Combat/Weapon/Weapon.tscn")

@export var pickup_cooldown := 0.75

var weapon_container := CollectibleContainer.new(1)

var _cooldown_left := 0.0
var _incoming: WorldItem = null


func _process(delta: float) -> void:
	if _cooldown_left > 0.0:
		_cooldown_left -= delta


func try_claim_pickup(item: WorldItem) -> bool:
	if _cooldown_left > 0.0:
		return false
	if is_instance_valid(_incoming) and _incoming != item:
		return false
	_incoming = item
	return true


func release_claim(item: WorldItem) -> void:
	if _incoming == item:
		_incoming = null


func _ready() -> void:
	weapon_container.added.connect(_on_weapon_added)
	weapon_container.removed.connect(_on_weapon_removed)


# Helper to fetch this specific entity's starting/default weapon definition
func _get_default_weapon_def() -> WeaponDefinition:
	if entity and entity.definition and "starting_weapon" in entity.definition:
		return entity.definition.starting_weapon
	return null


func _check_default_weapon() -> void:
	var default_def = _get_default_weapon_def()
	if weapon_container.is_empty() and default_def != null:
		var default_instance = ItemInstance.new()
		default_instance.definition = default_def
		weapon_container.add(default_instance)


# Call this when colliding with a WorldItem weapon drop
func pickup_weapon(world_item: WorldItem) -> bool:
	if (
		world_item.instance.definition == null
		or not (world_item.instance.definition is WeaponDefinition)
	):
		return false

	var new_instance = world_item.instance
	var default_def = _get_default_weapon_def()

	# 1. If we already have a weapon equipped...
	if not weapon_container.is_empty():
		var current_instance = weapon_container.get_contents()[0]

		# If it's NOT the character's default weapon, drop the real weapon into the world first
		if current_instance.definition != default_def:
			var drop_pos = entity.global_position + Vector3(0, 0.5, 0)
			var dropped = WorldItemSpawner.drop(
				current_instance, drop_pos, get_tree().current_scene
			)
			if dropped is WorldItem:
				dropped.ignored_body = entity
		# Clear the container silently without triggering the default weapon fallback yet
		weapon_container.remove(current_instance)  # Cleans up the old 3D weapon node

	var ok := weapon_container.add(new_instance)

	if ok:
		_cooldown_left = pickup_cooldown
	release_claim(world_item)
	return ok


func drop_current_weapon() -> void:
	var current_instances = weapon_container.get_contents()
	if current_instances.is_empty():
		return

	var current_instance = current_instances[0]
	var default_def = _get_default_weapon_def()

	# SAFETY: Never allow the character's default fallback weapon to be dropped into the world!
	if current_instance.definition == default_def:
		return

	# Remove from container (triggers _on_weapon_removed to delete the 3D node)
	WorldItemSpawner.drop(current_instance, Vector3(0, 2, 0))

	# FALLBACK: Automatically re-equip the character's default weapon once the item is gone
	if weapon_container.is_empty() and default_def != null:
		var default_instance = ItemInstance.new()
		default_instance.definition = default_def
		weapon_container.add(default_instance)


func _on_weapon_added(instance: ItemInstance) -> void:
	var weapon_def := instance.definition as WeaponDefinition
	if weapon_def == null:
		return

	entity.weapon_component.equip_weapon(weapon_def)
	_reapply_accessories(entity.weapon_component.equipped_weapon)


func _on_weapon_removed(_instance: ItemInstance) -> void:
	entity.weapon_component.unequip_weapon()


func _reapply_accessories(new_weapon: Weapon) -> void:
	var accessories_comp = entity.accessories_component
	if accessories_comp == null:
		return
	for accessory_instance in accessories_comp.get_accessories():
		var raw_acc: Variant = accessory_instance.definition
		var accessory_def = raw_acc as AccessoryDefinition
		if accessory_def and accessory_def.behaviors:
			for behavior_def in accessory_def.behaviors:
				var new_behavior_instance = ItemInstance.new()
				new_behavior_instance.definition = behavior_def
				new_weapon.behavior_component.add_behavior(new_behavior_instance)
