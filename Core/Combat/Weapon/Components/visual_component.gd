class_name WeaponVisualComponent
extends WeaponComponent

var dynamic_aim_offset_amount: float = 2.0
var shader_mat: ShaderMaterial

@onready var sprite: AnimatedSprite3D = $"../../AnimatedSprite3D"
@onready var muzzle: Marker3D = $"../../AnimatedSprite3D/Muzzle"


func apply_definition() -> void:
	var definition := weapon.definition

	sprite.sprite_frames = definition.sprite_frames
	sprite.texture_filter = definition.texture_filter
	sprite.modulate = definition.modulate
	sprite.scale = definition.sprite_scale

	GState.weapon_changed.emit(WeaponState.new(weapon.wielder, sprite))

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


func play_swing_animation(_direction: Vector3):
	var mat = sprite.material_override
	var tween = create_tween()

	var swing_target = -1.5 if mat.get_shader_parameter("flip_gun") else 1.5

	var windup_angle = -0.7 * sign(swing_target)  # Pulls back much further
	var windup_time = 0.2  # Takes twice as long
	(
		tween
		. tween_method(set_swing.bind(mat), 0.0, windup_angle, windup_time)
		. set_trans(Tween.TRANS_QUAD)  # Makes it ease into the pullback
		. set_ease(Tween.EASE_OUT)
	)
	tween.tween_method(set_swing.bind(mat), windup_angle, swing_target, 0.15).set_trans(
		Tween.TRANS_SINE
	)
	tween.tween_method(set_swing.bind(mat), swing_target, 0.0, 0.25).set_trans(Tween.TRANS_QUAD)


func set_swing(value: float, mat: Material):
	mat.set_shader_parameter("swing_angle", value)


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


func create_phantom_weapon(aim_dir: Vector3, delay: float = 0.0) -> void:
	if delay > 0:
		await get_tree().create_timer(delay, false).timeout

	if not is_instance_valid(sprite):
		return

	# 1. Create a temporary AnimatedSprite3D copy
	var phantom = AnimatedSprite3D.new()
	phantom.sprite_frames = sprite.sprite_frames
	phantom.animation = sprite.animation
	phantom.frame = sprite.frame
	phantom.pixel_size = sprite.pixel_size
	phantom.billboard = sprite.billboard
	phantom.scale = sprite.scale

	# 2. Setup the Shader & Animation Sync
	var duplicate_mat = null
	if shader_mat != null:
		duplicate_mat = shader_mat.duplicate()
		phantom.material_override = duplicate_mat

		# FIX 1: The custom shader needs its texture manually updated every frame!
		# This inline signal forces the phantom to animate exactly like the main _process loop does.
		phantom.frame_changed.connect(
			func():
				if is_instance_valid(phantom) and phantom.sprite_frames:
					var tex = phantom.sprite_frames.get_frame_texture(
						phantom.animation, phantom.frame
					)
					duplicate_mat.set_shader_parameter("main_texture", tex)
		)

		# Force the very first frame to load immediately
		if phantom.sprite_frames:
			var tex = phantom.sprite_frames.get_frame_texture(phantom.animation, phantom.frame)
			duplicate_mat.set_shader_parameter("main_texture", tex)

		# Invert the screen visuals
		var current_flip = shader_mat.get_shader_parameter("flip_gun")
		duplicate_mat.set_shader_parameter("flip_gun", not current_flip)

		var current_offset = shader_mat.get_shader_parameter("gun_offset")
		if current_offset != null:
			current_offset.x *= -1.0
			duplicate_mat.set_shader_parameter("gun_offset", current_offset)

	phantom.modulate = Color(1, 1, 1, 0.7)

	# FIX 2: Attach it directly to the Wielder (Player).
	# This prevents it from spinning wildly if you move your mouse while it's fading out!
	weapon.wielder.add_child(phantom)

	# FIX 3: Push it 1.2 meters away in pure World Space using the aim direction.
	# (Since BackSlashBehavior reverses aim_dir before calling this, it pushes perfectly backward)
	phantom.global_position = weapon.wielder.global_position + (aim_dir.normalized() * 1.2)

	# Play the sprite so the frame_changed signal actually fires!
	phantom.play(sprite.animation)

	# 4. Play the shader swing animation
	if duplicate_mat != null:
		var swing_tween = create_tween()
		var swing_target = -1.5 if duplicate_mat.get_shader_parameter("flip_gun") else 1.5
		var windup_angle = -0.7 * sign(swing_target)

		(
			swing_tween
			. tween_method(set_swing.bind(duplicate_mat), 0.0, windup_angle, 0.2)
			. set_trans(Tween.TRANS_QUAD)
			. set_ease(Tween.EASE_OUT)
		)
		(
			swing_tween
			. tween_method(set_swing.bind(duplicate_mat), windup_angle, swing_target, 0.15)
			. set_trans(Tween.TRANS_SINE)
		)
		swing_tween.tween_method(set_swing.bind(duplicate_mat), swing_target, 0.0, 0.25).set_trans(
			Tween.TRANS_QUAD
		)

	# 5. Fade out
	var fade_tween = create_tween()
	fade_tween.tween_property(phantom, "modulate:a", 0.0, 0.5).set_trans(Tween.TRANS_QUAD)
	fade_tween.tween_callback(phantom.queue_free)
