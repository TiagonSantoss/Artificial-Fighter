class_name VisualEffectsComponent
extends EntityComponent

var visual_targets: Array[Node3D] = []
var is_flashing := false
var mesh_flash_material: StandardMaterial3D


func _ready() -> void:
	mesh_flash_material = StandardMaterial3D.new()
	mesh_flash_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh_flash_material.albedo_color = Color(1.0, 0.3, 0.3, 1.0)


func setup_visuals(targets: Array[Node3D]) -> void:
	visual_targets = targets


func on_damage(_hit: HitData) -> void:
	flash_red()


func flash_red(duration: float = 0.15) -> void:
	if not is_instance_valid(entity.mesh_instance):
		return

	# 1. Get current active material (or active override)
	var active_mat: Material = entity.mesh_instance.get_active_material(0)
	if active_mat == null:
		return

	# 2. Duplicate material so changes only affect THIS entity
	var unique_mat: BaseMaterial3D = active_mat.duplicate() as BaseMaterial3D
	if unique_mat == null:
		return

	# 3. Apply duplicated material as a local override
	entity.mesh_instance.material_override = unique_mat

	# 4. Flash red using albedo color modulation
	var original_color := unique_mat.albedo_color
	unique_mat.albedo_color = Color.RED

	# 5. Reset back to original color after duration
	await get_tree().create_timer(duration).timeout

	if is_instance_valid(entity.mesh_instance) and is_instance_valid(unique_mat):
		unique_mat.albedo_color = original_color
		# Optional: Clear override to revert to default shared material
		entity.mesh_instance.material_override = null
