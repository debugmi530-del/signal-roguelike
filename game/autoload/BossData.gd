class_name BossData
extends Resource

## Configurable stat/pattern block for a boss. Boss.tscn reads one of these
## at spawn time — same scaling idea as EnemyData, add more .tres files in
## resources/bosses/ to grow toward the plan's 15+ bosses.

@export var id: String = ""
@export var display_name: String = ""
@export var max_hp: float = 200.0
@export var move_speed: float = 60.0
@export var contact_damage: float = 2.0
@export var radius: float = 34.0
@export var color: Color = Color(0.8, 0.2, 0.6)
@export var projectile_speed: float = 300.0
@export var burst_count: int = 8
@export var burst_interval: float = 2.2
@export var phase_two_hp_ratio: float = 0.5
