class_name ArenaBarrierRoot
extends Node3D

func set_locked(value: bool) -> void:
	for child in get_children():
		if child is ArenaBarrierPiece:
			child.set_active(value)
