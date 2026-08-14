class_name VisualEffectsComponent
extends EntityComponent

var visual_targets: Array[Node3D] = []
var is_flashing := false
var mesh_flash_material: StandardMaterial3D

# --- NEW: Variables for block state ---
var is_blocking_visual_active := false
var block_material_override: BaseMaterial3D = null


func _ready() -> void:
	mesh_flash_material = StandardMaterial3D.new()
	mesh_flash_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh_flash_material.albedo_color = Color(1.0, 0.3, 0.3, 1.0)


func setup_visuals(targets: Array[Node3D]) -> void:
	visual_targets = targets


func on_damage(_hit: HitData) -> void:
	flash_red()


# --- NEW: Toggle function for the gray block effect ---
func set_blocking_visuals(active: bool) -> void:
	if active == is_blocking_visual_active or not is_instance_valid(entity.mesh_instance):
		return

	is_blocking_visual_active = active

	if active:
		var active_mat: Material = entity.mesh_instance.get_active_material(0)
		if active_mat:
			block_material_override = active_mat.duplicate() as BaseMaterial3D
			block_material_override.albedo_color = Color(0.4, 0.4, 0.4, 1.0)  # Gray color
			entity.mesh_instance.material_override = block_material_override
	else:
		block_material_override = null
		# Only clear the override entirely if a flash isn't currently happening
		if not is_flashing:
			entity.mesh_instance.material_override = null


func flash_red(duration: float = 0.15) -> void:
	if not is_instance_valid(entity.mesh_instance):
		return

	is_flashing = true  # Lock the flash state

	var active_mat: Material = entity.mesh_instance.get_active_material(0)
	if active_mat == null:
		return

	var unique_mat: BaseMaterial3D = active_mat.duplicate() as BaseMaterial3D
	if unique_mat == null:
		return

	entity.mesh_instance.material_override = unique_mat
	var original_color := unique_mat.albedo_color
	unique_mat.albedo_color = Color.RED

	await get_tree().create_timer(duration).timeout

	if is_instance_valid(entity.mesh_instance):
		is_flashing = false
		# NEW: If we are blocking, restore the gray override. Otherwise, clear it.
		if is_blocking_visual_active and is_instance_valid(block_material_override):
			entity.mesh_instance.material_override = block_material_override
		else:
			entity.mesh_instance.material_override = null


func flash_blue(duration: float = 0.15) -> void:
	if not is_instance_valid(entity.mesh_instance):
		return

	is_flashing = true

	var active_mat: Material = entity.mesh_instance.get_active_material(0)
	if active_mat == null:
		return

	var unique_mat: BaseMaterial3D = active_mat.duplicate() as BaseMaterial3D
	if unique_mat == null:
		return

	entity.mesh_instance.material_override = unique_mat
	var _original_color := unique_mat.albedo_color
	unique_mat.albedo_color = Color.BLUE

	await get_tree().create_timer(duration).timeout

	if is_instance_valid(entity.mesh_instance):
		is_flashing = false
		if is_blocking_visual_active and is_instance_valid(block_material_override):
			entity.mesh_instance.material_override = block_material_override
		else:
			entity.mesh_instance.material_override = null
