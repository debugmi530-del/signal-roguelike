extends CharacterBody2D

## Generic boss controller, driven by a BossData resource. Fires a radial
## burst pattern and toughens its pace once below phase_two_hp_ratio.

var data: BossData
var current_hp: float = 200.0
var _fire_timer: float = 0.0
var _player: Node2D = null
var phase_two: bool = false

signal died(boss: Node)
signal hp_changed(current: float, max_hp: float)

@onready var visual: Polygon2D = $Visual
@onready var collision: CollisionShape2D = $CollisionShape2D

func setup(boss_data: BossData) -> void:
	data = boss_data
	current_hp = data.max_hp
	_fire_timer = data.burst_interval
	_build_visual()

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1 | 2
	add_to_group("enemy")
	add_to_group("boss")

func _build_visual() -> void:
	var shape := CircleShape2D.new()
	shape.radius = data.radius
	collision.shape = shape
	var pts := PackedVector2Array()
	var sides := 8
	for i in range(sides):
		var a := TAU * float(i) / float(sides)
		pts.append(Vector2(cos(a), sin(a)) * data.radius)
	visual.polygon = pts
	visual.color = data.color

func _physics_process(delta: float) -> void:
	if _player == null:
		var players := get_tree().get_nodes_in_group("player")
		if not players.is_empty():
			_player = players[0]
		return
	if not phase_two and current_hp <= data.max_hp * data.phase_two_hp_ratio:
		phase_two = true

	var to_player := _player.global_position - global_position
	var desired_dist := 260.0
	if to_player.length() > desired_dist:
		velocity = to_player.normalized() * data.move_speed
	else:
		velocity = to_player.normalized() * -data.move_speed * 0.4

	_fire_timer -= delta
	if _fire_timer <= 0.0:
		_burst_fire()
		_fire_timer = data.burst_interval / (1.6 if phase_two else 1.0)

	move_and_slide()
	_check_player_contact()

func _check_player_contact() -> void:
	for i in range(get_slide_collision_count()):
		var collision_info := get_slide_collision(i)
		var collider := collision_info.get_collider()
		if collider and collider.is_in_group("player") and collider.has_method("take_hit"):
			collider.take_hit(data.contact_damage, (collider.global_position - global_position).normalized())

func _burst_fire() -> void:
	var scene: PackedScene = load("res://scenes/EnemyProjectile.tscn")
	var count: int = data.burst_count
	for i in range(count):
		var angle := TAU * float(i) / float(count)
		var dir := Vector2.RIGHT.rotated(angle)
		var p = scene.instantiate()
		get_parent().add_child(p)
		p.global_position = global_position
		p.setup(dir, data.contact_damage, data.projectile_speed)

func take_hit(amount: float, knockback_dir: Vector2 = Vector2.ZERO) -> void:
	current_hp -= amount
	velocity += knockback_dir * 60.0
	hp_changed.emit(current_hp, data.max_hp)
	if current_hp <= 0.0:
		died.emit(self)
		queue_free()
