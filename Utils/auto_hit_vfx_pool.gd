extends Node

const HIT_VFX_SCENE := preload("res://Utils/HitVFX.tscn")

var pool: Array[HitVFX] = []
var world: Node

func set_world(parent: Node):
	world = parent

func spawn(position: Vector3, normal: Vector3):
	var vfx: HitVFX
	
	if pool.is_empty():
		vfx = HIT_VFX_SCENE.instantiate()
	else:
		vfx = pool.pop_back()
	
	world.add_child(vfx)
	
	vfx.global_position = position
	vfx.basis = Basis.looking_at(normal)
	vfx.rotation.y = randf() * TAU
	
	vfx.play()
	
	return vfx

func release(vfx: HitVFX):
	if vfx.get_parent():
		vfx.get_parent().remove_child(vfx)
	
	pool.push_back(vfx)
