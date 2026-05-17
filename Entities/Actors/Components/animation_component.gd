class_name AnimationComponent
extends EntityComponent

enum AnimMoveState {
	IDLE,
	WALK
}

enum AnimDirState {
	SIDE,
	UP,
	DOWN
}

var sprite: AnimatedSprite3D

var move_state: AnimMoveState = AnimMoveState.IDLE
var dir_state: AnimDirState = AnimDirState.DOWN
var warned_missing_anims: Dictionary = {}

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
	
	var dir: Vector3 = entity.movement_component.last_direction
	
	# -------------------------
	# IDLE CASE (no movement)
	# -------------------------
	if dir.length() < 0.01:
		var idle_anim := "idle_down"
		if sprite.sprite_frames and sprite.sprite_frames.has_animation(idle_anim):
			if sprite.animation != idle_anim:
				sprite.play(idle_anim)
		return
	
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
		sprite.flip_h = x < 0
	else:
		sprite.flip_h = false
		anim = "up" if z > 0 else "down"
	
	# -------------------------
	# STATE (walk/idle)
	# -------------------------
	var prefix := "walk_"
	anim = prefix + anim
	
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
