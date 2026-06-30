class_name WeaponBehaviorComponent
extends WeaponComponent

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

func on_melee_spawned(context, shot, melee):
	for instance in behaviors.contents:
		var behavior := instance.definition as BehaviorDefinition
		if behavior:
			behavior.on_melee_spawned(context, shot, melee, instance)

func after_attack(context):
	for instance in behaviors.contents:
		var behavior := instance.definition as BehaviorDefinition
		if behavior:
			behavior.after_attack(
				context,
				instance
			)

func add_behavior(instance: ItemInstance) -> bool:
	if instance == null:
		return false
	
	if not instance.definition is BehaviorDefinition:
		return false
	
	if behaviors.is_full():
		return false
	
	var ok := behaviors.add(instance)
	
	if ok:
		var behavior := instance.definition as BehaviorDefinition
		if behavior:
			behavior.on_equipped(weapon, instance)
	
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
		WorldItemSpawner.drop(
			instance,
			weapon.global_position,
			get_tree().current_scene
		)
