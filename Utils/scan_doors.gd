@tool
extends EditorScript

# Folder that holds your RoomDefinition .tres files
const ROOT := "res://assets/definitions/rooms/PS2/"


func _run() -> void:
	_scan_dir(ROOT)
	print("Door scan finished.")


func _scan_dir(path: String) -> void:
	for f in DirAccess.get_files_at(path):
		if f.ends_with(".tres") or f.ends_with(".res"):
			var full := path.path_join(f)
			var res := load(full)
			if res is RoomDefinition:
				_fill(res, full)

	for d in DirAccess.get_directories_at(path):
		if d.begins_with("."):
			continue
		_scan_dir(path.path_join(d))


func _fill(def: RoomDefinition, path: String) -> void:
	if def.scene == null:
		print("SKIPPED (no scene): ", path)
		return

	var found: Array[DoorSocket.Direction] = []
	var state := def.scene.get_state()

	for i in state.get_node_count():
		var script: Script = null
		var dir = null

		for p in state.get_node_property_count(i):
			match state.get_node_property_name(i, p):
				&"script":
					script = state.get_node_property_value(i, p)
				&"direction":
					dir = state.get_node_property_value(i, p)

		if script == null or script.get_global_name() != &"DoorSocket":
			continue

		if dir == null:
			dir = script.get_property_default_value("direction")

		if not found.has(dir):
			found.append(dir)

	def.available_doors = found
	ResourceSaver.save(def, path)
	print("OK ", path, " -> ", found)
