class_name PlayerController
extends Controller

func get_actions() -> Array[Action]:
	var actions: Array[Action] = []
	
	var dir := Vector3.ZERO
	dir.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	dir.z = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")

	if dir != Vector3.ZERO:
		actions.append(MovementAction.new(dir))

	if Input.is_action_just_pressed("ui_cancel"):
		actions.append(EscapeAction.new())

	return actions
