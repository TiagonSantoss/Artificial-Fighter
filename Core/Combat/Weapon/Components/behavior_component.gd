class_name WeaponBehaviorComponent
extends WeaponComponent

const WorldItemScene := preload("res://Game/World/WorldItem.tscn")

var behaviors := CollectibleContainer.new()


func before_attack(context: WeaponAttackContext):
	for instance in behaviors.contents:
		var behavior := instance.definition as BehaviorDefinition
		if behavior:
			behavior.before_attack(context, instance)


func on_projectile_spawned(context: WeaponAttackContext, shot: AttackShot, projectile: Projectile):
	for instance in behaviors.contents:
		var behavior := instance.definition as BehaviorDefinition
		if behavior:
			behavior.on_projectile_spawned(context, shot, projectile, instance)

			projectile.set_meta("source_behavior_component", self)


func update_live_projectile(projectile: Projectile, delta: float) -> void:
	for instance in behaviors.contents:
		var behavior := instance.definition as BehaviorDefinition
		if behavior:
			behavior.update_live_projectile(projectile, delta, instance)


func on_melee_spawned(context, shot, melee):
	for instance in behaviors.contents:
		var behavior := instance.definition as BehaviorDefinition
		if behavior:
			behavior.on_melee_spawned(context, shot, melee, instance)


func after_attack(context):
	for instance in behaviors.contents:
		var behavior := instance.definition as BehaviorDefinition
		if behavior:
			behavior.after_attack(context, instance)


func add_behavior(instance: ItemInstance) -> bool:
	if instance == null:
		return false

	if not instance.definition is BehaviorDefinition:
		return false

	if behaviors.is_full():
		return false

	var unique_behavior = instance.definition.duplicate(true) as BehaviorDefinition
	instance.definition = unique_behavior

	var ok := behaviors.add(instance)

	if ok:
		if unique_behavior:
			unique_behavior.on_equipped(weapon, instance)

	return ok


func remove_behavior(instance: ItemInstance) -> bool:
	var ok := behaviors.remove(instance)

	if ok:
		var behavior := instance.definition as BehaviorDefinition
		if behavior:
			behavior.on_unequipped(weapon, instance)

	return ok


func drop_behavior(instance: ItemInstance) -> void:
	if behaviors.remove(instance):
		var drop_pos := weapon.wielder.global_position + Vector3(0, 0.5, 0)
		var drop_impulse := -weapon.wielder.global_transform.basis.z * 2.0 + Vector3(0, 3.0, 0)
		WorldItemSpawner.drop(instance, drop_pos, weapon.wielder.get_parent(), drop_impulse)
