class_name RoomGraphBuilder
extends RefCounted

func create_graph(start_definition: RoomDefinition) -> RoomGraph:
	var graph := RoomGraph.new()
	
	graph.add_room(
		"start",
		start_definition
	)
	
	return graph

func add_room(graph: RoomGraph, id: String, def: RoomDefinition) -> void:
	print("ADD ROOM:", id)
	#print("BEFORE:", graph.connections.keys())
	graph.add_room(id, def)
	#print("AFTER:", graph.connections.keys())


func connect_rooms(
	graph: RoomGraph,
	a: String,
	b: String,
	dir: DoorSocket.Direction
) -> void:
	graph.connect_room(a, b, dir)
