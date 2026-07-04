class_name EnemyData
extends Resource

## Configurable stat block for a "static/interference" enemy. A single
## Enemy.tscn scene reads one of these at spawn time, which is how the plan's
## 40+ enemy types scale without needing 40+ scenes — add more .tres files
## in resources/enemies/ any time.

@export var id: String = ""
@export var display_name: String = ""
@export var max_hp: float = 10.0
@export var move_speed: float = 90.0
@export var contact_damage: float = 1.0
@export var radius: float = 14.0
@export var color: Color = Color(1.0, 0.4, 0.4)
@export var is_ranged: bool = false
@export var projectile_speed: float = 260.0
@export var fire_interval: float = 1.6
@export var xp_weight: float = 1.0
