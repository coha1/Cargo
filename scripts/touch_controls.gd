class_name TouchControls
extends Control


## Force the overlay visible even on non-touch desktop — useful for layout testing.
@export var force_visible: bool = false


## Internal button descriptor — one per on-screen control.
class _Btn:
	var rect:        Rect2
	var action:      String
	var icon:        String
	var touch_index: int  = -1   # -1 = not currently pressed
	var panel:       Panel = null

	func _init(r: Rect2, a: String, i: String) -> void:
		rect = r; action = a; icon = i


var _buttons: Array[_Btn] = []


func _ready() -> void:
	if not force_visible and not DisplayServer.is_touchscreen_available():
		visible = false
		return

	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_build_buttons()


# ── Layout ────────────────────────────────────────────────────────────────────

func _build_buttons() -> void:
	var s: Vector2 = get_viewport_rect().size

	# ── Left thumb — steering ─────────────────────────────────────────────────
	_add_btn(Rect2(30,         s.y - 185, 145, 155), "steer_left",  "◄")
	_add_btn(Rect2(190,        s.y - 185, 145, 155), "steer_right", "►")

	# ── Left thumb — aerial pitch (above steering) ────────────────────────────
	_add_btn(Rect2(30,         s.y - 345, 145, 120), "pitch_forward", "⌃")
	_add_btn(Rect2(190,        s.y - 345, 145, 120), "pitch_back",    "⌄")

	# ── Right thumb — throttle, brake, drift ──────────────────────────────────
	_add_btn(Rect2(s.x - 210,  s.y - 240, 180, 210), "accelerate", "GAS")
	_add_btn(Rect2(s.x - 395,  s.y - 165, 165, 135), "brake",      "BRAKE")
	_add_btn(Rect2(s.x - 395,  s.y - 310, 165, 115), "ebrake",     "DRIFT")

	# ── Top centre — delivery order actions ───────────────────────────────────
	_add_btn(Rect2(s.x * 0.5 - 160, 20, 148, 58), "accept_order",  "✓  ACCEPT")
	_add_btn(Rect2(s.x * 0.5 +  12, 20, 148, 58), "decline_order", "✕  CANCEL")


func _add_btn(rect: Rect2, action: String, icon: String) -> void:
	var btn := _Btn.new(rect, action, icon)

	var panel := Panel.new()
	panel.position  = rect.position
	panel.size      = rect.size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_style(panel, false)

	var lbl := Label.new()
	lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lbl.text = icon
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 22)
	lbl.add_theme_color_override("font_color", Color(0.90, 0.93, 1.0, 0.85))
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(lbl)

	add_child(panel)
	btn.panel = panel
	_buttons.append(btn)


# ── Input ─────────────────────────────────────────────────────────────────────

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_on_touch_down(event.index, event.position)
		else:
			_on_touch_up(event.index)
	elif event is InputEventScreenDrag:
		_on_drag(event.index, event.position)


func _on_touch_down(index: int, pos: Vector2) -> void:
	for btn: _Btn in _buttons:
		if btn.touch_index == -1 and btn.rect.has_point(pos):
			btn.touch_index = index
			_fire(btn, true)
			_apply_style(btn.panel, true)
			return


func _on_touch_up(index: int) -> void:
	for btn: _Btn in _buttons:
		if btn.touch_index == index:
			btn.touch_index = -1
			_fire(btn, false)
			_apply_style(btn.panel, false)
			return


func _on_drag(index: int, pos: Vector2) -> void:
	# Check if an already-pressed button's finger slid off it
	for btn: _Btn in _buttons:
		if btn.touch_index == index:
			if not btn.rect.has_point(pos):
				btn.touch_index = -1
				_fire(btn, false)
				_apply_style(btn.panel, false)
			return

	# Finger wasn't on a button — check for passby activation
	for btn: _Btn in _buttons:
		if btn.touch_index == -1 and btn.rect.has_point(pos):
			btn.touch_index = index
			_fire(btn, true)
			_apply_style(btn.panel, true)
			return


# ── Helpers ───────────────────────────────────────────────────────────────────

func _fire(btn: _Btn, pressed: bool) -> void:
	var ev := InputEventAction.new()
	ev.action   = btn.action
	ev.pressed  = pressed
	ev.strength = 1.0 if pressed else 0.0
	Input.parse_input_event(ev)


func _apply_style(panel: Panel, pressed: bool) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color     = Color(0.28, 0.50, 0.95, 0.82) if pressed else Color(0.08, 0.10, 0.18, 0.68)
	style.border_color = Color(0.55, 0.78, 1.00, 0.90) if pressed else Color(0.30, 0.50, 0.85, 0.55)
	style.set_border_width_all(2)
	style.set_corner_radius_all(14)
	panel.add_theme_stylebox_override("panel", style)
