class_name RoomInfo
extends RefCounted

## Plain data holder for one room in the generated station layout.

enum Type { START, ENEMY, BOSS, SHOP, TREASURE }

var grid_pos: Vector2i
var type: int = Type.ENEMY
var cleared: bool = false
var visited: bool = false
var neighbor_dirs: Array[Vector2i] = []
var enemy_count: int = 3

func has_neighbor(dir: Vector2i) -> bool:
	return neighbor_dirs.has(dir)
