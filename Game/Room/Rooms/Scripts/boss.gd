extends Node3D

func _ready():
	var builder = GridBuild.new()
	var grid: GridData = builder.build($GridMap)

	ResourceSaver.save(grid, "res://Game/Room/Rooms/boss.tres")
