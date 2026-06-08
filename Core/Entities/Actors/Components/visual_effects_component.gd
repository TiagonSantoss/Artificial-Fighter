class_name VisualEffectsComponent
extends EntityComponent

var sprite: AnimatedSprite3D
var is_flashing := false

func set_sprite(p_sprite: AnimatedSprite3D) -> void:
	sprite = p_sprite

func on_damage(_hit: HitData) -> void:
	flash_red()

func flash_red(duration: float = 0.1) -> void:
	if sprite == null:
		return
	
	if is_flashing:
		return
	
	is_flashing = true
	
	sprite.modulate = Color(1, 0.3, 0.3, 1)
	
	await get_tree().create_timer(duration).timeout
	
	sprite.modulate = Color(1, 1, 1, 1)
	is_flashing = false
