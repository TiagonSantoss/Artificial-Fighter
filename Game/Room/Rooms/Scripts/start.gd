extends Node3D

func _ready():
	var builder = GridBuild.new()
	var grid: GridData = builder.build($GridMap)

	ResourceSaver.save(grid, "res://Game/Room/Rooms/startDATA.tres")
	print("CELLS:", grid.grid.size())
	print("DOORS:", grid.get_doors().size())
