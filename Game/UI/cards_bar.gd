class_name CardsBar
extends Control

@export_group("Layout Settings")
@export var main_card_size: Vector2 = Vector2(90, 130)  # Increase this to make cards bigger!
@export var preview_card_size: Vector2 = Vector2(45, 65)  # The tiny size for the preview

@export_group("Animation")
@export var tween_duration: float = 0.25
@export var offscreen_y_offset: float = 200.0
@export var hover_y_offset: float = -20.0
@export var hover_scale: Vector2 = Vector2(1.1, 1.1)

var observed_entity: Entity
var current_cam_axis: int = -1
var active_card_uis: Dictionary = {}

@onready var preview_container: HBoxContainer = $VBoxContainer/PreviewContainer
@onready var slot_x1: TextureRect = $VBoxContainer/MainContainer/SlotX1
@onready var slot_x2: TextureRect = $VBoxContainer/MainContainer/SlotX2
@onready var slot_z1: TextureRect = $VBoxContainer/MainContainer/SlotZ1
@onready var slot_z2: TextureRect = $VBoxContainer/MainContainer/SlotZ2


func _ready() -> void:
	if GState.has_signal("perspective_updated"):
		GState.perspective_updated.connect(_on_perspective_updated)
	if GState.has_signal("cards_changed"):
		GState.cards_changed.connect(_on_cards_changed)
	if GState.has_signal("controlled_entity_changed"):
		GState.controlled_entity_changed.connect(_on_controlled_entity_changed)

	if GState.current_perspective:
		current_cam_axis = GState.current_perspective.active_axis
		_update_bg_visuals()


func _on_perspective_updated(state) -> void:
	current_cam_axis = state.active_axis
	_update_bg_visuals()
	refresh()


func _on_cards_changed(state) -> void:
	if state != null and state.entity == observed_entity:
		refresh()


func _on_controlled_entity_changed(entity: Entity) -> void:
	observed_entity = entity
	refresh()


func _update_bg_visuals() -> void:
	var is_x = (
		current_cam_axis == CameraPerspectiveState.Axis.X_POSITIVE
		or current_cam_axis == CameraPerspectiveState.Axis.X_NEGATIVE
	)

	if slot_x1:
		slot_x1.visible = is_x
	if slot_x2:
		slot_x2.visible = is_x
	if slot_z1:
		slot_z1.visible = not is_x
	if slot_z2:
		slot_z2.visible = not is_x


func refresh() -> void:
	if observed_entity == null or observed_entity.cards_component == null:
		_clear_all_cards()
		return

	var hand = observed_entity.cards_component.get_cards()

	var valid_main_cards: Array[ItemInstance] = []
	var valid_preview_cards: Array[ItemInstance] = []

	var is_cam_x = (
		current_cam_axis == CameraPerspectiveState.Axis.X_POSITIVE
		or current_cam_axis == CameraPerspectiveState.Axis.X_NEGATIVE
	)
	var x_count = 0
	var z_count = 0

	# 1. Sort cards into Main Slots vs Preview Slots
	for instance in hand:
		var def = instance.definition as CardDefinition
		if def == null:
			continue

		if def.allowed_axis == CardDefinition.CardAxis.X:
			if x_count < 2:
				if is_cam_x:
					valid_main_cards.append(instance)
				else:
					valid_preview_cards.append(instance)
				x_count += 1

		elif def.allowed_axis == CardDefinition.CardAxis.Z:
			if z_count < 2:
				if not is_cam_x:
					valid_main_cards.append(instance)
				else:
					valid_preview_cards.append(instance)
				z_count += 1

		elif def.allowed_axis == CardDefinition.CardAxis.ANY:
			# "ANY" cards always try to fill the active main slots
			if is_cam_x and x_count < 2:
				valid_main_cards.append(instance)
				x_count += 1
			elif not is_cam_x and z_count < 2:
				valid_main_cards.append(instance)
				z_count += 1

	var all_valid_instances = valid_main_cards + valid_preview_cards

	# 2. Delete cards that are entirely gone
	var current_instances = active_card_uis.keys()
	for instance in current_instances:
		if not all_valid_instances.has(instance):
			_tween_card_out(active_card_uis[instance])
			active_card_uis.erase(instance)

	# 3. Setup or Move MAIN Cards
	for i in range(valid_main_cards.size()):
		var instance = valid_main_cards[i]
		var target_slot = (
			(slot_x1 if i == 0 else slot_x2) if is_cam_x else (slot_z1 if i == 0 else slot_z2)
		)
		_setup_or_move_card(instance, target_slot, true)

	# 4. Setup or Move PREVIEW Cards
	for i in range(valid_preview_cards.size()):
		var instance = valid_preview_cards[i]
		_setup_or_move_card(instance, preview_container, false)


