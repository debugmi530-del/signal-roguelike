class_name RoomGenerator
extends RefCounted

## Builds one station's room graph on a simple grid, following the plan's
## per-station room counts. Rooms never need to be cleared to move on, and
## the shape/positions are re-rolled every station.

const DIRS: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

var rooms: Dictionary = {} # Vector2i -> RoomInfo
var boss_pos: Vector2i

func generate() -> Dictionary:
	rooms.clear()
	var enemy_count := randi_range(5, 25)
	var shop_count := randi_range(0, 2)
	var treasure_count := randi_range(0, 4)
	var total_extra := enemy_count + shop_count + treasure_count + 1 # +1 boss

	var start := Vector2i.ZERO
	var start_room := RoomInfo.new()
	start_room.grid_pos = start
	start_room.type = RoomInfo.Type.START
	start_room.cleared = true
	start_room.visited = true
	rooms[start] = start_room

	var frontier: Array[Vector2i] = [start]
	var placed := 0
	var guard := 0
	while placed < total_extra and guard < total_extra * 40:
		guard += 1
		var from: Vector2i = frontier[randi() % frontier.size()]
		var dir: Vector2i = DIRS[randi() % DIRS.size()]
		var next: Vector2i = from + dir
		if rooms.has(next):
			continue
		var room := RoomInfo.new()
		room.grid_pos = next
		room.type = RoomInfo.Type.ENEMY
		rooms[next] = room
		frontier.append(next)
		placed += 1

	# Boss room = farthest room (by grid distance) from the start.
	boss_pos = start
	var best_dist := -1
	for pos in rooms.keys():
		if pos == start:
			continue
		var d: int = abs(pos.x - start.x) + abs(pos.y - start.y)
		if d > best_dist:
			best_dist = d
			boss_pos = pos
	if rooms.has(boss_pos) and boss_pos != start:
		rooms[boss_pos].type = RoomInfo.Type.BOSS

	# Assign shop/treasure rooms among the remaining non-start/non-boss rooms.
	var candidates: Array[Vector2i] = []
	for pos in rooms.keys():
		if pos != start and pos != boss_pos:
			candidates.append(pos)
	candidates.shuffle()

	var idx := 0
	for i in range(shop_count):
		if idx >= candidates.size():
			break
		rooms[candidates[idx]].type = RoomInfo.Type.SHOP
		idx += 1
	for i in range(treasure_count):
		if idx >= candidates.size():
			break
		rooms[candidates[idx]].type = RoomInfo.Type.TREASURE
		idx += 1

	# Remaining candidates stay ENEMY; give them a random pack size.
	for pos in candidates.slice(idx):
		rooms[pos].enemy_count = randi_range(2, 5)

	# Compute door connections between adjacent placed rooms.
	for pos in rooms.keys():
		var room: RoomInfo = rooms[pos]
		for dir in DIRS:
			if rooms.has(pos + dir):
				room.neighbor_dirs.append(dir)

	return rooms
