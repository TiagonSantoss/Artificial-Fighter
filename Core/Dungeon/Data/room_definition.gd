class_name RoomDefinition
extends Resource

enum RoomCategory {
	START,
	COMBAT,
	ELITE,
	BOSS
}

@export var id: String
@export var scene: PackedScene

@export var tags: Array[String] = []
@export var category: RoomCategory
@export var size: Vector2i = Vector2i(1,1)

@export var available_doors: Array[DoorSocket.Direction]
@export var encounter_pool: Array[EncounterDefinition]

func has_door(dir: DoorSocket.Direction) -> bool:
	return available_doors.has(dir)
