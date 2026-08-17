class_name VisualEffectsComponent
extends EntityComponent

var visual_targets: Array[Node] = []
var is_flashing := false
var is_blinking := false
var is_blocking_visual_active := false

var block_material_override: BaseMaterial3D = null
const BLOCK_COLOR = Color(0.4, 0.4, 0.4, 1.0)  # Gray for Sprite3D/2D

# --- RESTORED SETUP FUNCTION ---


func setup_visuals(targets: Array) -> void:
	visual_targets.assign(targets)


func on_damage(_hit: HitData) -> void:
	flash_red()


# --- ENUM HELPERS ---


func _has_mesh() -> bool:
	return (
		(
			entity.definition.visual_type
			in [EntityDefinition.VisualType.MESH_3D, EntityDefinition.VisualType.HYBRID]
		)
		and is_instance_valid(entity.mesh_instance)
	)


func _has_sprite() -> bool:
	return (
		(
			entity.definition.visual_type
			in [EntityDefinition.VisualType.SPRITE_3D, EntityDefinition.VisualType.HYBRID]
		)
		and is_instance_valid(entity.sprite)
	)


# --- BLOCKING VISUALS ---


func set_blocking_visuals(active: bool) -> void:
	if active == is_blocking_visual_active:
		return

	is_blocking_visual_active = active

	# Handle Mesh
	if _has_mesh():
		if active:
			var active_mat: Material = entity.mesh_instance.get_active_material(0)
			if active_mat:
				block_material_override = active_mat.duplicate() as BaseMaterial3D
				block_material_override.albedo_color = Color(0.4, 0.4, 0.4, 1.0)
				entity.mesh_instance.material_override = block_material_override
		else:
			block_material_override = null
			if not is_flashing:
				entity.mesh_instance.material_override = null

	# Handle Sprite3D
	if _has_sprite():
		if active:
			entity.sprite.modulate = BLOCK_COLOR
		else:
			if not is_flashing:
				entity.sprite.modulate = Color.WHITE


# --- FLASH LOGIC ---


func flash_red(duration: float = 0.15) -> void:
	_flash_color(Color.RED, duration)


func flash_blue(duration: float = 0.15) -> void:
	_flash_color(Color.BLUE, duration)


func flash_gray(duration: float = 0.15) -> void:
	_flash_color(Color(0.4, 0.4, 0.4, 1.0), duration)


func _flash_color(color: Color, duration: float) -> void:
	is_flashing = true

	# 1. Apply Flash
	if _has_mesh():
		var active_mat: Material = entity.mesh_instance.get_active_material(0)
		if active_mat:
			var unique_mat: BaseMaterial3D = active_mat.duplicate() as BaseMaterial3D
			if unique_mat:
				entity.mesh_instance.material_override = unique_mat
				unique_mat.albedo_color = color

	if _has_sprite():
		entity.sprite.modulate = color

	# Wait for duration
	await get_tree().create_timer(duration).timeout

	# 2. Restore Visuals
	is_flashing = false

	if _has_mesh():
		if is_blocking_visual_active and is_instance_valid(block_material_override):
			entity.mesh_instance.material_override = block_material_override
		else:
			entity.mesh_instance.material_override = null

	if _has_sprite():
		if is_blocking_visual_active:
			entity.sprite.modulate = BLOCK_COLOR
		else:
			entity.sprite.modulate = Color.WHITE


# --- I-FRAME BLINK LOGIC ---


func start_blinking(duration: float, blink_interval: float = 0.1) -> void:
	if is_blinking:
		return

	is_blinking = true
	var loops := int(duration / blink_interval)

	for i in range(loops):
		if _has_mesh():
			entity.mesh_instance.visible = not entity.mesh_instance.visible

		if _has_sprite():
			entity.sprite.visible = not entity.sprite.visible

		await get_tree().create_timer(blink_interval).timeout

	is_blinking = false

	if _has_mesh():
		entity.mesh_instance.visible = true

	if _has_sprite():
		entity.sprite.visible = true
