class_name WeaponInventoryComponent
extends EntityComponent

# Replace this with the actual path to your base Weapon scene
const WEAPON_SCENE = preload("res://Core/Combat/Weapon/Weapon.tscn")

# A container strictly limited to 1 slot!
var weapon_container := CollectibleContainer.new(1)


func _ready() -> void:
	weapon_container.added.connect(_on_weapon_added)
	weapon_container.removed.connect(_on_weapon_removed)


# Call this function when your player collides with a dropped weapon
func pickup_weapon(world_item) -> void:
	var instance = world_item.item_instance
	if instance == null or not (instance.definition is WeaponDefinition):
		return

	# 1. Drop the currently equipped weapon if the slot is full
	if not weapon_container.is_empty():
		_drop_current_weapon()

	# 2. Equip the new weapon
	var success = weapon_container.add(instance)

	# 3. Destroy the physical item node on the ground
	if success:
		world_item.queue_free()


func _drop_current_weapon() -> void:
	var current_instances = weapon_container.get_contents()
	if current_instances.is_empty():
		return

	var current_instance = current_instances[0]

	# Calculate drop position and impulse (pops it up and slightly forward)
	var drop_pos = entity.global_position + Vector3(0, 0.5, 0)
	var drop_impulse = -entity.global_transform.basis.z * 3.0 + Vector3(0, 3.0, 0)

	# Remove it from our container (this triggers _on_weapon_removed to destroy the 3D node)
	weapon_container.remove(current_instance)

	# Spawn the world item back into the scene
	WorldItemSpawner.drop(current_instance, drop_pos, get_tree().current_scene, drop_impulse)


func _on_weapon_added(instance: ItemInstance) -> void:
	var raw_def: Variant = instance.definition

	var weapon_def = raw_def as WeaponDefinition

	if weapon_def == null:
		return

	# Grab the WeaponComponent (Adjust the path if your component structure is different)
	var weapon_comp = entity.get_node_or_null("WeaponComponent")
	if weapon_comp == null:
		push_error("WeaponInventoryComponent could not find WeaponComponent!")
		return

	# 1. Spawn the new physical 3D weapon node
	var new_weapon_node = WEAPON_SCENE.instantiate()
	weapon_comp.add_child(new_weapon_node)

	# 2. Setup the weapon with the definition
	new_weapon_node.setup(weapon_def, entity)
	weapon_comp.equipped_weapon = new_weapon_node

	# 3. Re-apply Accessory behaviors!
	_reapply_accessories(new_weapon_node)

	# Optional: Emit a global signal if your UI needs to update
	# GState.weapon_inventory_changed.emit(instance)


func _on_weapon_removed(instance: ItemInstance) -> void:
	# Destroy the physical 3D weapon node when it leaves the container
	var weapon_comp = entity.get_node_or_null("WeaponComponent")
	if weapon_comp != null and is_instance_valid(weapon_comp.equipped_weapon):
		weapon_comp.equipped_weapon.queue_free()
		weapon_comp.equipped_weapon = null


func _reapply_accessories(new_weapon) -> void:
	# Grab the AccessoriesComponent (Adjust the path if your component structure is different)
	var accessories_comp = entity.get_node_or_null("AccessoriesComponent")
	if accessories_comp == null:
		return

	var behavior_comp = new_weapon.behavior_component
	if behavior_comp == null:
		return

	# Because you swapped weapons, the new weapon doesn't have the Accessory behaviors yet.
	# Loop through the player's equipped accessories and push their behaviors to the new weapon.
	for accessory_instance in accessories_comp.get_accessories():
		var accessory_def = accessory_instance.definition as AccessoryDefinition
		if accessory_def and accessory_def.behaviors:
			for behavior_def in accessory_def.behaviors:
				var new_behavior_instance = ItemInstance.new()
				new_behavior_instance.definition = behavior_def
				behavior_comp.add_behavior(new_behavior_instance)
