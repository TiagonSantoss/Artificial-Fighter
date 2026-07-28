class_name CardsBar
extends Control

@export_group("Audio")
@export var hover_sound: AudioStream
@export var play_sound: AudioStream
@export var audio_bus: StringName = &"SFX"

@export var hover_offset_y: float = -20.0
@export var hover_tilt_angle: float = 8.0
@export var hover_scale: Vector2 = Vector2(1.1, 1.1)

var observed_entity: Entity
var card_tweens: Dictionary = {}
var _audio_pool: Array[AudioStreamPlayer] = []
var _audio_idx: int = 0

@onready var container: HBoxContainer = $HBoxContainer


func _ready() -> void:
	for i in range(4):
		var player := AudioStreamPlayer.new()
		player.bus = audio_bus
		add_child(player)
		_audio_pool.append(player)

	if GState.has_signal("cards_changed"):
		GState.cards_changed.connect(_on_cards_changed)

	if GState.has_signal("controlled_entity_changed"):
		GState.controlled_entity_changed.connect(_on_controlled_entity_changed)

	var game := get_tree().current_scene as Game
	if game != null and game.controlled_entity != null:
		set_entity(game.controlled_entity)


func _play_ui_sound(stream: AudioStream, pitch_min: float = 0.95, pitch_max: float = 1.05) -> void:
	if stream == null:
		return

	var player := _audio_pool[_audio_idx]
	_audio_idx = (_audio_idx + 1) % _audio_pool.size()

	player.stream = stream
	player.pitch_scale = randf_range(pitch_min, pitch_max)
	player.play()


func _on_controlled_entity_changed(entity: Entity) -> void:
	set_entity(entity)


func _on_cards_changed(state: CardsChangedState) -> void:
	if state != null and state.entity == observed_entity:
		refresh()


func set_entity(entity: Entity) -> void:
	if observed_entity == entity:
		return

	observed_entity = entity
	refresh()


func refresh() -> void:
	card_tweens.clear()
	for child in container.get_children():
		child.queue_free()

	if observed_entity == null or observed_entity.cards_component == null:
		return

	var cards := observed_entity.cards_component.get_cards()

	for instance in cards:
		var card_def := instance.definition as CardDefinition
		if card_def == null:
			continue

		var card_ui := TextureRect.new()
		card_ui.texture = card_def.icon
		card_ui.custom_minimum_size = Vector2(80, 120)
		card_ui.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		card_ui.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		card_ui.tooltip_text = card_def.description

		card_ui.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		card_ui.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		card_ui.mouse_filter = Control.MOUSE_FILTER_STOP

		# Godot 4.7 Offset Transforms
		card_ui.offset_transform_enabled = true
		card_ui.pivot_offset = card_ui.custom_minimum_size / 2.0

		card_ui.mouse_entered.connect(_on_card_mouse_entered.bind(card_ui))
		card_ui.mouse_exited.connect(_on_card_mouse_exited.bind(card_ui))
		card_ui.gui_input.connect(_on_card_gui_input.bind(instance))

		container.add_child(card_ui)


# --- CLICK TO ACTIVATED ---


func _on_card_gui_input(event: InputEvent, instance: ItemInstance) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_play_card(instance)


func _play_card(instance: ItemInstance) -> void:
	var card_def := instance.definition as CardDefinition
	if card_def != null and observed_entity != null:
		print(card_def)
		card_def.play(observed_entity, null)
		_play_ui_sound(play_sound, 1.02, 1.05)

	# Remove the card from hand (triggers cards_changed signal to refresh UI)
	if observed_entity != null and observed_entity.cards_component != null:
		observed_entity.cards_component.hand.remove(instance)


# --- HOVER LOGIC ---


func _on_card_mouse_entered(card_ui: Control) -> void:
	_kill_card_tween(card_ui)
	card_ui.z_index = 10

	var tween := card_ui.create_tween().set_parallel(true)
	card_tweens[card_ui] = tween
	tween.tween_property(card_ui, "offset_transform_position:y", hover_offset_y, 0.15)
	tween.tween_property(card_ui, "offset_transform_scale", hover_scale, 0.15)
	tween.tween_property(card_ui, "offset_transform_rotation", deg_to_rad(hover_tilt_angle), 0.15)
	_play_ui_sound(hover_sound)


func _on_card_mouse_exited(card_ui: Control) -> void:
	_kill_card_tween(card_ui)
	card_ui.z_index = 0

	var tween := card_ui.create_tween().set_parallel(true)
	card_tweens[card_ui] = tween
	tween.tween_property(card_ui, "offset_transform_position", Vector2.ZERO, 0.15)
	tween.tween_property(card_ui, "offset_transform_rotation", 0.0, 0.15)
	tween.tween_property(card_ui, "offset_transform_scale", Vector2.ONE, 0.15)


func _kill_card_tween(card_ui: Control) -> void:
	if card_tweens.has(card_ui) and is_instance_valid(card_tweens[card_ui]):
		card_tweens[card_ui].kill()
	card_tweens.erase(card_ui)
