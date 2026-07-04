class_name DeathScreen
extends CanvasLayer

## Shown on death. Reports depth reached and any cards newly unlocked into
## the pool for future runs — the game's only cross-run progression.

signal return_to_menu_requested

var depth_reached: int = 0
var newly_unlocked: Array = []
var _menu_button: Button

func setup(depth: int, unlocked: Array) -> void:
	depth_reached = depth
	newly_unlocked = unlocked

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 60
	_build_ui()
	_menu_button.grab_focus()

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.03, 0.01, 0.04, 0.95)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := VBoxContainer.new()
	panel.custom_minimum_size = Vector2(480, 0)
	panel.add_theme_constant_override("separation", 14)
	center.add_child(panel)

	var title := Label.new()
	title.text = "СИГНАЛ ПОТЕРЯН"
	title.add_theme_font_size_override("font_size", 40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(title)

	var depth_label := Label.new()
	depth_label.text = "Достигнута станция: %d" % depth_reached
	depth_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	depth_label.add_theme_font_size_override("font_size", 20)
	panel.add_child(depth_label)

	if not newly_unlocked.is_empty():
		var sep := HSeparator.new()
		panel.add_child(sep)
		var unlock_title := Label.new()
		unlock_title.text = "Новые карты открыты для будущих попыток:"
		unlock_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		unlock_title.autowrap_mode = TextServer.AUTOWRAP_WORD
		panel.add_child(unlock_title)
		for card in newly_unlocked:
			var l := Label.new()
			l.text = "• %s (%s)" % [card.display_name, CardItem.RARITY_NAMES[card.rarity]]
			l.modulate = CardItem.RARITY_COLORS[card.rarity]
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			panel.add_child(l)
	else:
		var none_label := Label.new()
		none_label.text = "Новых карт не открыто в этот раз."
		none_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		none_label.modulate = Color(0.7, 0.7, 0.75)
		panel.add_child(none_label)

	_menu_button = Button.new()
	_menu_button.text = "В главное меню"
	_menu_button.pressed.connect(_on_menu)
	panel.add_child(_menu_button)

func _on_menu() -> void:
	return_to_menu_requested.emit()
	queue_free()
