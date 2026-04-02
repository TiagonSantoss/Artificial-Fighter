extends Resource
class_name CellDefinition

@export var walkable: bool = true
@export var spawn: bool = false
@export var enemy_spawn: bool = false
@export var is_door: bool = false
@export var door_dir: Vector3i = Vector3i(0,0,0)
@export var door_type: String = "normal"
@export var tags: Array[String] = []
