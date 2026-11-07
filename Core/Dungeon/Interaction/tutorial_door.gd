class_name SceneTransitionDoor
extends Area3D

var is_locked := false

@export_file("*.tscn") var target_scene_path: String


func _ready() -> void:
	print("Scene transition door ready!")

	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	# Check if the body is the player using your existing Entity logic
	if body is Entity:
		if body.entity_id == 0 or body.entity_id == 1:
			if target_scene_path != "":
				print("Door triggered! Changing scene to: ", target_scene_path)

				# IMPORTANT: Replace 'SceneManager' below with the actual Autoload
				# name you gave to your scene manager script in Project Settings!
				SceneManager.change_scene(target_scene_path)
			else:
				push_warning("Warning: Scene door touched, but target_scene_path is empty!")


func unlock() -> void:
	is_locked = false
	print("Door unlocked!")


func lock() -> void:
	is_locked = true
	print("Door locked!")
