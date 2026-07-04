extends CharacterBody2D

## Generic "static burst" enemy driven entirely by an EnemyData resource, so
## the 40+ enemy roster is content (resources), not code (scenes).

var data: EnemyData
var current_hp: float = 10.0
var _fire_timer: float = 0.0
var _player: Node2D = null

@onready var visual: Polygon2D = $Visual
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var hp_bar: Node2D = $HpBar
@onready var hp_bar_fill: ColorRect = $HpBar/Fill

signal died(enemy: Node)

func setup(enemy_data: EnemyData) -> void:
        data = enemy_data
        current_hp = data.max_hp
        _fire_timer = data.fire_interval * randf()
        _build_visual()

func _ready() -> void:
        collision_layer = 2
        collision_mask = 1 | 2
        add_to_group("enemy")

func _build_visual() -> void:
        var shape := CircleShape2D.new()
        shape.radius = data.radius
        collision.shape = shape
        var pts := PackedVector2Array()
        var sides := 6
        for i in range(sides):
                var a := TAU * float(i) / float(sides)
                pts.append(Vector2(cos(a), sin(a)) * data.radius)
        visual.polygon = pts
        visual.color = data.color
        hp_bar.position = Vector2(0, -data.radius - 12)

func _physics_process(delta: float) -> void:
        if _player == null:
                var players := get_tree().get_nodes_in_group("player")
                if not players.is_empty():
                        _player = players[0]
                return
        var to_player := _player.global_position - global_position
        if data.is_ranged:
                var desired_dist := 220.0
                if to_player.length() > desired_dist:
                        velocity = to_player.normalized() * data.move_speed
                else:
                        velocity = Vector2.ZERO
                _fire_timer -= delta
                if _fire_timer <= 0.0 and to_player.length() < 500.0:
                        _fire_at_player(to_player.normalized())
                        _fire_timer = data.fire_interval
        else:
                velocity = to_player.normalized() * data.move_speed
        move_and_slide()
        _check_player_contact()
        _update_hp_bar()

func _check_player_contact() -> void:
        for i in range(get_slide_collision_count()):
                var collision_info := get_slide_collision(i)
                var collider := collision_info.get_collider()
                if collider and collider.is_in_group("player") and collider.has_method("take_hit"):
                        collider.take_hit(data.contact_damage, (collider.global_position - global_position).normalized())

func _fire_at_player(dir: Vector2) -> void:
        var scene: PackedScene = load("res://scenes/EnemyProjectile.tscn")
        var p = scene.instantiate()
        get_parent().add_child(p)
        p.global_position = global_position
        p.setup(dir, data.contact_damage, data.projectile_speed)

func _update_hp_bar() -> void:
        if data.max_hp <= 0.0:
                return
        hp_bar_fill.scale.x = clamp(current_hp / data.max_hp, 0.0, 1.0)

func take_hit(amount: float, knockback_dir: Vector2 = Vector2.ZERO) -> void:
        current_hp -= amount
        velocity += knockback_dir * 120.0
        if current_hp <= 0.0:
                died.emit(self)
                queue_free()