# --- UI CREATION & MOVEMENT ---


func _setup_or_move_card(instance: ItemInstance, target_parent: Control, is_main: bool) -> void:
	var ui_node: TextureRect
	var is_new = false

	if active_card_uis.has(instance):
		ui_node = active_card_uis[instance]
	else:
		ui_node = _create_card_ui(instance)
		active_card_uis[instance] = ui_node
		is_new = true

	# Reparent safely
	if ui_node.get_parent() == null:
		target_parent.add_child(ui_node)
	elif ui_node.get_parent() != target_parent:
		ui_node.reparent(target_parent, false)

	var target_size = main_card_size if is_main else preview_card_size

	# Previews cannot be clicked or hovered
	ui_node.mouse_filter = Control.MOUSE_FILTER_STOP if is_main else Control.MOUSE_FILTER_IGNORE
	ui_node.pivot_offset = target_size / 2.0

	_kill_tween(ui_node)
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(
		Tween.EASE_OUT
	)
	ui_node.set_meta("tween", tween)

	# 1. Always tween custom_minimum_size (This forces the Preview HBoxContainer to react)
	tween.tween_property(ui_node, "custom_minimum_size", target_size, tween_duration)

	# 2. THE FIX: Manually force Size and Position when inside the TextureRect slots!
	if is_main:
		# Fallback to custom_minimum_size if the slot's layout size hasn't calculated yet
		var p_size = target_parent.size
		if p_size == Vector2.ZERO:
			p_size = target_parent.custom_minimum_size

		var target_pos = (p_size / 2.0) - (target_size / 2.0)

		tween.tween_property(ui_node, "size", target_size, tween_duration)
		tween.tween_property(ui_node, "position", target_pos, tween_duration)

	# 3. Handle the offset slide-in animation cleanly
	if is_new:
		ui_node.offset_transform_position.y = offscreen_y_offset
		tween.tween_property(ui_node, "offset_transform_position:y", 0.0, tween_duration)
	else:
		tween.tween_property(ui_node, "offset_transform_position:y", 0.0, tween_duration)
		tween.tween_property(ui_node, "offset_transform_scale", Vector2.ONE, tween_duration)


func _create_card_ui(instance: ItemInstance) -> TextureRect:
	var def = instance.definition as CardDefinition
	var card_ui := TextureRect.new()

	card_ui.texture = def.icon
	card_ui.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	card_ui.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	card_ui.offset_transform_enabled = true

	card_ui.mouse_entered.connect(_on_card_mouse_entered.bind(card_ui))
	card_ui.mouse_exited.connect(_on_card_mouse_exited.bind(card_ui))
	card_ui.gui_input.connect(_on_card_gui_input.bind(instance))

	return card_ui


# --- TWEENS & INPUT ---


func _tween_card_out(card_ui: Control) -> void:
	_kill_tween(card_ui)
	card_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(card_ui, "offset_transform_position:y", offscreen_y_offset, tween_duration)
	tween.tween_callback(card_ui.queue_free)


func _clear_all_cards() -> void:
	for instance in active_card_uis.keys():
		_tween_card_out(active_card_uis[instance])
	active_card_uis.clear()


func _kill_tween(card_ui: Control) -> void:
	if card_ui.has_meta("tween"):
		var t = card_ui.get_meta("tween") as Tween
		if t and t.is_valid():
			t.kill()


func _on_card_gui_input(event: InputEvent, instance: ItemInstance) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if observed_entity != null and observed_entity.has_method("use_card"):
			observed_entity.use_card(instance)


func _on_card_mouse_entered(card_ui: Control) -> void:
	if card_ui.mouse_filter == Control.MOUSE_FILTER_IGNORE:
		return

	_kill_tween(card_ui)
	card_ui.z_index = 10
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(
		Tween.EASE_OUT
	)
	card_ui.set_meta("tween", tween)
	tween.tween_property(card_ui, "offset_transform_position:y", hover_y_offset, 0.15)
	tween.tween_property(card_ui, "offset_transform_scale", hover_scale, 0.15)


func _on_card_mouse_exited(card_ui: Control) -> void:
	if card_ui.mouse_filter == Control.MOUSE_FILTER_IGNORE:
		return

	_kill_tween(card_ui)
	card_ui.z_index = 0
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(
		Tween.EASE_OUT
	)
	card_ui.set_meta("tween", tween)
	tween.tween_property(card_ui, "offset_transform_position:y", 0.0, 0.15)
	tween.tween_property(card_ui, "offset_transform_scale", Vector2.ONE, 0.15)
