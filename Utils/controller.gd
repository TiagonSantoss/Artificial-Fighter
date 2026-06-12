class_name Controller
extends Resource

var aim_target: Variant

func get_actions(_actor: Entity, _delta: float) -> Array[Action]:
	return []

func get_aim_target(_actor: Entity) -> Variant:
	return null

func update_aim(actor: Entity) -> void:
	aim_target = get_aim_target(actor)
