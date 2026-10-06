class_name PhysicalCard
extends Area3D

@export var speed: float = 15.0
@export var max_lifetime: float = 3.0

var _caster: Entity
var _card_instance: ItemInstance
var _direction: Vector3
var _time_alive: float = 0.0


func fire(caster: Entity, card_instance: ItemInstance, direction: Vector3) -> void:
	_caster = caster
	_card_instance = card_instance
	_direction = direction

	if _direction != Vector3.ZERO:
		# Calculate the angle on the XZ planerotation
		rotation.y = atan2(-_direction.x, -_direction.z)

	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	global_position += _direction * speed * delta

	_time_alive += delta
	if _time_alive >= max_lifetime:
		queue_free()


func _on_body_entered(body: Node3D) -> void:
	if body == _caster or body == GameAutoLoad._companion_entity:
		return

	if body is Entity:
		var card_def = _card_instance.definition as CardDefinition
		if card_def:
			card_def.play(_caster, body, _direction)

	queue_free()
