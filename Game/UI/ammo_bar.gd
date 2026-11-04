class_name AmmoBar
extends ProgressBar

@export var tween_duration := 0.25

var ammo: AxisAmmo
var _tween: Tween


func _ready() -> void:
	show_percentage = false
	step = 1.0 

	GState.ammo_bound.connect(_bind_ammo)
	if GState.current_ammo:
		_bind_ammo(GState.current_ammo)  # the weapon may already exist


func _bind_ammo(new_ammo: AxisAmmo) -> void:
	if ammo and ammo.changed.is_connected(_on_ammo_changed):
		ammo.changed.disconnect(_on_ammo_changed)

	ammo = new_ammo
	if ammo == null:
		return

	ammo.changed.connect(_on_ammo_changed)

	# snap to the new weapon's state, no tween
	if _tween and _tween.is_valid():
		_tween.kill()
	max_value = ammo.total
	value = ammo.current[AxisAmmo.Group.X]


func _on_ammo_changed(group: AxisAmmo.Group, current: int, maximum: int) -> void:
	# the signal fires for both pools, only X drives the bar
	if group != AxisAmmo.Group.X:
		return

	max_value = maximum

	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween().set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "value", current, tween_duration)
