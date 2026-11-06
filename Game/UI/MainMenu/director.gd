extends Control

@onready var bg = $background
@onready var blocks = $Node3D/SubViewport/blocks
@onready var floating_cds = $Node3D/SubViewport/characters
# @onready var anim_player = $Intro
@onready var play_button = $UILayer/Menu/Buttons/Play
@onready var emitter = $FmodEventEmitter2D

@onready var video_player = $VideoStreamPlayer


func _ready() -> void:
	video_player.play()
	await video_player.finished

	video_player.hide()

	setup_random_colors()
	setup_random_layout()

	# anim_player.play("boot_intro")
	# await anim_player.animation_finished
	play_button.grab_focus()
	emitter.play()


func _input(event: InputEvent) -> void:
	if video_player.is_playing():
		if (
			event.is_action_pressed("ui_accept")
			or event.is_action_pressed("ui_cancel")
			or (event is InputEventMouseButton and event.pressed)
		):
			video_player.stop()
			video_player.finished.emit()


func setup_random_colors() -> void:
	var is_dark_mode = randi() % 2 == 0
	var primary_color: Color
	var secondary_color: Color

	if is_dark_mode:
		primary_color = Color.BLACK
		secondary_color = Color.WHITE
		bg.material.set_shader_parameter("dot_color", Color.BLACK)
		bg.material.set_shader_parameter("vignette_color", Color.BLACK)
	else:
		primary_color = Color.WHITE
		secondary_color = Color.BLACK
		bg.material.set_shader_parameter("dot_color", Color.WHITE)
		bg.material.set_shader_parameter("vignette_color", Color.WHITE)

	bg.material.set_shader_parameter("bg_color", primary_color)
	bg.material.set_shader_parameter("gradient_color", secondary_color)


func setup_random_layout() -> void:
	var layout_roll = randi() % 3
	var p_mat = blocks.process_material as ParticleProcessMaterial

	blocks.rotation_degrees = Vector3.ZERO

	match layout_roll:
		0:
			print("BOTTOM EDGE")
			blocks.position = Vector3(0.0, -5.0, -4.0)
			p_mat.emission_box_extents = Vector3(6.0, 1.0, 6.0)
		1:
			print("DIAGONAL SLOPE BOOTOOM LEFT")
			blocks.position = Vector3(4.0, -2.0, 0.0)
			p_mat.emission_box_extents = Vector3(7.0, 2.5, 7.0)
			blocks.rotation_degrees = Vector3(0, 0, 45)
		2:
			print("RIGHT EDGE VERTICAL WALL")
			blocks.position = Vector3(12.0, -3.0, 0.0)
			p_mat.emission_box_extents = Vector3(6.0, 1.0, 6.0)
			blocks.rotation_degrees = Vector3(0, 0, 90)
