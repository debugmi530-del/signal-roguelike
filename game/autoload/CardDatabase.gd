extends Node

## Loads every card definition from resources/cards/*.tres, tracks which
## cards are unlocked for future runs (persisted to disk), and hands out
## weighted-random card choices for the "static room" pick-a-card screens.

const SAVE_PATH := "user://signal_unlocked_cards.json"
const CARDS_DIR := "res://resources/cards"

var all_cards: Array = []
var unlocked_ids: Array = []

func _ready() -> void:
	_load_all_cards()
	_load_unlocked()

func _load_all_cards() -> void:
	all_cards.clear()
	var dir := DirAccess.open(CARDS_DIR)
	if dir == null:
		push_warning("CardDatabase: no cards directory found at %s" % CARDS_DIR)
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var card: CardItem = load("%s/%s" % [CARDS_DIR, file_name])
			if card:
				all_cards.append(card)
		file_name = dir.get_next()
	dir.list_dir_end()

func _load_unlocked() -> void:
	unlocked_ids.clear()
	if FileAccess.file_exists(SAVE_PATH):
		var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
		var content := f.get_as_text()
		f.close()
		var parsed = JSON.parse_string(content)
		if parsed is Array:
			for entry in parsed:
				unlocked_ids.append(String(entry))
			return
	# First run ever: unlock only the starter set.
	for card in all_cards:
		if card.id.begins_with("starter_"):
			unlocked_ids.append(card.id)
	_save_unlocked()

func _save_unlocked() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify(unlocked_ids))
	f.close()

func unlock_card(id: String) -> bool:
	if unlocked_ids.has(id):
		return false
	unlocked_ids.append(id)
	_save_unlocked()
	return true

func get_unlocked_pool() -> Array:
	var pool: Array = []
	for card in all_cards:
		if unlocked_ids.has(card.id):
			pool.append(card)
	return pool

## Called after clearing a station: unlocks roughly one new card for future
## runs from whatever is still locked. Returns the cards that just unlocked
## so the death/summary screen can show them.
func maybe_unlock_new_cards(_depth: int) -> Array:
	var locked: Array = []
	for card in all_cards:
		if not unlocked_ids.has(card.id):
			locked.append(card)
	if locked.is_empty():
		return []
	locked.shuffle()
	var newly_unlocked: Array = []
	if unlock_card(locked[0].id):
		newly_unlocked.append(locked[0])
	return newly_unlocked

func weighted_random_card(pool: Array) -> CardItem:
	if pool.is_empty():
		return null
	var total_weight := 0.0
	var luck := StatManager.get_stat("luck")
	# Luck softly boosts the weight of anything above Common.
	var weights: Array = []
	for card in pool:
		var w: float = CardItem.RARITY_WEIGHTS[card.rarity]
		if card.rarity != CardItem.Rarity.COMMON:
			w *= 1.0 + (luck * 0.01)
		weights.append(w)
		total_weight += w
	var roll := randf() * total_weight
	var cumulative := 0.0
	for i in range(pool.size()):
		cumulative += weights[i]
		if roll <= cumulative:
			return pool[i]
	return pool[pool.size() - 1]

func get_random_choices(count: int) -> Array:
	var pool := get_unlocked_pool()
	var choices: Array = []
	var attempts := 0
	while choices.size() < count and attempts < 100 and choices.size() < pool.size():
		attempts += 1
		var card := weighted_random_card(pool)
		if card and not choices.has(card):
			choices.append(card)
	return choices
