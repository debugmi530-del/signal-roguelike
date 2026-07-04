extends Node

## Drives the run's high-level flow: infinite station counter, boss cadence,
## current station theme, and the "no permanent power progression, only card
## pool unlocks" persistence hookup.

signal run_started
signal run_ended(depth: int, newly_unlocked: Array)

const BOSS_EVERY_N_STATIONS := 5

var current_station_index: int = 0
var current_theme: StationTheme = null
var newly_unlocked_cards: Array = []
var last_run_depth: int = 0

func start_new_run() -> void:
	StatManager.reset_run()
	current_station_index = 0
	newly_unlocked_cards.clear()
	current_theme = StationDatabase.get_random_theme()
	run_started.emit()

func advance_station() -> void:
	current_station_index += 1
	current_theme = StationDatabase.get_random_theme()
	var unlocked := CardDatabase.maybe_unlock_new_cards(current_station_index)
	if not unlocked.is_empty():
		newly_unlocked_cards.append_array(unlocked)

func is_boss_station() -> bool:
	return current_station_index > 0 and current_station_index % BOSS_EVERY_N_STATIONS == 0

func end_run() -> void:
	last_run_depth = current_station_index
	run_ended.emit(last_run_depth, newly_unlocked_cards.duplicate())
