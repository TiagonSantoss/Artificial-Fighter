extends Node

func _ready():
	var builder = GridBuild.new()
	var grid = builder.build($GridMap)
	
	print("Test result:", grid.grid.size())
