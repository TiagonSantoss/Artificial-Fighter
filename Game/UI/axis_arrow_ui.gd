extends Control

const RADIUS_X := 48.0
const RADIUS_Y := 24.0

const MIN_SCALE := 0.75
const MAX_SCALE := 1.20

const MIN_ALPHA := 0.45
const MAX_ALPHA := 1.0

@export var rotation_speed := 8.0

# --- Texture Configuration ---
@export_group("X Axis Textures")
@export var texture_x_positive: Texture2D  # Bright red circle with 'X'
@export var texture_x_negative: Texture2D  # Dark/hollow red circle

@export_group("Z Axis Textures")
@export var texture_z_positive: Texture2D  # Bright blue circle with 'Z'
@export var texture_z_negative: Texture2D  # Dark/hollow blue circle

@onready var arrow_zn: TextureRect = $ArrowZN
@onready var arrow_zp: TextureRect = $ArrowZP
@onready var arrow_xp: TextureRect = $ArrowXP
@onready var arrow_xn: TextureRect = $ArrowXN

var current_rotation := 0.0
var target_rotation := 0.0

var arrows := {}
var base_positions := {}


func _ready() -> void:
	arrows = {
		CameraPerspectiveState.Axis.X_POSITIVE: arrow_xp,
		CameraPerspectiveState.Axis.X_NEGATIVE: arrow_xn,
		CameraPerspectiveState.Axis.Z_POSITIVE: arrow_zp,
		CameraPerspectiveState.Axis.Z_NEGATIVE: arrow_zn,
	}

	base_positions = {
		arrow_xp: Vector3(1, 0, 0),
		arrow_xn: Vector3(-1, 0, 0),
		arrow_zp: Vector3(0, 0, 1),
		arrow_zn: Vector3(0, 0, -1),
	}

	# Set the initial textures
	_update_textures()

	GState.perspective_updated.connect(_on_perspective_updated)

	_update_highlight(CameraPerspectiveState.Axis.Z_NEGATIVE)


func _process(delta: float) -> void:
	current_rotation = lerp_angle(current_rotation, target_rotation, rotation_speed * delta)

	for arrow in base_positions:
		var p: Vector3 = base_positions[arrow]
		var r := p.rotated(Vector3.UP, current_rotation)

		arrow.position = Vector2(r.x * RADIUS_X, r.z * RADIUS_Y)

		# t represents how close the node is to the camera (0.0 is far back, 1.0 is front)
		var t := (-r.z + 1.0) * 0.5

		var s = lerp(MIN_SCALE, MAX_SCALE, t)
		arrow.scale = Vector2.ONE * s

		var a = lerp(MIN_ALPHA, MAX_ALPHA, t)
		arrow.modulate.a = a

		arrow.z_index = int(t * 100)


func _on_perspective_updated(axis: CameraPerspectiveState.Axis) -> void:
	match axis:
		CameraPerspectiveState.Axis.Z_NEGATIVE:
			target_rotation = deg_to_rad(0)

		CameraPerspectiveState.Axis.X_POSITIVE:
			target_rotation = deg_to_rad(90)

		CameraPerspectiveState.Axis.Z_POSITIVE:
			target_rotation = deg_to_rad(180)

		CameraPerspectiveState.Axis.X_NEGATIVE:
			target_rotation = deg_to_rad(270)

	_update_highlight(axis)


func _update_highlight(active: CameraPerspectiveState.Axis) -> void:
	for axis in arrows:
		arrows[axis].modulate = Color.WHITE

	arrows[active].modulate = Color.YELLOW


# --- Assign the correct textures to the UI elements ---
func _update_textures() -> void:
	if texture_x_positive and texture_x_negative:
		arrow_xp.texture = texture_x_positive
		arrow_xn.texture = texture_x_negative

	if texture_z_positive and texture_z_negative:
		arrow_zp.texture = texture_z_positive
		arrow_zn.texture = texture_z_negative
