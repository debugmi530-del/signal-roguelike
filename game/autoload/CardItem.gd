class_name CardItem
extends Resource

## Data definition for a single collectible "signal interference" card.
## 300-card target: 14 base modules (~200 cards) + 10 sacrifice sub-modules
## (~100 cards). This resource is the atomic unit for both.

enum Rarity {
	COMMON,
	UNCOMMON,
	RARE,
	EPIC,
	LEGENDARY,
	MYTHIC,
	ARCHON,
}

const RARITY_WEIGHTS := {
	Rarity.COMMON: 35,
	Rarity.UNCOMMON: 30,
	Rarity.RARE: 16,
	Rarity.EPIC: 9,
	Rarity.LEGENDARY: 5,
	Rarity.MYTHIC: 3,
	Rarity.ARCHON: 2,
}

const RARITY_NAMES := {
	Rarity.COMMON: "Обычная",
	Rarity.UNCOMMON: "Необычная",
	Rarity.RARE: "Редкая",
	Rarity.EPIC: "Эпическая",
	Rarity.LEGENDARY: "Легендарная",
	Rarity.MYTHIC: "Мифическая",
	Rarity.ARCHON: "Архонтовая",
}

const RARITY_COLORS := {
	Rarity.COMMON: Color(0.75, 0.78, 0.8),
	Rarity.UNCOMMON: Color(0.34, 0.87, 0.53),
	Rarity.RARE: Color(0.27, 0.58, 1.0),
	Rarity.EPIC: Color(0.66, 0.32, 0.98),
	Rarity.LEGENDARY: Color(1.0, 0.65, 0.13),
	Rarity.MYTHIC: Color(1.0, 0.27, 0.4),
	Rarity.ARCHON: Color(1.0, 0.93, 0.36),
}

## Module identifier — matches the design plan's module breakdown, e.g.
## "damage", "fire_rate", "projectile_count", "projectile_speed",
## "trajectory", "on_hit", "survival", "mobility", "economy", "aura",
## "active", "station_synergy", "unique",
## and for sacrifice cards: "sac_damage", "sac_fire_rate", "sac_projectile",
## "sac_projectile_speed", "sac_trajectory", "sac_survival", "sac_mobility",
## "sac_luck", "sac_active", "sac_unique".
@export var module: String = "damage"
@export var id: String = ""
@export var display_name: String = ""
@export_multiline var flavor_text: String = ""
@export var rarity: Rarity = Rarity.COMMON
@export var modifiers: Array[CardModifier] = []
@export var is_sacrifice: bool = false
## For sacrifice cards, the cost is expressed as its own (usually negative)
## modifiers so it stacks with the same additive rules as normal modifiers.
@export var sacrifice_modifiers: Array[CardModifier] = []

func all_modifiers() -> Array:
	var combined: Array = []
	combined.append_array(modifiers)
	if is_sacrifice:
		combined.append_array(sacrifice_modifiers)
	return combined

## Builds the transparent "what happens if I take this" preview lines shown
## on the card, honoring the additive-stacking rule described in the plan:
## a second copy of "+3 projectiles" shows "+6 projectiles total" rather than
## re-stating +3.
func get_preview_lines() -> Array:
	var lines: Array = []
	for mod in all_modifiers():
		var key := CardModifier.stat_key(mod.stat)
		var current_total := StatManager.get_stat(key)
		var new_total := current_total + mod.value
		var sign_str := "+" if mod.value >= 0.0 else ""
		lines.append("%s%s к %s → станет %s" % [sign_str, _fmt(mod.value), CardModifier.stat_label_ru(mod.stat), _fmt(new_total)])
	return lines

func _fmt(v: float) -> String:
	if is_equal_approx(v, round(v)):
		return str(int(round(v)))
	return str(snapped(v, 0.01))
