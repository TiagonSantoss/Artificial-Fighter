class_name WeaponVisualComponent
extends WeaponComponent

@onready var sprite: AnimatedSprite3D = $"../../AnimatedSprite3D"
@onready var muzzle: Marker3D = $"../../Muzzle"

var shader_mat: ShaderMaterial

func apply_definition() -> void:
	var definition := weapon.definition
	
	sprite.sprite_frames = definition.sprite_frames
	sprite.texture_filter = definition.texture_filter
	sprite.modulate = definition.modulate
	sprite.scale = definition.sprite_scale
	
	# 🟢 SAFETY CHECK: Only play the animation if sprite_frames is assigned
	if sprite.sprite_frames:
		sprite.play(definition.default_animation)
	
	sprite.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	sprite.position = Vector3.ZERO
	
	shader_mat = ShaderMaterial.new()
	shader_mat.shader = preload("res://assets/shaders/weapon_billboard.gdshader")
	sprite.material_override = shader_mat


func _process(_delta: float) -> void:
	# 🟢 SAFETY CHECK: Added "sprite.sprite_frames" to prevent the null value crash
	if shader_mat and sprite and sprite.sprite_frames:
		var current_texture = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
		shader_mat.set_shader_parameter("main_texture", current_texture)


func update_aim(dir: Vector3) -> void:
	var angle_y := atan2(-dir.z, dir.x)
	weapon.global_rotation.y = angle_y
	
	if shader_mat and dir.length_squared() > 0.001:
		var cam := get_viewport().get_camera_3d()
		if cam:
			var cam_basis := cam.global_transform.basis
			var cam_local_dir := cam_basis.inverse() * dir.normalized()
			
			var sprite_angle := atan2(cam_local_dir.z, cam_local_dir.x)
			
			var definition := weapon.definition
			var look_left := cam_local_dir.x < 0.0
			shader_mat.set_shader_parameter("flip_gun", look_left)
			
			var tweak_rad := deg_to_rad(definition.sprite_rotation_offset)
			sprite_angle += tweak_rad
				
			shader_mat.set_shader_parameter("sprite_rotation", sprite_angle)
			
			var base_offset := definition.sprite_offset
			var offset_2d := Vector2(base_offset.x, base_offset.y)
			shader_mat.set_shader_parameter("gun_offset", offset_2d)


func get_muzzle_position() -> Vector3:
	return muzzle.global_position
