class_name VisualEffectsComponent
extends EntityComponent

@export var shadow_offset := 0.01

var shadow: Sprite3D
var shadow_timer := 0.0

func set_shadow(value: Sprite3D) -> void:
	shadow = value

func update(_delta: float) -> void:
	if shadow == null or entity == null:
		return
	
	if entity.is_on_floor():
		shadow.global_position = Vector3(
			entity.global_position.x,
			entity.global_position.y + shadow_offset,
			entity.global_position.z
		)
		
		shadow.scale = Vector3.ONE
		return
	
	#shadow_timer += delta
	
	#if shadow_timer < 0.05:
	#	return
	#shadow_timer = 0.0
	if !entity.is_on_floor():
		update_airborne_shadow()
	#update_airborne_shadow()

func update_airborne_shadow() -> void:
	var from := entity.global_position + Vector3.UP * 2.0
	var to := entity.global_position + Vector3.DOWN * 100.0
	
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [entity.get_rid()]
	
	var result := entity.get_world_3d().direct_space_state.intersect_ray(query)
	
	if result.is_empty():
		return
	
	var hit_pos: Vector3 = result.position
	
	shadow.global_position = Vector3(
		entity.global_position.x,
		hit_pos.y + shadow_offset,
		entity.global_position.z
	)
	
	var height_above_ground = abs(entity.global_position.y - hit_pos.y)
	
	var scale_factor = clamp(
		1.0 - height_above_ground * 0.08,
		0.4,
		1.0
	)
	
	shadow.scale = Vector3.ONE * scale_factor
	print("Shadow scale:",height_above_ground, scale_factor)
