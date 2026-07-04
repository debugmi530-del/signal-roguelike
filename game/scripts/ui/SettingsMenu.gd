class_name SettingsMenu
extends CanvasLayer

## Full gamepad-navigable settings overlay. Instantiated with `.new()` from
## either the main menu or the pause menu — no separate scene file needed.
## Persists to user://settings.cfg and can be applied at boot.

signal closed

const CONFIG_PATH := "user://settings.cfg"

var _volume_slider: HSlider
var _fullscreen_check: CheckButton
var _back_button: Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 50
	_build_ui()
	_load_into_controls()
	_back_button.grab_focus()

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.03, 0.06, 0.95)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := VBoxContainer.new()
	panel.custom_minimum_size = Vector2(480, 0)
	panel.add_theme_constant_override("separation", 18)
	center.add_child(panel)

	var title := Label.new()
	title.text = "НАСТРОЙКИ"
	title.add_theme_font_size_override("font_size", 36)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(title)

	var vol_label := Label.new()
	vol_label.text = "Громкость"
	panel.add_child(vol_label)

	_volume_slider = HSlider.new()
	_volume_slider.min_value = 0.0
	_volume_slider.max_value = 1.0
	_volume_slider.step = 0.05
	_volume_slider.focus_mode = Control.FOCUS_ALL
	_volume_slider.value_changed.connect(_on_volume_changed)
	panel.add_child(_volume_slider)

	_fullscreen_check = CheckButton.new()
	_fullscreen_check.text = "Полноэкранный режим"
	_fullscreen_check.focus_mode = Control.FOCUS_ALL
	_fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	panel.add_child(_fullscreen_check)

	var hint := Label.new()
	hint.text = "Геймпад: стик/крестовина — навигация, A — выбрать, B — назад"
	hint.modulate = Color(0.7, 0.7, 0.75)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD
	panel.add_child(hint)

	_back_button = Button.new()
	_back_button.text = "Назад"
	_back_button.focus_mode = Control.FOCUS_ALL
	_back_button.pressed.connect(_on_back_pressed)
	panel.add_child(_back_button)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
		get_viewport().set_input_as_handled()

func _on_back_pressed() -> void:
	_save_from_controls()
	closed.emit()
	queue_free()

func _on_volume_changed(value: float) -> void:
	var idx := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(idx, linear_to_db(max(value, 0.0001)))

func _on_fullscreen_toggled(pressed: bool) -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if pressed else DisplayServer.WINDOW_MODE_WINDOWED)

func _load_into_controls() -> void:
	var cfg := ConfigFile.new()
	var volume := 0.8
	var fullscreen := true
	if cfg.load(CONFIG_PATH) == OK:
		volume = cfg.get_value("audio", "volume", 0.8)
		fullscreen = cfg.get_value("display", "fullscreen", true)
	_volume_slider.value = volume
	_fullscreen_check.button_pressed = fullscreen
	_on_volume_changed(volume)

func _save_from_controls() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "volume", _volume_slider.value)
	cfg.set_value("display", "fullscreen", _fullscreen_check.button_pressed)
	cfg.save(CONFIG_PATH)

## Called once at game boot (from MainMenu) so saved settings take effect
## before the player ever opens the settings screen.
static func apply_saved_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(CONFIG_PATH) != OK:
		return
	var volume: float = cfg.get_value("audio", "volume", 0.8)
	var fullscreen: bool = cfg.get_value("display", "fullscreen", true)
	var idx := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(idx, linear_to_db(max(volume, 0.0001)))
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
