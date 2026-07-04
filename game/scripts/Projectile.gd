extends Area2D

## Player projectile — a simple traveling "pulse". Pierce count controls how
## many enemies it can pass through before despawning.

var direction: Vector2 = Vector2.RIGHT
var speed: float = 600.0
var damage: float = 10.0
var pierce_left: int = 0
var knockback: float = 40.0
var lifetime: float = 2.5
var _hit_bodies: Array = []

@onready var visual: Polygon2D = $Visual
@onready var collision: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	var shape := CircleShape2D.new()
	shape.radius = 6.0
	collision.shape = shape
	visual.polygon = PackedVector2Array([
		Vector2(-6, -3), Vector2(6, 0), Vector2(-6, 3)
	])
	visual.color = Color(1.0, 0.9, 0.3)
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	collision_layer = 4
	collision_mask = 2

func setup(dir: Vector2, dmg: float, spd: float, pierce: int, kb: float) -> void:
	direction = dir
	damage = dmg
	speed = spd
	pierce_left = pierce
	knockback = kb
	rotation = dir.angle()

func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if _hit_bodies.has(body):
		return
	if body.has_method("take_hit"):
		_hit_bodies.append(body)
		var kb_dir := direction
		body.take_hit(damage, kb_dir)
		_consume_pierce()

func _on_area_entered(area: Node) -> void:
	pass

func _consume_pierce() -> void:
	if pierce_left <= 0:
		queue_free()
	else:
		pierce_left -= 1
