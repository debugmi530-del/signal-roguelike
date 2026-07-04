extends Node

## Loads every EnemyData/BossData resource so rooms can spawn enemies by id
## or by station-favored pool without hardcoding scene references.

const ENEMIES_DIR := "res://resources/enemies"
const BOSSES_DIR := "res://resources/bosses"

var all_enemies: Array = []
var all_bosses: Array = []

func _ready() -> void:
	all_enemies = _load_dir(ENEMIES_DIR)
	all_bosses = _load_dir(BOSSES_DIR)

func _load_dir(path: String) -> Array:
	var result: Array = []
	var dir := DirAccess.open(path)
	if dir == null:
		push_warning("EnemyDatabase: missing directory %s" % path)
		return result
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var res = load("%s/%s" % [path, file_name])
			if res:
				result.append(res)
		file_name = dir.get_next()
	dir.list_dir_end()
	return result

func get_random_enemy(theme: StationTheme) -> EnemyData:
	if all_enemies.is_empty():
		return null
	if theme and not theme.favored_enemy_ids.is_empty() and randf() < 0.7:
		var favored: Array = []
		for e in all_enemies:
			if theme.favored_enemy_ids.has(e.id):
				favored.append(e)
		if not favored.is_empty():
			return favored[randi() % favored.size()]
	return all_enemies[randi() % all_enemies.size()]

func get_random_boss() -> BossData:
	if all_bosses.is_empty():
		return null
	return all_bosses[randi() % all_bosses.size()]
