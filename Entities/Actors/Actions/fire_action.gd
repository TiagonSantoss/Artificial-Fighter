class_name FireAction
extends Action

var direction: Vector3

func _init(dir: Vector3):
	direction = dir

func execute(entity, _delta):
	entity.weapon_component.equipped_weapon.fire(
		direction
	)
