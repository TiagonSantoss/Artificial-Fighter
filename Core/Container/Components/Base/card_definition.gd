class_name CardDefinition
extends ItemDefinition

enum CardType { INSTANT, DIRECTIONAL, PROJECTILE }
enum CardAxis { X, Z, ANY }

@export var card_type: CardType = CardType.INSTANT
@export var allowed_axis: CardAxis = CardAxis.ANY
@export var dual_fire: bool = false


func play(
	_caster: Entity, _target: Entity = null, _throw_direction: Vector3 = Vector3.ZERO
) -> void:
	pass
