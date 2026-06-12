class_name HealthComponent
extends EntityComponent

const HIT_VFX_SCENE = preload("res://Utils/HitVFX.tscn")

signal damaged(amount)
signal died

var health: float
var max_health: int

func configure(max_hp: int):
	max_health = max_hp
	health = max_hp

func damage(amount: float):
	health -= amount
	
	damaged.emit(amount)
	
	print(health)
	
	if health <= 0:
		#_spawn_hit_vfx()
		died.emit()


func _spawn_hit_vfx() -> void:
	var vfx := HIT_VFX_SCENE.instantiate()
	get_tree().current_scene.add_child(vfx)
	vfx.reparent(entity)
	vfx.rotation.y = randf() * TAU
	
	#if vfx is Node3D:
	#	vfx.look_at(pos + normal, Vector3.UP)
	
	vfx.play()
