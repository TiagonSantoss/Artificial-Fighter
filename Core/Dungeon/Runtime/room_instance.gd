class_name RoomInstance
extends RefCounted

var room_id: String
var definition: RoomDefinition

var layout_position: Vector2i
var world_origin: Vector3

var node: Node3D

var spawned := false
var cleared := false

var player_spawns: Array[Vector3i]
var enemy_spawns: Array[Vector3i]
var enemies: Array[Entity]

var encounter_enabled := true
