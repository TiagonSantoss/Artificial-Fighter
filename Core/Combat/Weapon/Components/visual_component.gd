class_name WeaponVisualComponent
extends WeaponComponent

@onready var sprite: AnimatedSprite3D = $"../../AnimatedSprite3D"
@onready var muzzle: Marker3D = $"../../Muzzle"

func apply_definition() -> void:
	var definition := weapon.definition
	
	sprite.sprite_frames = definition.sprite_frames
	sprite.texture_filter = definition.texture_filter
	sprite.modulate = definition.modulate
	sprite.billboard = definition.billboard
	sprite.scale = definition.sprite_scale
	sprite.position = definition.sprite_offset
	sprite.play(definition.default_animation)

func update_aim(dir: Vector3) -> void:
	var angle_y := atan2(-dir.z, dir.x)
	
	weapon.global_rotation.y = angle_y
	sprite.flip_v = dir.x < 0

func get_muzzle_position() -> Vector3:
	return muzzle.global_position
