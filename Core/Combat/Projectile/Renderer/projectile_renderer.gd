extends Node

@onready var mm: MultiMeshInstance3D = $MultiMeshInstance3D
var multimesh: MultiMesh

const MAX_INSTANCES := 20000

func _ready() -> void:
	if mm == null:
		push_error("ProjectileRenderer: MultiMeshInstance3D child node not found!")
		return
		
	# 1. Dynamically build a brand-new MultiMesh resource from scratch.
	# This ensures it has a clean structural setup without any rigid layout locks.
	var new_multimesh := MultiMesh.new()
	
	# 2. Configure structural property layouts BEFORE setting the maximum instance count
	new_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	new_multimesh.use_custom_data = true 
	new_multimesh.instance_count = MAX_INSTANCES
	
	# 3. Carry over your QuadMesh / Material template configurations from the original node
	if mm.multimesh and mm.multimesh.mesh:
		new_multimesh.mesh = mm.multimesh.mesh
		
	# 4. Swap out the active resource references
	mm.multimesh = new_multimesh
	multimesh = new_multimesh


func _process(_delta: float) -> void:
	if multimesh == null:
		return
		
	var projectiles = AutoProjectileSystem.active_projectiles
	var count = min(projectiles.size(), MAX_INSTANCES)
	multimesh.visible_instance_count = count
	
	# 5. Build the master data array (Exactly 16 floats * MAX_INSTANCES)
	var mega_buffer := PackedFloat32Array()
	mega_buffer.resize(MAX_INSTANCES * 16) 
	
	var idx := 0
	
	for i in count:
		var p = projectiles[i]
		
		# Calculate transformation basis
		var b := Basis.IDENTITY
		if p.definition:
			b = b.scaled(p.definition.scale)
			
		if p.definition and p.definition.rotates_to_velocity and p.velocity.length_squared() > 0.001:
			b = Basis.looking_at(p.velocity.normalized(), Vector3.UP)
			b = b.scaled(p.definition.scale)
		
		# Write Transform3D data (Floats 0-11)
		mega_buffer[idx]     = b.x.x; mega_buffer[idx + 1]  = b.y.x; mega_buffer[idx + 2]  = b.z.x; mega_buffer[idx + 3]  = p.position.x
		mega_buffer[idx + 4] = b.x.y; mega_buffer[idx + 5]  = b.y.y; mega_buffer[idx + 6]  = b.z.y; mega_buffer[idx + 7]  = p.position.y
		mega_buffer[idx + 8] = b.x.z; mega_buffer[idx + 9]  = b.y.z; mega_buffer[idx + 10] = b.z.z; mega_buffer[idx + 11] = p.position.z
		
		# Write Custom Data parameters (Floats 12-15)
		mega_buffer[idx + 12] = float(p.frame) / 255.0
		mega_buffer[idx + 13] = float(p.definition.atlas_row) / 255.0
		mega_buffer[idx + 14] = 0.0
		mega_buffer[idx + 15] = 0.0
		
		idx += 16
		
	# 6. Push the master array data directly to the GPU
	multimesh.buffer = mega_buffer
