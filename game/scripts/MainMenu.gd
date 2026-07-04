extends Control

## Full gamepad-navigable main menu. Root scene of the project.

var _play_button: Button

func _ready() -> void:
	SettingsMenu.apply_saved_settings()
	_build_ui()
	_play_button.grab_focus()

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.03, 0.06, 1.0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var glow := Node2D.new()
	add_child(glow)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := VBoxContainer.new()
	panel.custom_minimum_size = Vector2(420, 0)
	panel.add_theme_constant_override("separation", 20)
	center.add_child(panel)

	var title := Label.new()
	title.text = "SIGNAL"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 64)
	title.modulate = Color(0.35, 0.9, 1.0)
	panel.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "эхо среди бесконечных частот"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.modulate = Color(0.6, 0.65, 0.7)
	panel.add_child(subtitle)

	var unlocked_label := Label.new()
	unlocked_label.text = "Открыто карт: %d / %d" % [CardDatabase.unlocked_ids.size(), CardDatabase.all_cards.size()]
	unlocked_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	unlocked_label.modulate = Color(0.6, 0.65, 0.7)
	panel.add_child(unlocked_label)

	var sep := HSeparator.new()
	panel.add_child(sep)

	_play_button = Button.new()
	_play_button.text = "Настроиться на частоту"
	_play_button.pressed.connect(_on_play)
	panel.add_child(_play_button)

	var settings_button := Button.new()
	settings_button.text = "Настройки"
	settings_button.pressed.connect(_on_settings)
	panel.add_child(settings_button)

	var quit_button := Button.new()
	quit_button.text = "Выход"
	quit_button.pressed.connect(_on_quit)
	panel.add_child(quit_button)

	var hint := Label.new()
	hint.text = "Геймпад: стик — навигация, A — выбрать, B — назад"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.modulate = Color(0.5, 0.5, 0.55)
	panel.add_child(hint)

func _on_play() -> void:
	GameManager.start_new_run()
	get_tree().change_scene_to_file("res://scenes/Game.tscn")

func _on_settings() -> void:
	var settings := SettingsMenu.new()
	add_child(settings)

func _on_quit() -> void:
	get_tree().quit()
