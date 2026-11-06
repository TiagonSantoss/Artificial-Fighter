extends TextureProgressBar

@export var smoothing := 10.0  # 0 = instant

var _known := {}  # boss instance id -> max health
var _bosses: Array = []
var _shown := 0.0


func _ready() -> void:
	min_value = 0.0
	step = 0.0  # smooth values instead of whole numbers
	hide()
	GState.boss_fight_changed.connect(_on_boss_fight_changed)


func _on_boss_fight_changed(bosses: Array) -> void:
	_bosses = bosses

	if bosses.is_empty():
		_known.clear()
		hide()
		return

	for boss in bosses:
		var id: int = boss.get_instance_id()
		if not _known.has(id):
			_known[id] = float(boss.definition.max_health)

	var total_max := 0.0
	for m in _known.values():
		total_max += m
	max_value = total_max

	if not visible:
		_shown = total_max  # starts full
		value = _shown
		show()


func _process(delta: float) -> void:
	if not visible:
		return

	var current := 0.0
	for boss in _bosses:
		if is_instance_valid(boss) and not boss.is_queued_for_deletion():
			# ADAPT: use your HealthComponent's real current-health field
			current += clampf(
				boss.health_component.current_health, 0.0, _known.get(boss.get_instance_id(), 0.0)
			)

	if smoothing <= 0.0:
		_shown = current
	else:
		_shown = lerpf(_shown, current, minf(1.0, smoothing * delta))
	value = _shown
