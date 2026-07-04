class_name HUD
extends CanvasLayer

## Left-side Isaac Rebirth-style stat panel: plain numbers, no percent signs.

var _hp_label: Label
var _damage_label: Label
var _fire_rate_label: Label
var _proj_speed_label: Label
var _move_speed_label: Label
var _luck_label: Label
var _station_label: Label

func _ready() -> void:
	layer = 10
	_build_ui()
	StatManager.stats_changed.connect(_refresh)
	_refresh()

func _build_ui() -> void:
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel.position = Vector2(16, 16)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.03, 0.06, 0.7)
	style.set_corner_radius_all(8)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	var vbox := VBoxContainer.new()
	panel.add_child(vbox)

	_station_label = _make_label(vbox, "Станция 0")
	_station_label.add_theme_font_size_override("font_size", 20)
	_hp_label = _make_label(vbox, "HP: 6")
	_damage_label = _make_label(vbox, "Урон: 10")
	_fire_rate_label = _make_label(vbox, "Перезарядка: 2.2")
	_proj_speed_label = _make_label(vbox, "Скорость снаряда: 620")
	_move_speed_label = _make_label(vbox, "Скорость: 260")
	_luck_label = _make_label(vbox, "Удача: 0")

func _make_label(parent: Control, text: String) -> Label:
	var l := Label.new()
	l.text = text
	parent.add_child(l)
	return l

func _refresh() -> void:
	_hp_label.text = "HP: %d / %d" % [int(ceil(StatManager.current_hp)), int(StatManager.get_stat("max_hp"))]
	_damage_label.text = "Урон: %s" % _fmt(StatManager.get_stat("damage"))
	_fire_rate_label.text = "Перезарядка: %s" % _fmt(StatManager.get_stat("fire_rate"))
	_proj_speed_label.text = "Скорость снаряда: %s" % _fmt(StatManager.get_stat("projectile_speed"))
	_move_speed_label.text = "Скорость: %s" % _fmt(StatManager.get_stat("move_speed"))
	_luck_label.text = "Удача: %s" % _fmt(StatManager.get_stat("luck"))
	_station_label.text = "Станция %d" % GameManager.current_station_index

func _fmt(v: float) -> String:
	if is_equal_approx(v, round(v)):
		return str(int(round(v)))
	return str(snapped(v, 0.01))
