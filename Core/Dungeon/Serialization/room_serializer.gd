class_name RoomSerializer
extends Node

var cache: Dictionary = {}

const CELL_DEFINITION_PATH := "res://assets/definitions/cells/"

# --------------------------------------------------
# Cell definition loader (cached + safe)
# --------------------------------------------------
func load_cell_definition(mesh_name: String) -> CellDefinition:
	var key := mesh_name.to_lower().strip_edges()
	
	if cache.has(key):
		return cache[key]
	
	var path := CELL_DEFINITION_PATH + "%s.tres" % key
	
	if not ResourceLoader.exists(path):
		push_warning("Missing CellDefinition: " + path)
		return null
	
	var res := load(path)
	
	if res == null:
		push_warning("Failed to load CellDefinition: " + path)
		return null
	
	cache[key] = res
	return res


# --------------------------------------------------
# GridMap → RoomTileData conversion
# --------------------------------------------------
func build(gridmap: GridMap) -> RoomTileData:
	var data := RoomTileData.new()
	
	if gridmap == null:
		push_error("RoomSerializer: gridmap is null")
		return data
	
	var mesh_library := gridmap.mesh_library
	if mesh_library == null:
		push_error("RoomSerializer: gridmap has no mesh_library")
		return data
	
	for cell in gridmap.get_used_cells():
		var item_id := gridmap.get_cell_item(cell)
		
		if item_id == GridMap.INVALID_CELL_ITEM:
			continue
		
		var mesh_name := mesh_library.get_item_name(item_id)
		
		if mesh_name.is_empty():
			push_warning("Empty mesh name at cell: " + str(cell))
			continue
		
		var cell_data := load_cell_definition(mesh_name)
		
		if cell_data == null:
			push_warning("Tile without config: " + mesh_name)
			continue
		
		data.set_cell(cell, cell_data)
	
	return data

func extract_sockets(gridmap: GridMap) -> Array:
	var sockets := []
	
	for cell in gridmap.get_used_cells():
		var item_id = gridmap.get_cell_item(cell)
		var mesh_name = gridmap.mesh_library.get_item_name(item_id)
		
		var def := load_cell_definition(mesh_name)
		if def and def.is_door:
			sockets.append({
				"pos": cell,
				"dir": def.door_dir
			})
	
	return sockets
