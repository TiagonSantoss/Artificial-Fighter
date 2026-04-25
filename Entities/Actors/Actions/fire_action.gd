class_name FireAction
extends Action


func execute(entity, _delta):

	var target = entity.get_mouse_world()

	if target:
		var dir = target - entity.global_position
		dir.y = 0
		dir = dir.normalized()
		entity.equipped_weapon.fire(dir)
