class_name DoorSocket
extends Area3D

enum Direction { NORTH, SOUTH, EAST, WEST, SPECIAL }

@export var direction: Direction

var room_id: String
var target_room_id: String


func _ready() -> void:
	print("im door and im ready")
	add_to_group("door_socket")

	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if body is Entity:
		if body.entity_id == 0 or body.entity_id == 1:
			if target_room_id != "":
				print("Door triggered! Teleporting to: ", target_room_id)
				GameAutoLoad.chunk_manager.teleport_player(target_room_id, direction)
			else:
				print("Warning: Door touched, but target_room_id is empty!")

func hide_special() -> void:
	hide()
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)


func reveal_special(animated := true) -> void:
	show()
	if not animated:
		set_deferred("monitoring", true)
		set_deferred("monitorable", true)
		return

	# Pop-in animation. Works on any Node3D without touching materials.
	scale = Vector3.ONE * 0.01
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector3.ONE, 0.4)
	tween.tween_callback(
		func():
			set_deferred("monitoring", true)
			set_deferred("monitorable", true)
	)
