extends Node

## Loads every StationTheme resource from resources/stations/*.tres and hands
## out a random one each time a new station (frequency) starts.

const STATIONS_DIR := "res://resources/stations"

var all_stations: Array = []

func _ready() -> void:
	all_stations.clear()
	var dir := DirAccess.open(STATIONS_DIR)
	if dir == null:
		push_warning("StationDatabase: no stations directory found at %s" % STATIONS_DIR)
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var theme: StationTheme = load("%s/%s" % [STATIONS_DIR, file_name])
			if theme:
				all_stations.append(theme)
		file_name = dir.get_next()
	dir.list_dir_end()

func get_random_theme() -> StationTheme:
	if all_stations.is_empty():
		return null
	return all_stations[randi() % all_stations.size()]
