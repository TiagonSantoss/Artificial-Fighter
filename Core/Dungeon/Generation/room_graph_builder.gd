class_name RoomGraphBuilder
extends RefCounted


func create_graph(start_variant: RoomVariant) -> RoomGraph:  # CHANGED
	var graph := RoomGraph.new()
	graph.add_room("start", start_variant)
	return graph


func add_room(graph: RoomGraph, id: String, variant: RoomVariant) -> void:  # CHANGED
	graph.add_room(id, variant)


func connect_rooms(graph: RoomGraph, a: String, b: String, dir: DoorSocket.Direction) -> void:
	graph.connect_room(a, b, dir)
