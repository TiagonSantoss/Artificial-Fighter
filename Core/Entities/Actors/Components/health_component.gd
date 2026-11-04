class_name HealthComponent
extends EntityComponent

# const HIT_VFX_SCENE = preload("res://Utils/HitVFX.tscn")

signal died

var health: float
var max_health: int


func configure(max_hp: int):
	max_health = max_hp
	health = max_hp


func damage(amount: float):
	health -= amount

	if entity.entity_id == GameAutoLoad.get_current_entity().entity_id:
		GState.health_changed.emit(entity.entity_id, int(health))

	print(health)

	if health <= 0:
		SceneManager.spawn_effect(SceneManager.Fx.EXPLOSION, entity.global_position)
		#_spawn_hit_vfx()
		died.emit()

# func _spawn_hit_vfx() -> void:
# 	var vfx := HIT_VFX_SCENE.instantiate()
# 	get_tree().current_scene.add_child(vfx)
# 	vfx.reparent(entity)
# 	vfx.rotation.y = randf() * TAU
#
# 	#if vfx is Node3D:
# 	#	vfx.look_at(pos + normal, Vector3.UP)
#
# 	vfx.play()
