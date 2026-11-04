class_name AmmoBar
extends Control

@export_group("Layout Settings")
@export var main_size := Vector2(140, 70)
@export var preview_size := Vector2(100, 50)

@export_group("Animation")
@export var tween_duration := 0.25
@export var offscreen_y_offset := 200.0
@export var pop_scale := Vector2(1.25, 1.25)
@export var inactive_alpha := 0.6

var observed_entity: Entity
var ammo: AxisAmmo
var current_group := AxisAmmo.Group.X
var _shown := {AxisAmmo.Group.X: -1, AxisAmmo.Group.Z: -1}

@onready var preview_container: HBoxContainer = $VBoxContainer/PreviewContainer
@onready var main_container: HBoxContainer = $VBoxContainer/MainContainer
@onready var slot_1: PanelContainer = %Slot1  # X-axis ammo
@onready var slot_2: PanelContainer = %Slot2  # Z-axis ammo

var slots := {}


func _ready() -> void:
	slots = {AxisAmmo.Group.X: slot_1, AxisAmmo.Group.Z: slot_2}

	for slot: Control in slots.values():
		slot.offset_transform_enabled = true
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE

	GState.perspective_updated.connect(_on_perspective_updated)
	GState.ammo_bound.connect(_bind_ammo)

	if GState.current_perspective:
		current_group = AxisAmmo.group_of(GState.current_perspective.active_axis)

	_arrange(true)
	if GState.current_ammo:
		_bind_ammo(GState.current_ammo)  # the weapon may already exist


# --- SIGNALS ---


func _on_perspective_updated(state) -> void:
	var new_group := AxisAmmo.group_of(state.active_axis)
	if new_group == current_group:
		return  # 180° turn stays in the same pool
	current_group = new_group
	_arrange(false)


func _on_ammo_changed(group: AxisAmmo.Group, current: int, _maximum: int) -> void:
	_refresh_text(group)

	if _shown[group] != -1 and _shown[group] != current:
		_pop(slots[group])
	_shown[group] = current


# --- BINDING ---


func _bind_ammo(new_ammo: AxisAmmo) -> void:
	if ammo and ammo.changed.is_connected(_on_ammo_changed):
		ammo.changed.disconnect(_on_ammo_changed)

	ammo = new_ammo
	if ammo == null:
		return

	ammo.changed.connect(_on_ammo_changed)
	for group in slots:
		_shown[group] = ammo.current[group]
		_refresh_text(group)

	_arrange(true)
	_slide_in()


# --- LAYOUT ---


func _arrange(instant: bool) -> void:
	for group in slots:
		var slot: PanelContainer = slots[group]
		var is_main: bool = group == current_group
		var target_parent: Control = main_container if is_main else preview_container
		var target_size := main_size if is_main else preview_size
		var target_alpha := 1.0 if is_main else inactive_alpha

		if slot.get_parent() != target_parent:
			slot.reparent(target_parent, false)

		slot.pivot_offset = target_size / 2.0
		_refresh_text(group)

		if instant:
			slot.custom_minimum_size = target_size
			slot.modulate.a = target_alpha
			slot.offset_transform_position.y = 0.0
		else:
			var tween := _new_tween(slot)
			tween.tween_property(slot, "custom_minimum_size", target_size, tween_duration)
			tween.tween_property(slot, "modulate:a", target_alpha, tween_duration)
			tween.tween_property(slot, "offset_transform_position:y", 0.0, tween_duration)


func _refresh_text(group: AxisAmmo.Group) -> void:
	var label: Label = slots[group].get_node("Label")
	var axis_name := "x" if group == AxisAmmo.Group.X else "z"
	var cur = ammo.current[group] if ammo else 0
	var total := ammo.total if ammo else 0

	if group == current_group:
		label.text = "%s  %d / %d" % [axis_name, cur, total]
	else:
		label.text = "%s  %d" % [axis_name, cur]


# --- TWEENS ---


func _pop(slot: Control) -> void:
	slot.pivot_offset = slot.size / 2.0
	slot.offset_transform_scale = pop_scale

	var tween := _new_tween(slot)
	tween.tween_property(slot, "offset_transform_scale", Vector2.ONE, tween_duration)


func _slide_in() -> void:
	for slot: Control in slots.values():
		slot.offset_transform_position.y = offscreen_y_offset
		var tween := _new_tween(slot)
		tween.tween_property(slot, "offset_transform_position:y", 0.0, tween_duration)


func _hide_all() -> void:
	for slot: Control in slots.values():
		slot.offset_transform_position.y = offscreen_y_offset


func _new_tween(slot: Control) -> Tween:
	if slot.has_meta("tween"):
		var old := slot.get_meta("tween") as Tween
		if old and old.is_valid():
			old.kill()

	var tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(
		Tween.EASE_OUT
	)
	slot.set_meta("tween", tween)
	return tween
