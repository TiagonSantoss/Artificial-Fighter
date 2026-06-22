extends Node

const PROJECTILE_SCENE = preload("res://Core/Combat/Projectile/Projectile.tscn")
@export var pool_size := 300

var _pool: Array = []

func _ready() -> void:
	# Wait one frame to ensure the main game tree is ready
	await get_tree().process_frame
	
	# Pre-allocate all the bullets into memory
	for i in range(pool_size):
		var proj = PROJECTILE_SCENE.instantiate()
		add_child(proj)
		if proj.has_method("deactivate"):
			proj.deactivate()
		_pool.append(proj)

func get_projectile():
	for proj in _pool:
		if not proj.is_active:
			return proj
			
	# Safety fallback: steal the oldest bullet if we run out
	var oldest = _pool[0]
	oldest.deactivate()
	return oldest
