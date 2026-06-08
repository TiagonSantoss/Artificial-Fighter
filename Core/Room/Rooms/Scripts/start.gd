@tool
extends Node3D

@onready var spiral = $"spiral thing"
var random_axis := Vector3(
	randf_range(-1, 1),
	randf_range(-1, 1),
	randf_range(-1, 1)
).normalized()

var rotation_speed := 0.2

func _ready():
	var builder = GridBuild.new()
	var grid: GridData = builder.build($GridMap)
	
	ResourceSaver.save(grid, "res://Core/Room/Rooms/startDATA.tres")
	print("CELLS:", grid.grid.size())
	print("DOORS:", grid.get_doors().size())

func _process(delta):
	spiral.rotate(random_axis, rotation_speed * delta)
