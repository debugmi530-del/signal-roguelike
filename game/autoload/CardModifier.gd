class_name CardModifier
extends Resource

## A single stat modifier attached to a card. Cards can carry multiple
## modifiers (and sacrifice cards carry both a gain and a cost modifier).

enum Stat {
	DAMAGE,
	FIRE_RATE,
	PROJECTILE_COUNT,
	PROJECTILE_SPEED,
	MAX_HP,
	REGEN,
	MOVE_SPEED,
	LUCK,
	PIERCE,
	KNOCKBACK,
}

@export var stat: Stat = Stat.DAMAGE
@export var value: float = 0.0

static func stat_key(stat_id: int) -> String:
	match stat_id:
		Stat.DAMAGE:
			return "damage"
		Stat.FIRE_RATE:
			return "fire_rate"
		Stat.PROJECTILE_COUNT:
			return "projectile_count"
		Stat.PROJECTILE_SPEED:
			return "projectile_speed"
		Stat.MAX_HP:
			return "max_hp"
		Stat.REGEN:
			return "regen"
		Stat.MOVE_SPEED:
			return "move_speed"
		Stat.LUCK:
			return "luck"
		Stat.PIERCE:
			return "pierce"
		Stat.KNOCKBACK:
			return "knockback"
	return ""

static func stat_label_ru(stat_id: int) -> String:
	match stat_id:
		Stat.DAMAGE:
			return "урону"
		Stat.FIRE_RATE:
			return "перезарядке"
		Stat.PROJECTILE_COUNT:
			return "снарядам в очереди"
		Stat.PROJECTILE_SPEED:
			return "скорости снаряда"
		Stat.MAX_HP:
			return "макс. HP"
		Stat.REGEN:
			return "регенерации"
		Stat.MOVE_SPEED:
			return "скорости передвижения"
		Stat.LUCK:
			return "удаче"
		Stat.PIERCE:
			return "пробитию"
		Stat.KNOCKBACK:
			return "отбрасыванию"
	return ""
