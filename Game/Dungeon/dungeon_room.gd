class_name DungeonRoom
extends RefCounted

var definition: RoomDefinition
var world_origin: Vector3

var node: Node3D
var offset: Vector3i

var spawned := false
var cleared := false

var player_spawns: Array[Vector3i]
var enemy_spawns: Array[Vector3i]
var enemies: Array[Entity]

var has_encounter := true
