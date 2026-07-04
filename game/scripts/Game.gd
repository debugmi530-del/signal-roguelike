extends Node2D

## Orchestrates one station: generates the room layout, spawns the player,
## activates rooms as the player crosses into them, and reacts to combat,
## shop/treasure picks, boss defeats and death.

const ROOM_SIZE := Vector2(960, 640)
const WALL_THICKNESS := 32.0
const DOOR_GAP := 140.0

@onready var world: Node2D = $World
@onready var camera: Camera2D = $Camera2D

var rooms: Dictionary = {}
var room_generator := RoomGenerator.new()
var current_room_cell: Vector2i = Vector2i(9999, 9999)
var player: CharacterBody2D
var hud: HUD
var _pause_menu: PauseMenu = null
var _room_enemy_counts: Dictionary = {}
var _room_walls: Dictionary = {}
var _boss_node: Node = null
var _resolving_overlay: bool = false

func _ready() -> void:
	add_to_group("game")
	StatManager.died.connect(_on_player_died)
	_start_station()

func _start_station() -> void:
	for child in world.get_children():
		child.queue_free()
	rooms = room_generator.generate()
	current_room_cell = Vector2i(9999, 9999)
	_room_enemy_counts.clear()
	_room_walls.clear()
	_boss_node = null

	_build_all_room_shells()
	_spawn_player()

	hud = HUD.new()
	add_child(hud)

	_enter_room(Vector2i.ZERO)

func _build_all_room_shells() -> void:
	for pos in rooms.keys():
		var room: RoomInfo = rooms[pos]
		_build_room_walls(room)

func _room_world_center(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * ROOM_SIZE.x, cell.y * ROOM_SIZE.y)

func _build_room_walls(room: RoomInfo) -> void:
	var center := _room_world_center(room.grid_pos)
	var holder := Node2D.new()
	holder.name = "RoomWalls_%d_%d" % [room.grid_pos.x, room.grid_pos.y]
	world.add_child(holder)
	_room_walls[room.grid_pos] = holder

	var half := ROOM_SIZE / 2.0

	# Floor tint per room type for readability.
	var floor_rect := ColorRect.new()
	floor_rect.color = _floor_color(room)
	floor_rect.position = center - half
	floor_rect.size = ROOM_SIZE
	floor_rect.z_index = -10
	floor_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(floor_rect)

	# Four edges, each possibly split around a door gap.
	_add_edge(holder, center, half, Vector2i(0, -1), room.has_neighbor(Vector2i(0, -1)))
	_add_edge(holder, center, half, Vector2i(0, 1), room.has_neighbor(Vector2i(0, 1)))
	_add_edge(holder, center, half, Vector2i(-1, 0), room.has_neighbor(Vector2i(-1, 0)))
	_add_edge(holder, center, half, Vector2i(1, 0), room.has_neighbor(Vector2i(1, 0)))

func _floor_color(room: RoomInfo) -> Color:
	var theme := GameManager.current_theme
	var base_color := theme.background_color if theme else Color(0.05, 0.06, 0.1)
	match room.type:
		RoomInfo.Type.BOSS:
			return base_color.lightened(0.08).lerp(Color(0.3, 0.05, 0.08), 0.3)
		RoomInfo.Type.SHOP:
			return base_color.lightened(0.12)
		RoomInfo.Type.TREASURE:
			return base_color.lerp(Color(0.35, 0.3, 0.05), 0.3)
		_:
			return base_color

func _add_edge(holder: Node2D, center: Vector2, half: Vector2, dir: Vector2i, has_door: bool) -> void:
	var wall_color := Color(0.16, 0.18, 0.26)
	if GameManager.current_theme:
		wall_color = GameManager.current_theme.wall_color
	if dir.x == 0:
		# Horizontal wall (top or bottom edge)
		var y := center.y - half.y if dir.y < 0 else center.y + half.y - WALL_THICKNESS
		if not has_door:
			_make_wall_segment(holder, Vector2(center.x - half.x, y), Vector2(ROOM_SIZE.x, WALL_THICKNESS), wall_color)
		else:
			var seg_w := (ROOM_SIZE.x - DOOR_GAP) / 2.0
			_make_wall_segment(holder, Vector2(center.x - half.x, y), Vector2(seg_w, WALL_THICKNESS), wall_color)
			_make_wall_segment(holder, Vector2(center.x + half.x - seg_w, y), Vector2(seg_w, WALL_THICKNESS), wall_color)
	else:
		var x := center.x - half.x if dir.x < 0 else center.x + half.x - WALL_THICKNESS
		if not has_door:
			_make_wall_segment(holder, Vector2(x, center.y - half.y), Vector2(WALL_THICKNESS, ROOM_SIZE.y), wall_color)
		else:
			var seg_h := (ROOM_SIZE.y - DOOR_GAP) / 2.0
			_make_wall_segment(holder, Vector2(x, center.y - half.y), Vector2(WALL_THICKNESS, seg_h), wall_color)
			_make_wall_segment(holder, Vector2(x, center.y + half.y - seg_h), Vector2(WALL_THICKNESS, seg_h), wall_color)

func _make_wall_segment(holder: Node2D, top_left: Vector2, size: Vector2, color: Color) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	holder.add_child(body)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	shape.position = top_left + size / 2.0
	body.add_child(shape)
	var visual := ColorRect.new()
	visual.color = color
	visual.position = top_left
	visual.size = size
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(visual)

