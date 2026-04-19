extends Camera3D

@export var speed := 10.0
@export var mouse_sensitivity := 0.002

var rotation_x := 0.0
var rotation_y := 0.0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	

func _input(event):
	if event is InputEventMouseMotion:
		rotation_y -= event.relative.x * mouse_sensitivity
		rotation_x -= event.relative.y * mouse_sensitivity
		
		rotation_x = clamp(rotation_x, deg_to_rad(-90), deg_to_rad(90))
		
		rotation = Vector3(rotation_x, rotation_y, 0)

func _process(delta):
	var direction := Vector3.ZERO
	
	if Input.is_action_pressed("ui_up"): # W
		direction += Vector3.UP
	if Input.is_action_pressed("ui_down"): # S
		direction -= Vector3.UP
	if Input.is_action_pressed("ui_left"): # A
		direction -= transform.basis.x
	if Input.is_action_pressed("ui_right"): # D
		direction += transform.basis.x
	
	if Input.is_action_pressed("ui_accept"): # Space
		direction += Vector3.UP
	if Input.is_action_pressed("ui_cancel"): # Ctrl
		direction -= Vector3.UP
	
	if direction != Vector3.ZERO:
		direction = direction.normalized()
	
	position += direction * speed * delta
