extends GPUParticles3D

@export var bob_height: float = 0.5
@export var bob_speed: float = 1.5

var time_passed: float = 0.0
var start_y: float = 0.0


func _ready() -> void:
	start_y = position.y


func _process(delta: float) -> void:
	time_passed += delta
	position.y = start_y + (sin(time_passed * bob_speed) * bob_height)
