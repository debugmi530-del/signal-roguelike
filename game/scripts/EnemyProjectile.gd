extends Area2D

## Simple hostile projectile fired by ranged enemies/bosses.

var direction: Vector2 = Vector2.RIGHT
var speed: float = 260.0
var damage: float = 1.0
var lifetime: float = 4.0

@onready var visual: Polygon2D = $Visual
@onready var collision: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	var shape := CircleShape2D.new()
	shape.radius = 7.0
	collision.shape = shape
	visual.polygon = PackedVector2Array([
		Vector2(-6, -6), Vector2(6, -6), Vector2(6, 6), Vector2(-6, 6)
	])
	visual.color = Color(1.0, 0.35, 0.55)
	body_entered.connect(_on_body_entered)
	collision_layer = 8
	collision_mask = 1

func setup(dir: Vector2, dmg: float, spd: float) -> void:
	direction = dir
	damage = dmg
	speed = spd

func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.has_method("take_hit") and body.is_in_group("player"):
		body.take_hit(damage, direction)
		queue_free()
