extends Control

@onready var bg = $background
@onready var blocks = $Node3D/SubViewport/blocks
@onready var floating_cds = $Node3D/SubViewport/characters
@onready var anim_player = $Intro
@onready var play_button = $UILayer/Menu/Buttons/Play


func _ready() -> void:
	# $UILayer/Menu.modulate.a = 0

	# 2. Roll the random layouts and colors
	setup_random_colors()
	setup_random_layout()

	# 3. Play the snappy "boot_intro" animation
	anim_player.play("boot_intro")

	# 4. Wait for the animation to end, then give the player control
	await anim_player.animation_finished
	play_button.grab_focus()


func setup_random_colors() -> void:
	var is_dark_mode = randi() % 2 == 0

	var primary_color: Color
	var secondary_color: Color

	# Configure colors based on the coin flip
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

	# Inject the colors into your corner-to-corner shader
	bg.material.set_shader_parameter("bg_color", primary_color)
	bg.material.set_shader_parameter("gradient_color", secondary_color)

	# Create a new 3D material dynamically and apply it to both particle systems
	# var element_material = StandardMaterial3D.new()
	# element_material.albedo_color = secondary_color
	# element_material.vertex_color_use_as_albedo = true
	# element_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	#
	# # NEW: Tell the material to glow in the dark and ignore lighting
	# element_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	# blocks.material_override = element_material
	# floating_cds.material_override = element_material

	# Update the UI title to contrast against the new background
	# $UILayer/Menu/Title.material.set_shader_parameter("override_color", secondary_color)
	# $UILayer/Menu/Buttons/Play.material.set_shader_parameter("override_color", secondary_color)
	# $UILayer/Menu/Buttons/Options.material.set_shader_parameter("override_color", secondary_color)
	# $UILayer/Menu/Buttons/Credits.material.set_shader_parameter("override_color", secondary_color)
	# $UILayer/Menu/Buttons/Exit.material.set_shader_parameter("override_color", secondary_color)
	#


func setup_random_layout() -> void:
	var layout_roll = randi() % 3

	# Access the particle's emission box so we can stretch and squash it
	var p_mat = blocks.process_material as ParticleProcessMaterial

	# Reset rotation in case a previous scene load left it tilted
	blocks.rotation_degrees = Vector3.ZERO

	match layout_roll:
		0:
			print("BOTTOM EDGE")
			# Variant 1: Bottom Edge Cityscape
			blocks.position = Vector3(0.0, -5.0, -4.0)
			# Stretch the box extremely wide, but keep it short
			p_mat.emission_box_extents = Vector3(6.0, 1.0, 6.0)

		1:
			print("DIAGONAL SLOPE BOOTOOM LEFT")
			# Variant 2: Bottom-Left Diagonal Slope
			blocks.position = Vector3(4.0, -2.0, 0.0)
			# Make the box a square
			p_mat.emission_box_extents = Vector3(7.0, 2.5, 7.0)
			# Rotate it 45 degrees to create the stair-step/slope effect
			blocks.rotation_degrees = Vector3(0, 0, 45)

		2:
			print("RIGHT EDGE VERTICAL WALL")
			# Variant 3: Right Edge Vertical Wall
			blocks.position = Vector3(12.0, -3.0, 0.0)
			# Compress the width, but stretch it completely up the side of the screen
			p_mat.emission_box_extents = Vector3(6.0, 1.0, 6.0)

			blocks.rotation_degrees = Vector3(0, 0, 90)
