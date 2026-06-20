class_name RoomDefinition
extends Resource

enum RoomCategory {
	START,
	COMBAT,
	ELITE,
	BOSS
}
@export_category("Data")
@export var id: String
@export var scene: PackedScene

@export_category("Layout")
@export var tags: Array[String] = []
@export var category: RoomCategory
@export var size: Vector2i = Vector2i(1,1)
@export var available_doors: Array[DoorSocket.Direction]

@export_category("Combat")
@export var has_encounter: bool = false
@export var encounter_pool: Array[EncounterDefinition]

func has_door(dir: DoorSocket.Direction) -> bool:
	return available_doors.has(dir)

func get_random_encounter() -> EncounterDefinition:
	if encounter_pool.is_empty():
		return null
	
	return encounter_pool.pick_random()
