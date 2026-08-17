class_name AnimationComponent
extends EntityComponent

enum AnimMoveState { IDLE, WALK, JUMP }
enum AnimDirState { SIDE, UP, DOWN }
enum AirState { GROUNDED, RISING, FALLING }

var sprite: AnimatedSprite3D
var mesh_instance: MeshInstance3D

var move_state: AnimMoveState = AnimMoveState.IDLE
var air_state: AirState = AirState.GROUNDED
var dir_state: AnimDirState = AnimDirState.DOWN
var facing_left := false
var facing_direction: Vector3 = Vector3.FORWARD

var warned_missing_anims: Dictionary = {}


func set_visual_nodes(p_sprite: AnimatedSprite3D, p_mesh: MeshInstance3D = null) -> void:
	sprite = p_sprite
	mesh_instance = p_mesh


func configure_visuals(definition: EntityDefinition) -> Array[Node3D]:
	var active_visuals: Array[Node3D] = []

	if entity == null:
		return active_visuals

	match definition.visual_type:
		EntityDefinition.VisualType.SPRITE_3D:
			if is_instance_valid(sprite):
				sprite.sprite_frames = definition.sprite_frames
				sprite.modulate = definition.modulate
				sprite.billboard = definition.billboard
				sprite.texture_filter = definition.texture_filter
				sprite.scale = definition.sprite_scale
				sprite.visible = true

				if (
					definition.sprite_frames
					and definition.sprite_frames.has_animation(definition.default_animation)
				):
					sprite.play(definition.default_animation)

				active_visuals.append(sprite)

			if is_instance_valid(mesh_instance):
				mesh_instance.visible = false

		EntityDefinition.VisualType.MESH_3D:
			if is_instance_valid(sprite):
				sprite.visible = false

			if not is_instance_valid(mesh_instance):
				mesh_instance = MeshInstance3D.new()
				mesh_instance.name = "MeshInstance3D"
				entity.add_child(mesh_instance)

			mesh_instance.mesh = definition.mesh
			if definition.material_override:
				mesh_instance.material_override = definition.material_override
			mesh_instance.scale = definition.mesh_scale
			mesh_instance.visible = true

			active_visuals.append(mesh_instance)

		EntityDefinition.VisualType.HYBRID:
			if is_instance_valid(sprite):
				sprite.sprite_frames = definition.sprite_frames
				sprite.modulate = definition.modulate
				sprite.billboard = definition.billboard
				sprite.texture_filter = definition.texture_filter
				sprite.scale = definition.sprite_scale
				sprite.visible = true

				if (
					definition.sprite_frames
					and definition.sprite_frames.has_animation(definition.default_animation)
				):
					sprite.play(definition.default_animation)

				active_visuals.append(sprite)

			if not is_instance_valid(mesh_instance):
				mesh_instance = MeshInstance3D.new()
				mesh_instance.name = "MeshInstance3D"
				entity.add_child(mesh_instance)

			mesh_instance.mesh = definition.mesh
			if definition.material_override:
				mesh_instance.material_override = definition.material_override
			mesh_instance.scale = definition.mesh_scale
			mesh_instance.visible = true

			active_visuals.append(mesh_instance)

	return active_visuals


func rotate_mesh_towards_velocity(
	mesh: MeshInstance3D, velocity: Vector3, delta: float, rotation_speed: float = 10.0
) -> void:
	# Ignore Y velocity so the model doesn't tilt up or down when jumping/falling
	var horizontal_velocity := Vector3(velocity.x, 0.0, velocity.z)

	# Only rotate if the entity is actually moving
	if horizontal_velocity.length_squared() < 0.01:
		return

	# Calculate the angle of movement on the horizontal plane
	var target_angle := atan2(horizontal_velocity.x, horizontal_velocity.z)

	# Smoothly interpolate the current Y rotation toward the target angle
	mesh.rotation.y = lerp_angle(mesh.rotation.y, target_angle, rotation_speed * delta)


func update_animation() -> void:
	if entity == null or not is_instance_valid(sprite) or not sprite.visible:
		return

	var vy := entity.movement_component.entity.velocity.y

	if entity.is_on_floor():
		air_state = AirState.GROUNDED
	elif vy > 0.1:
		air_state = AirState.RISING
	else:
		air_state = AirState.FALLING

	var velocity := entity.movement_component.movement_velocity
	var is_moving := Vector2(velocity.x, velocity.z).length() > 0.05
	var dir: Vector3 = facing_direction

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

	var cam_forward := -cam.global_transform.basis.z
	var cam_right := cam.global_transform.basis.x

	var x := dir.dot(cam_right)
	var z := dir.dot(cam_forward)

	if abs(x) > abs(z):
		dir_state = AnimDirState.SIDE
		facing_left = x < 0
		sprite.flip_h = facing_left
	else:
		sprite.flip_h = false
		dir_state = AnimDirState.UP if z > 0 else AnimDirState.DOWN

	if entity.movement_component.last_direction.length() > 0.01:
		facing_direction = entity.movement_component.last_direction.normalized()

	var prefix := ""
	if is_moving:
		facing_direction = entity.movement_component.last_direction.normalized()

	match air_state:
		AirState.GROUNDED:
			prefix = "walk" if is_moving else "idle"
		AirState.RISING:
			prefix = "jump_up"
		AirState.FALLING:
			prefix = "jump_down"

	var anim := "%s_%s" % [prefix, get_dir_name()]

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
