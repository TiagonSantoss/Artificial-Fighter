extends Control

@onready var arrow_zn: TextureRect = $ArrowZN
@onready var arrow_zp: TextureRect = $ArrowZP
@onready var arrow_xp: TextureRect = $ArrowXP
@onready var arrow_xn: TextureRect = $ArrowXN


func _ready() -> void:
	GState.perspective_updated.connect(_on_perspective_updated)


func _process(_delta):
	pass
	#var camera = Game.instance.camera_rig

	#global_position = camera.unproject_position(Game.player.global_position)


func _on_perspective_updated(axis: CameraPerspectiveState.Axis) -> void:
	var arrows := {
		CameraPerspectiveState.Axis.X_POSITIVE: arrow_xp,
		CameraPerspectiveState.Axis.X_NEGATIVE: arrow_xn,
		CameraPerspectiveState.Axis.Z_POSITIVE: arrow_zp,
		CameraPerspectiveState.Axis.Z_NEGATIVE: arrow_zn,
	}

	for arrow in arrows.values():
		arrow.modulate = Color.WHITE

	arrows[axis].modulate = Color.YELLOW
