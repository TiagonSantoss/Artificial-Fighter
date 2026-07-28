extends Node

const MAX_INSTANCES := 3000

var multimesh: MultiMesh
@onready var mm: MultiMeshInstance3D = $MultiMeshInstance3D


func _ready() -> void:
	if mm == null:
		push_error("ProjectileRenderer: MultiMeshInstance3D child node not found!")
		return

	var new_multimesh := MultiMesh.new()

	new_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	new_multimesh.use_custom_data = true
	new_multimesh.instance_count = MAX_INSTANCES

	if mm.multimesh and mm.multimesh.mesh:
		new_multimesh.mesh = mm.multimesh.mesh

	mm.multimesh = new_multimesh
	multimesh = new_multimesh


func _process(_delta: float) -> void:
	if multimesh == null:
		return

	var cam := get_viewport().get_camera_3d()
	var cam_basis := Basis.IDENTITY
	if cam:
		cam_basis = cam.global_transform.basis

	var projectiles = AutoProjectileSystem.active_projectiles
	var count = min(projectiles.size(), MAX_INSTANCES)
	multimesh.visible_instance_count = count

	var mega_buffer := PackedFloat32Array()
	mega_buffer.resize(MAX_INSTANCES * 16)

	var idx := 0

	for i in count:
		var p = projectiles[i]

		# Calculate transformation basis
		var b := Basis.IDENTITY

		if (
			p.definition
			and p.definition.rotates_to_velocity
			and p.velocity.length_squared() > 0.001
		):
			var direction = p.velocity.normalized()

			# SAFE UP-VECTOR GUARD: Avoid geometric breakdown if the bullet moves parallel to world UP
			var up_vector := Vector3.UP
			if abs(direction.dot(Vector3.UP)) > 0.99:
				up_vector = Vector3.FORWARD

			b = Basis.looking_at(direction, up_vector)

		# Apply scaling after rotation calculation to avoid mesh shearing matrix errors
		if p.definition:
			b = b.scaled(p.definition.scale)

		# Write Transform3D data (Floats 0-11)
		mega_buffer[idx] = b.x.x
		mega_buffer[idx + 1] = b.y.x
		mega_buffer[idx + 2] = b.z.x
		mega_buffer[idx + 3] = p.position.x
		mega_buffer[idx + 4] = b.x.y
		mega_buffer[idx + 5] = b.y.y
		mega_buffer[idx + 6] = b.z.y
		mega_buffer[idx + 7] = p.position.y
		mega_buffer[idx + 8] = b.x.z
		mega_buffer[idx + 9] = b.y.z
		mega_buffer[idx + 10] = b.z.z
		mega_buffer[idx + 11] = p.position.z

		# Read columns and rows directly from the projectile's definition resource
		var frame_col: float = 0.0
		var frame_row: float = 0.0

		if p.definition:
			if "atlas_column" in p.definition:
				frame_col = float(p.definition.atlas_column)
			if "atlas_row" in p.definition:
				frame_row = float(p.definition.atlas_row)

		var angle: float = 0.0
		if p.velocity.length_squared() > 0.001:
			var cam_local_velocity = cam_basis.inverse() * p.velocity

			angle = atan2(cam_local_velocity.z, cam_local_velocity.x)

		mega_buffer[idx + 12] = frame_col / 255.0
		mega_buffer[idx + 13] = frame_row / 255.0
		mega_buffer[idx + 14] = angle
		mega_buffer[idx + 15] = 0.0

		idx += 16

	multimesh.buffer = mega_buffer
