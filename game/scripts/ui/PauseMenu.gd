class_name PauseMenu
extends CanvasLayer

## Gamepad-navigable pause overlay. Opened with Start button or ui_cancel
## during gameplay.

signal resumed
signal exit_to_menu_requested

var _resume_button: Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 30
	_build_ui()
	_resume_button.grab_focus()

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.03, 0.06, 0.85)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := VBoxContainer.new()
	panel.custom_minimum_size = Vector2(360, 0)
	panel.add_theme_constant_override("separation", 16)
	center.add_child(panel)

	var title := Label.new()
	title.text = "ПАУЗА"
	title.add_theme_font_size_override("font_size", 34)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(title)

	_resume_button = Button.new()
	_resume_button.text = "Продолжить"
	_resume_button.pressed.connect(_on_resume)
	panel.add_child(_resume_button)

	var settings_btn := Button.new()
	settings_btn.text = "Настройки"
	settings_btn.pressed.connect(_on_settings)
	panel.add_child(settings_btn)

	var exit_btn := Button.new()
	exit_btn.text = "Выйти в меню"
	exit_btn.pressed.connect(_on_exit)
	panel.add_child(exit_btn)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_resume()
		get_viewport().set_input_as_handled()

func _on_resume() -> void:
	resumed.emit()
	queue_free()

func _on_settings() -> void:
	var settings := SettingsMenu.new()
	add_child(settings)

func _on_exit() -> void:
	exit_to_menu_requested.emit()
	queue_free()
