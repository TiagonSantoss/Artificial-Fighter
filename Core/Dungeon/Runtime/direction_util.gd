class_name DirUtil
extends RefCounted

const ORDER := [
	DoorSocket.Direction.NORTH,
	DoorSocket.Direction.EAST,
	DoorSocket.Direction.SOUTH,
	DoorSocket.Direction.WEST,
]


static func rotate(dir: DoorSocket.Direction, steps: int) -> DoorSocket.Direction:
	return ORDER[(ORDER.find(dir) + steps) % 4]


static func opposite(dir: DoorSocket.Direction) -> DoorSocket.Direction:
	return rotate(dir, 2)