func _spawn_player() -> void:
	var scene: PackedScene = load("res://scenes/Player.tscn")
	player = scene.instantiate()
	world.add_child(player)
	player.global_position = _room_world_center(Vector2i.ZERO)
	camera.reparent(player)
	camera.position = Vector2.ZERO

func _process(_delta: float) -> void:
	if player == null or not is_instance_valid(player) or get_tree().paused:
		_check_pause_input()
		return
	_check_pause_input()
	var cell := Vector2i(round(player.global_position.x / ROOM_SIZE.x), round(player.global_position.y / ROOM_SIZE.y))
	if cell != current_room_cell and rooms.has(cell):
		_enter_room(cell)

func _check_pause_input() -> void:
	if _pause_menu != null:
		return
	if Input.is_action_just_pressed("ui_cancel") or Input.is_joy_button_pressed(0, JOY_BUTTON_START):
		if Input.is_joy_button_pressed(0, JOY_BUTTON_START) and _pause_menu != null:
			return
		_open_pause_menu()

func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_START:
		if _pause_menu == null and not get_tree().paused:
			_open_pause_menu()

func _open_pause_menu() -> void:
	if get_tree().paused:
		return
	_pause_menu = PauseMenu.new()
	add_child(_pause_menu)
	get_tree().paused = true
	_pause_menu.resumed.connect(func():
		get_tree().paused = false
		_pause_menu = null
	)
	_pause_menu.exit_to_menu_requested.connect(func():
		get_tree().paused = false
		_pause_menu = null
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	)

func _enter_room(cell: Vector2i) -> void:
	current_room_cell = cell
	var room: RoomInfo = rooms[cell]
	var was_visited := room.visited
	room.visited = true
	_update_camera_limits(cell)

	if was_visited or room.cleared or _resolving_overlay:
		return

	match room.type:
		RoomInfo.Type.ENEMY:
			_spawn_enemy_pack(room)
		RoomInfo.Type.BOSS:
			_spawn_boss(room)
		RoomInfo.Type.SHOP:
			_open_card_choice(room, 3)
		RoomInfo.Type.TREASURE:
			_open_card_choice(room, 1)
		RoomInfo.Type.START:
			room.cleared = true

func _update_camera_limits(cell: Vector2i) -> void:
	var center := _room_world_center(cell)
	var half := ROOM_SIZE / 2.0
	camera.limit_left = int(center.x - half.x)
	camera.limit_right = int(center.x + half.x)
	camera.limit_top = int(center.y - half.y)
	camera.limit_bottom = int(center.y + half.y)

func _spawn_enemy_pack(room: RoomInfo) -> void:
	var center := _room_world_center(room.grid_pos)
	var count: int = room.enemy_count
	_room_enemy_counts[room.grid_pos] = count
	for i in range(count):
		var data := EnemyDatabase.get_random_enemy(GameManager.current_theme)
		if data == null:
			continue
		var scene: PackedScene = load("res://scenes/Enemy.tscn")
		var enemy = scene.instantiate()
		world.add_child(enemy)
		var offset := Vector2(randf_range(-300, 300), randf_range(-200, 200))
		enemy.global_position = center + offset
		enemy.setup(data)
		enemy.died.connect(func(_e): _on_room_enemy_died(room))

func _on_room_enemy_died(room: RoomInfo) -> void:
	_room_enemy_counts[room.grid_pos] = _room_enemy_counts.get(room.grid_pos, 1) - 1
	if _room_enemy_counts[room.grid_pos] <= 0:
		room.cleared = true

func _spawn_boss(room: RoomInfo) -> void:
	var center := _room_world_center(room.grid_pos)
	var data := EnemyDatabase.get_random_boss()
	if data == null:
		room.cleared = true
		return
	var scene: PackedScene = load("res://scenes/Boss.tscn")
	var boss = scene.instantiate()
	world.add_child(boss)
	boss.global_position = center
	boss.setup(data)
	_boss_node = boss
	boss.died.connect(func(_b):
		room.cleared = true
		_boss_node = null
		_on_boss_defeated()
	)

func _on_boss_defeated() -> void:
	GameManager.advance_station()
	await get_tree().create_timer(1.0).timeout
	_start_station()

func _open_card_choice(room: RoomInfo, count: int) -> void:
	_resolving_overlay = true
	get_tree().paused = true
	var title := "МАГАЗИН ЧАСТОТ" if room.type == RoomInfo.Type.SHOP else "НАЙДЕНА КАРТА"
	var screen := CardSelectScreen.new()
	var cards := CardDatabase.get_random_choices(count)
	screen.setup(cards, title)
	add_child(screen)
	screen.card_chosen.connect(func(card: CardItem):
		StatManager.add_card(card)
		room.cleared = true
		get_tree().paused = false
		_resolving_overlay = false
	)

func _on_player_died() -> void:
	if get_tree().paused:
		return
	get_tree().paused = true
	GameManager.end_run()
	var screen := DeathScreen.new()
	screen.setup(GameManager.last_run_depth, GameManager.newly_unlocked_cards)
	add_child(screen)
	screen.return_to_menu_requested.connect(func():
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	)
