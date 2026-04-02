extends Node3D

func _ready():
	var builder = GridBuild.new()
	var grid = builder.build($GridMap)
	
	var res = GridData.new()
	res.grid = grid.grid
	
	ResourceSaver.save(res, "res://Game/Room/Rooms/start.tres")
