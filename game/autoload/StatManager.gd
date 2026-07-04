extends Node

## Tracks the player's current-run stats. All card modifiers are additive on
## top of a shared base, which is what makes stacking transparent: two "+3
## projectile" cards always sum to "+6", never a multiplied surprise.

signal stats_changed
signal died

var base_stats := {
	"damage": 10.0,
	"fire_rate": 2.2,
	"projectile_count": 1.0,
	"projectile_speed": 620.0,
	"max_hp": 6.0,
	"regen": 0.0,
	"move_speed": 260.0,
	"luck": 0.0,
	"pierce": 0.0,
	"knockback": 40.0,
}

var collected_cards: Array = []
var current_hp: float = 0.0
var _regen_accumulator: float = 0.0

func reset_run() -> void:
	collected_cards.clear()
	current_hp = base_stats["max_hp"]
	_regen_accumulator = 0.0
	stats_changed.emit()

func add_card(card: CardItem) -> void:
	var max_hp_before := get_stat("max_hp")
	collected_cards.append(card)
	var max_hp_after := get_stat("max_hp")
	var hp_gain: float = max(0.0, max_hp_after - max_hp_before)
	current_hp = min(current_hp + hp_gain, max_hp_after)
	current_hp = max(current_hp, 1.0)
	stats_changed.emit()

func get_stat(stat_name: String) -> float:
	var total: float = base_stats.get(stat_name, 0.0)
	for card in collected_cards:
		for mod in card.all_modifiers():
			if CardModifier.stat_key(mod.stat) == stat_name:
				total += mod.value
	return max(total, 0.0) if stat_name != "knockback" else total

func take_damage(amount: float) -> void:
	if amount <= 0.0:
		return
	current_hp -= amount
	current_hp = max(current_hp, 0.0)
	stats_changed.emit()
	if current_hp <= 0.0:
		died.emit()

func process_regen(delta: float) -> void:
	var regen := get_stat("regen")
	if regen <= 0.0:
		return
	_regen_accumulator += regen * delta
	var whole := floor(_regen_accumulator)
	if whole > 0.0:
		var max_hp := get_stat("max_hp")
		if current_hp < max_hp:
			current_hp = min(current_hp + whole, max_hp)
			stats_changed.emit()
		_regen_accumulator -= whole

func is_dead() -> bool:
	return current_hp <= 0.0
