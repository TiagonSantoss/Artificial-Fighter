class_name EffectsBar
extends Control
#comentario
var observed_entity: Entity

@onready var container: HBoxContainer = $HBoxContainer


func _ready() -> void:
	var game := get_tree().current_scene as Game
	
	if game == null:
		return
	
	game.controlled_entity_changed.connect(set_entity)
	
	
	if game.controlled_entity != null:
		set_entity(game.controlled_entity)


func set_entity(entity: Entity) -> void:
	if observed_entity == entity:
		return
		
	if observed_entity != null:
		var effects_component := observed_entity.effects_component
		
		if effects_component.effects_changed.is_connected(refresh):
			effects_component.effects_changed.disconnect(refresh)
			
	observed_entity = entity
	
	if observed_entity != null:
		observed_entity.effects_component.effects_changed.connect(
			refresh
		)
	
	refresh()


func refresh() -> void:
	print("refresh")
	for child in container.get_children():
		child.queue_free()
	
	if observed_entity == null:
		return
	
	for instance in observed_entity.effects_component.effects.contents:
		var effect := instance.definition as EffectDefinition
		
		if effect == null:
			continue
		
		var icon := TextureRect.new()
		icon.texture = effect.icon
		icon.custom_minimum_size = Vector2(32, 32)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		
		icon.mouse_filter = Control.MOUSE_FILTER_STOP
		icon.mouse_default_cursor_shape = Control.CURSOR_CROSS
		icon.tooltip_text = effect.description
		
		container.add_child(icon)
