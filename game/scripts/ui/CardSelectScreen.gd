class_name CardSelectScreen
extends CanvasLayer

## Full gamepad-navigable "pick a card" overlay for shops/treasure/level-up
## moments. Cards show live-stacking previews via CardItem.get_preview_lines.

signal card_chosen(card: CardItem)

var choices: Array = []
var _card_panels: Array = []
var _title: String = "ВЫБЕРИ КАРТУ"

func setup(cards: Array, title: String = "ВЫБЕРИ КАРТУ") -> void:
	choices = cards
	_title = title

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 40
	_build_ui()
	if not _card_panels.is_empty():
		_card_panels[0].grab_focus()

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.03, 0.06, 0.92)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var root_v := VBoxContainer.new()
	root_v.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_v.alignment = BoxContainer.ALIGNMENT_CENTER
	root_v.add_theme_constant_override("separation", 24)
	add_child(root_v)

	var title_label := Label.new()
	title_label.text = _title
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 34)
	root_v.add_child(title_label)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 28)
	root_v.add_child(CenterContainer.new())
	var center := root_v.get_child(root_v.get_child_count() - 1)
	center.add_child(row)

	for card in choices:
		var btn := _build_card_button(card)
		row.add_child(btn)
		_card_panels.append(btn)

	var hint := Label.new()
	hint.text = "Крестовина/стик — выбор, A — взять"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.modulate = Color(0.7, 0.7, 0.75)
	root_v.add_child(hint)

func _build_card_button(card: CardItem) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(260, 340)
	btn.focus_mode = Control.FOCUS_ALL
	btn.toggle_mode = false
	btn.pressed.connect(func(): _choose(card))

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.09, 0.14)
	style.border_color = CardItem.RARITY_COLORS[card.rarity]
	style.set_border_width_all(3)
	style.set_corner_radius_all(10)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	btn.add_theme_stylebox_override("normal", style)
	var style_focus := style.duplicate()
	style_focus.border_color = Color(1, 1, 1)
	btn.add_theme_stylebox_override("focus", style_focus)
	btn.add_theme_stylebox_override("hover", style_focus)

	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	btn.add_child(vbox)

	var rarity_label := Label.new()
	rarity_label.text = CardItem.RARITY_NAMES[card.rarity]
	rarity_label.modulate = CardItem.RARITY_COLORS[card.rarity]
	vbox.add_child(rarity_label)

	var name_label := Label.new()
	name_label.text = card.display_name
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(name_label)

	var sep := HSeparator.new()
	vbox.add_child(sep)

	for line in card.get_preview_lines():
		var l := Label.new()
		l.text = line
		l.autowrap_mode = TextServer.AUTOWRAP_WORD
		l.add_theme_font_size_override("font_size", 14)
		vbox.add_child(l)

	if not card.flavor_text.is_empty():
		var flavor := Label.new()
		flavor.text = card.flavor_text
		flavor.modulate = Color(0.7, 0.7, 0.75)
		flavor.autowrap_mode = TextServer.AUTOWRAP_WORD
		flavor.add_theme_font_size_override("font_size", 13)
		vbox.add_child(flavor)

	return btn

func _choose(card: CardItem) -> void:
	card_chosen.emit(card)
	queue_free()
