extends CharacterBody2D

## Player-controlled "echo" — gamepad-first: left stick moves, right stick
## aims/fires. Falls back to WASD + mouse for keyboard testing. All visuals
## are built here from primitives per the placeholder-art plan.

const DEADZONE := 0.2
const AIM_DEADZONE := 0.35

@onready var body_visual: Node2D = $BodyVisual
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var muzzle: Marker2D = $Muzzle

var fire_cooldown: float = 0.0
var last_aim_dir: Vector2 = Vector2.RIGHT
var invuln_timer: float = 0.0

func _ready() -> void:
        _build_visual()
        var shape := CircleShape2D.new()
        shape.radius = 14.0
        collision.shape = shape
        StatManager.stats_changed.connect(func(): pass)

func _build_visual() -> void:
        for child in body_visual.get_children():
                child.queue_free()
        var core := Polygon2D.new()
        core.polygon = PackedVector2Array([
                Vector2(0, -16), Vector2(12, 8), Vector2(0, 16), Vector2(-12, 8)
        ])
        core.color = Color(0.25, 0.85, 1.0)
        body_visual.add_child(core)
        var ring := Node2D.new()
        var ring_draw := _make_ring(18.0, Color(0.6, 0.95, 1.0, 0.5))
        body_visual.add_child(ring_draw)
        muzzle.position = Vector2(18, 0)

func _make_ring(radius: float, color: Color) -> Node2D:
        var line := Line2D.new()
        line.width = 2.0
        line.default_color = color
        var points := PackedVector2Array()
        for i in range(33):
                var a := TAU * float(i) / 32.0
                points.append(Vector2(cos(a), sin(a)) * radius)
        line.points = points
        return line

func _physics_process(delta: float) -> void:
        if invuln_timer > 0.0:
                invuln_timer -= delta
                body_visual.visible = int(invuln_timer * 12.0) % 2 == 0
        else:
                body_visual.visible = true

        var move_dir := _get_move_vector()
        var speed := StatManager.get_stat("move_speed")
        velocity = move_dir * speed
        move_and_slide()

        StatManager.process_regen(delta)

        var aim_dir := _get_aim_vector()
        if aim_dir.length() > 0.01:
                last_aim_dir = aim_dir
                rotation = aim_dir.angle()

        fire_cooldown -= delta
        if _is_fire_held() and fire_cooldown <= 0.0:
                _fire()
                fire_cooldown = 1.0 / max(StatManager.get_stat("fire_rate"), 0.1)

func _is_fire_held() -> bool:
        if Input.get_joy_axis(0, JOY_AXIS_RIGHT_X) != 0.0 or Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y) != 0.0:
                var v := Vector2(Input.get_joy_axis(0, JOY_AXIS_RIGHT_X), Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y))
                if v.length() > AIM_DEADZONE:
                        return true
        if Input.is_joy_button_pressed(0, JOY_BUTTON_RIGHT_SHOULDER) or Input.is_joy_button_pressed(0, JOY_BUTTON_TRIGGER_RIGHT):
                return true
        return Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)

func _get_move_vector() -> Vector2:
        var v := Vector2(Input.get_joy_axis(0, JOY_AXIS_LEFT_X), Input.get_joy_axis(0, JOY_AXIS_LEFT_Y))
        if v.length() < DEADZONE:
                v = Vector2.ZERO
        var kb := Vector2.ZERO
        if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
                kb.x -= 1
        if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
                kb.x += 1
        if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
                kb.y -= 1
        if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
                kb.y += 1
        var combined := v + kb
        if combined.length() > 1.0:
                combined = combined.normalized()
        return combined

func _get_aim_vector() -> Vector2:
        var v := Vector2(Input.get_joy_axis(0, JOY_AXIS_RIGHT_X), Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y))
        if v.length() > AIM_DEADZONE:
                return v.normalized()
        if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
                return (get_global_mouse_position() - global_position).normalized()
        var dpad := Vector2.ZERO
        if Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_LEFT):
                dpad.x -= 1
        if Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_RIGHT):
                dpad.x += 1
        if Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_UP):
                dpad.y -= 1
        if Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_DOWN):
                dpad.y += 1
        if dpad.length() > 0.0:
                return dpad.normalized()
        return Vector2.ZERO

func _fire() -> void:
        var projectile_scene: PackedScene = load("res://scenes/Projectile.tscn")
        var count := int(StatManager.get_stat("projectile_count"))
        count = max(count, 1)
        var spread := deg_to_rad(8.0)
        # spread projectiles symmetrically around the aim direction
        for i in range(count):
                var t := 0.0
                if count > 1:
                        t = (float(i) / float(count - 1)) - 0.5
                var angle := last_aim_dir.angle() + t * spread * (count - 1)
                var dir := Vector2.RIGHT.rotated(angle)
                var p = projectile_scene.instantiate()
                get_parent().add_child(p)
                p.global_position = global_position + last_aim_dir * 20.0
                p.setup(dir, StatManager.get_stat("damage"), StatManager.get_stat("projectile_speed"), int(StatManager.get_stat("pierce")), StatManager.get_stat("knockback"))

func take_hit(amount: float, knockback_dir: Vector2 = Vector2.ZERO) -> void:
        if invuln_timer > 0.0:
                return
        StatManager.take_damage(amount)
        invuln_timer = 0.8
        velocity += knockback_dir * 200.0
