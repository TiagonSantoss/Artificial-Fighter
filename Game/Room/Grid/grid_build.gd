class_name GridBuild
extends Node

var cache := {}

func load_cell_definition(mesh_name: String) -> CellDefinition:
	if cache.has(mesh_name):
		return cache[mesh_name]
	
	var path = "res://assets/definitions/cells/%s.tres" % mesh_name.to_lower()
	
	if ResourceLoader.exists(path):
		var res = load(path)
		cache[mesh_name] = res
		return res
	
	return null

func build(gridmap: GridMap) -> GridData:
	var data := GridData.new()
	var mesh_library = gridmap.mesh_library
	
	for cell in gridmap.get_used_cells():
		var item_id = gridmap.get_cell_item(cell)
		if item_id == -1:
			continue
		
		var mesh_name = mesh_library.get_item_name(item_id)
		var cell_data := load_cell_definition(mesh_name)
		print(cell_data)
		
		if cell_data == null:
			push_warning("Tile without config: " + mesh_name)
			continue
		
		data.set_cell(cell, cell_data)
		
		#var world_pos = gridmap.map_to_local(cell)
		#print(cell, " -> ", world_pos)
	
	return data
