class_name DungeonGenerator
extends RefCounted

var visited_edges := {}


func generate(
	_seed: int, room_pool: Array[RoomDefinition], count: int, start_room: RoomDefinition
) -> RoomGraph:
	GodRNG.set_run_seed(_seed)
	visited_edges.clear()

	var start_variant := RoomVariant.new()
	start_variant.definition = start_room
	start_variant.rotation_steps = 0

	var builder := RoomGraphBuilder.new()
	var graph := builder.create_graph(start_variant)

	var open := ["start"]
	var id_counter := 1
	var used_doors := {"start": []}

	while open.size() > 0 and id_counter < count:
		var current: String = open.pop_front()

		if not graph.nodes.has(current):
			push_error("Missing node in graph: " + current)
			continue

		var current_variant: RoomVariant = graph.nodes[current]
		var available_dirs := _get_free_doors(current_variant, used_doors.get(current, []))

		if available_dirs.is_empty():
			continue

		for dir in available_dirs:
			if id_counter >= count:
				break

			var opposite := DirUtil.opposite(dir)
			var variant := _pick_compatible_variant(room_pool, opposite)

			if variant == null:
				continue

			var room_id := "room_%d" % id_counter
			id_counter += 1

			var edge_key := "%s->%s" % [current, room_id]
			if visited_edges.has(edge_key):
				continue
			visited_edges[edge_key] = true

			builder.add_room(graph, room_id, variant)
			builder.connect_rooms(graph, current, room_id, dir)

			if not used_doors.has(current):
				used_doors[current] = []
			if not used_doors.has(room_id):
				used_doors[room_id] = []

			used_doors[current].append(dir)
			used_doors[room_id].append(opposite)

			open.append(room_id)

	return graph


func _get_free_doors(variant: RoomVariant, used: Array) -> Array:
	var result := []
	for d in variant.get_doors():
		if not used.has(d):
			result.append(d)
	return result


func _pick_compatible_variant(
	pool: Array[RoomDefinition], required: DoorSocket.Direction
) -> RoomVariant:
	var candidates: Array[RoomVariant] = []

	for room in pool:
		var rotations := 4 if room.allow_rotation else 1
		for r in rotations:
			var v := RoomVariant.new()
			v.definition = room
			v.rotation_steps = r
			if required in v.get_doors():
				candidates.append(v)

	if candidates.is_empty():
		return null

	return candidates[GodRNG.rng.randi_range(0, candidates.size() - 1)]
