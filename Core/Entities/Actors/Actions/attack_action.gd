class_name AttackAction
extends Action

#var direction: Vector3

#func _init(dir: Vector3):
#	direction = dir

func execute(entity, _delta):
	entity.weapon_component.equipped_weapon.use_weapon(
		entity.weapon_component.aim_direction
	)
