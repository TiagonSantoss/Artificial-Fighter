class_name PlayerHud
extends Control

signal activated

@export var entity_id := 0
@export var slide_direction := Vector2.DOWN
@export var tween_duration := 0.35

var is_active := false
var _tween: Tween


static func find_for(node: Node) -> PlayerHud:
	var n := node.get_parent()
	while n:
		if n is PlayerHud:
			return n
		n = n.get_parent()
	return null


func _ready() -> void:
	offset_transform_enabled = true
	GState.controlled_entity_changed.connect(_on_controlled_entity_changed)

	var current := GameAutoLoad.get_current_entity()
	_set_active(current != null and current.entity_id == entity_id, true)


func _on_controlled_entity_changed(entity: Entity) -> void:
	if entity == null:
		return
	_set_active(entity.entity_id == entity_id)


func _set_active(active: bool, instant := false) -> void:
	is_active = active
	if _tween and _tween.is_valid():
		_tween.kill()

	# window-sized, so it always fully leaves the screen
	var target := Vector2.ZERO if active else slide_direction * get_viewport_rect().size

	if active:
		visible = true

	if instant:
		offset_transform_position = target
		visible = active
		if active:
			activated.emit()
		return

	_tween = create_tween().set_trans(Tween.TRANS_BACK)
	_tween.set_ease(Tween.EASE_OUT if active else Tween.EASE_IN)
	_tween.tween_property(self, "offset_transform_position", target, tween_duration)

	if active:
		activated.emit()
	else:
		_tween.tween_callback(func(): visible = false)
