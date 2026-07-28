class_name WeaponVisualComponent
extends WeaponComponent

var dynamic_aim_offset_amount: float = 2.0
var shader_mat: ShaderMaterial

@onready var sprite: AnimatedSprite3D = $"../../AnimatedSprite3D"
@onready var muzzle: Marker3D = $"../../Muzzle"


func apply_definition() -> void:
	var definition := weapon.definition

	sprite.sprite_frames = definition.sprite_frames
	sprite.texture_filter = definition.texture_filter
	sprite.modulate = definition.modulate
	sprite.scale = definition.sprite_scale

	if sprite.sprite_frames:
		sprite.play(definition.default_animation)

	sprite.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	sprite.position = Vector3.ZERO

	shader_mat = ShaderMaterial.new()
	shader_mat.shader = preload("res://assets/shaders/weapon_billboard.gdshader")
	sprite.material_override = shader_mat


func _process(_delta: float) -> void:
	if shader_mat and sprite and sprite.sprite_frames:
		var current_texture = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
		shader_mat.set_shader_parameter("main_texture", current_texture)


func update_aim(dir: Vector3) -> void:
	if dir.length_squared() <= 0.001:
		return

	var normalized_dir := dir.normalized()

	# 1. Get Camera Basis (for screen/view space calculations)
	var camera := get_viewport().get_camera_3d()
	var cam_basis := Basis.IDENTITY
	if camera != null:
		cam_basis = camera.global_transform.basis.orthonormalized()

	# 2. Transform aim direction into Camera Local Space
	# cam_dir.x = Right/Left on screen
	# cam_dir.y = Up/Down on screen (or cam_dir.z for forward depth)
	var cam_dir := cam_basis.inverse() * normalized_dir

	# 3. 3D World Rotation for Weapon (Yaw relative to world/camera)
	var angle_y := atan2(-normalized_dir.z, normalized_dir.x)
	weapon.global_rotation.y = angle_y

	# 4. Shader Sprite Rotation & Flipping (View Space)
	if shader_mat != null:
		# Use cam_dir.x to determine left/right relative to screen/camera
		var look_left := cam_dir.x < 0.0
		shader_mat.set_shader_parameter("flip_gun", look_left)

		# Calculate sprite angle in camera/view projection
		# Depending on camera pitch angle, project onto X-Y screen plane:
		var sprite_angle := (
			atan2(-cam_dir.y, cam_dir.x) if abs(cam_dir.y) > 0.1 else atan2(cam_dir.z, cam_dir.x)
		)

		var definition := weapon.definition
		var tweak_rad := deg_to_rad(definition.sprite_rotation_offset)
		sprite_angle += tweak_rad

		shader_mat.set_shader_parameter("sprite_rotation", sprite_angle)

		# 5. Dynamic Offset based on Camera Right direction
		var base_offset := definition.sprite_offset
		var dynamic_x := base_offset.x + (cam_dir.x * dynamic_aim_offset_amount)

		var offset_2d := Vector2(dynamic_x, base_offset.y)
		shader_mat.set_shader_parameter("gun_offset", offset_2d)


func get_muzzle_position() -> Vector3:
	return muzzle.global_position
