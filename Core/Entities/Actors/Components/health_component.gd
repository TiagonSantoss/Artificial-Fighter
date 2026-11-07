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
	if health <= 0.0:
		return  # already dead, ignore extra hits this frame

	health -= amount

	if GameAutoLoad.is_current_entity(entity):
		GState.health_changed.emit(entity.entity_id, int(health))

	if health <= 0.0:
		SceneManager.spawn_effect(SceneManager.Fx.EXPLOSION, entity.global_position)
		died.emit()


func heal(amount: float) -> float:
	if health <= 0.0 or health >= max_health:
		return 0.0  # dead or already full, nothing healed

	var before := health
	health = minf(health + amount, float(max_health))

	if GameAutoLoad.is_current_entity(entity):
		GState.health_changed.emit(entity.entity_id, int(health))

	return health - before

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
