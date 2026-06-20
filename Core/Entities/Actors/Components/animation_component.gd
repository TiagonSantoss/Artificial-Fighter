class_name AnimationComponent
extends EntityComponent

enum AnimMoveState {
	IDLE,
	WALK,
	JUMP
}

enum AnimDirState {
	SIDE,
	UP,
	DOWN
}

enum AirState {
	GROUNDED,
	RISING,
	FALLING
}

var sprite: AnimatedSprite3D

var move_state: AnimMoveState = AnimMoveState.IDLE
var air_state: AirState = AirState.GROUNDED
var dir_state: AnimDirState = AnimDirState.DOWN
var facing_left := false
var facing_direction: Vector3 = Vector3.FORWARD

var warned_missing_anims: Dictionary = {}

var jump_phase := 0  # 1 = rising, -1 = falling, 0 = grounded

func set_sprite(entity_sprite: AnimatedSprite3D) -> void:
	sprite = entity_sprite

func configure_visuals(definition: EntityDefinition) -> void:
	sprite.sprite_frames = definition.sprite_frames
	sprite.texture_filter = definition.texture_filter
	sprite.modulate = definition.modulate
	sprite.billboard = definition.billboard
	sprite.scale = definition.sprite_scale
	sprite.play(definition.default_animation)

func update_animation() -> void:
	if entity == null or sprite == null:
		return
	
	var vy := entity.movement_component.entity.velocity.y
	
	if entity.is_on_floor():
		air_state = AirState.GROUNDED
	elif vy > 0.1:
		air_state = AirState.RISING
	else:
		air_state = AirState.FALLING
	
	var velocity := entity.movement_component.movement_velocity
	
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	var is_moving := horizontal_speed > 0.05
	var dir: Vector3 = facing_direction
	
	# -------------------------
	# IDLE CASE (no movement)
	# -------------------------
	if dir.length() < 0.01:
		var idle_anim := "idle_" + get_dir_name()
		sprite.flip_h = facing_left
		
		if sprite.sprite_frames and sprite.sprite_frames.has_animation(idle_anim):
			if sprite.animation != idle_anim:
				sprite.play(idle_anim)
		return
	
	if dir.length() > 0.01:
		facing_direction = dir.normalized()
	
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	
	# -------------------------
	# CAMERA SPACE
	# -------------------------
	var cam_forward := -cam.global_transform.basis.z
	var cam_right := cam.global_transform.basis.x
	
	var x := dir.dot(cam_right)
	var z := dir.dot(cam_forward)
	
	var anim := ""
	
	# -------------------------
	# DIRECTION
	# -------------------------
	if abs(x) > abs(z):
		anim = "side"
		facing_left = x < 0
		sprite.flip_h = facing_left
	else:
		sprite.flip_h = false
		anim = "up" if z > 0 else "down"
		
	if abs(x) > abs(z):
		dir_state = AnimDirState.SIDE
		facing_left = x < 0
		sprite.flip_h = facing_left
	else:
		sprite.flip_h = false
		
		if z > 0:
			dir_state = AnimDirState.UP
		else:
			dir_state = AnimDirState.DOWN
	
	if entity.movement_component.last_direction.length() > 0.01:
		facing_direction = entity.movement_component.last_direction.normalized()
	
	# -------------------------
	# STATES
	# -------------------------
	var prefix := ""
	
	if is_moving:
		facing_direction = entity.movement_component.last_direction.normalized()
	
	match air_state:
		AirState.GROUNDED:
			if is_moving:
				prefix = "walk"
			else:
				prefix = "idle"
		AirState.RISING:
			prefix = "jump_up"
		AirState.FALLING:
			prefix = "jump_down"
	
	anim = "%s_%s" % [prefix, get_dir_name()]
	
	print(anim)
	
	# -------------------------
	# PLAY SAFELY
	# -------------------------
	if sprite.sprite_frames and sprite.sprite_frames.has_animation(anim):
		if sprite.animation != anim:
			sprite.play(anim)
	else:
		if not warned_missing_anims.has(anim):
			warned_missing_anims[anim] = true
			push_warning("Missing animation: %s (entity %s)" % [anim, entity.entity_id])

func get_dir_name() -> String:
	match dir_state:
		AnimDirState.UP:
			return "up"
		AnimDirState.DOWN:
			return "down"
		AnimDirState.SIDE:
			return "side"
			
	return "down"
