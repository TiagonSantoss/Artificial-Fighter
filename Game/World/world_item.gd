class_name WorldItem
extends RigidBody3D

@onready var sprite: Sprite3D = $Area3D/Sprite3D
@onready var spark: GPUParticles3D = $Area3D/Spark
@onready var area_3d: Area3D = $Area3D

var instance: ItemInstance

signal picked_up(instance: ItemInstance)

var t := 0.0

func _ready():
	sleeping = false
	apply_impulse(Vector3.ZERO)
	area_3d.body_entered.connect(_on_body_entered)
	
	if instance != null:
		_apply_instance()

func _process(delta):
	if sprite:
		sprite.look_at(get_viewport().get_camera_3d().global_position)
	t += delta
	global_position.y += sin(t * 2.0) * 0.002

func push_item(impulse: Vector3) -> void:
	apply_central_impulse(impulse)

func _on_body_entered(body: Node) -> void:
	if instance == null:
		return
	
	# Weapon pickup
	if body is Entity:
		if body.weapon_component != null:
			if body.weapon_component.equipped_weapon.equip_behavior(instance):
				picked_up.emit(instance)
				queue_free()
				return
		
		if body.has_method("inventory"):
			if body.inventory.add(instance):
				picked_up.emit(instance)
				queue_free()
				return

func _apply_instance() -> void:
	var def := instance.definition
	
	if def == null:
		return
	
	# Sprite
	if def.icon:
		sprite.texture = def.icon
	
	# Optional scaling
	sprite.scale = Vector3.ONE * 0.5
	
	# Spark effect (optional, safe fallback)
	if spark:
		spark.emitting = true

func set_instance(new_instance: ItemInstance) -> void:
	instance = new_instance
	
	if is_inside_tree():
		_apply_instance()
