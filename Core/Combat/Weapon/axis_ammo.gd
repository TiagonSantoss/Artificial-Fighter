class_name AxisAmmo
extends RefCounted

signal changed(group: Group, current: int, maximum: int)

enum Group { X, Z }

var total := 6  # ammo in circulation; either pool can hold all of it
var current := {Group.X: 0, Group.Z: 0}


static func group_of(axis: CameraPerspectiveState.Axis) -> Group:
	match axis:
		CameraPerspectiveState.Axis.X_POSITIVE, CameraPerspectiveState.Axis.X_NEGATIVE:
			return Group.X
	return Group.Z


static func other(group: Group) -> Group:
	return Group.Z if group == Group.X else Group.X


## Starts on X (everything)
func setup(total_ammo: int, start_in_x: int = -1) -> void:
	total = total_ammo
	var x := total if start_in_x < 0 else clampi(start_in_x, 0, total)
	current[Group.X] = x
	current[Group.Z] = total - x
	_emit_both()


func can_shoot(group: Group) -> bool:
	return current[group] > 0


## Returns false (and changes nothing) when 'group' doesnt have nothing
func fire(group: Group, amount: int = 1) -> bool:
	if current[group] < amount:
		FmodServer.play_one_shot("event:/SFX/UI/Error")
		SceneManager.shake(4.0,0.3)
		GameAutoLoad.rotate_by(90)
		return false

	var target := other(group)
	current[group] -= amount
	current[target] = mini(current[target] + amount, total)
	_emit_both()
	return true


func add(group: Group, amount: int) -> void:
	total += amount
	current[group] += amount
	_emit_both()


func _emit_both() -> void:
	changed.emit(Group.X, current[Group.X], total)
	changed.emit(Group.Z, current[Group.Z], total)