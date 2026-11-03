class_name RoomVariant
extends RefCounted

var definition: RoomDefinition
var rotation_steps: int = 0  # 0..3, each step is 90° clockwise


func get_doors() -> Array[DoorSocket.Direction]:
	var result: Array[DoorSocket.Direction] = []
	for d in definition.available_doors:
		result.append(DirUtil.rotate(d, rotation_steps))
	return result


func get_size() -> Vector2i:
	var s := definition.size
	return Vector2i(s.y, s.x) if rotation_steps % 2 == 1 else s
