class_name ObjectiveCard
extends PanelContainer

## Emitted when the player accepts the order.
signal order_accepted

enum State { AVAILABLE, ACTIVE, PICKED_UP, DELIVERED }

const _ORDER_FROM  := "Taco Stand"
const _ORDER_ITEM  := "3× Street Tacos"
const _ORDER_PAY   := "$6.50"
const _ORDER_ETA   := "~3 min"

var _state: State = State.AVAILABLE

# Sub-panels (one visible at a time)
var _available_panel: VBoxContainer
var _active_panel:    VBoxContainer
var _complete_panel:  VBoxContainer

# Shared refs needed for updates
var _accept_label: Label
var _time_label:   Label
var _tracker:      _ProgressTracker
var _pulse_tween:  Tween


# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	# Card floats in top-left corner, below the coin label
	anchor_left   = 0.0
	anchor_top    = 0.0
	anchor_right  = 0.0
	anchor_bottom = 0.0
	position = Vector2(20.0, 80.0)

	_apply_card_style()
	custom_minimum_size = Vector2(290.0, 0.0)

	_build_ui()
	_set_state(State.AVAILABLE)
	call_deferred("_fit")


func _apply_card_style() -> void:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.06, 0.08, 0.15, 0.94)
	s.border_color = Color(0.25, 0.45, 0.88, 0.85)
	s.set_border_width_all(2)
	s.set_corner_radius_all(9)
	s.set_content_margin_all(14)
	add_theme_stylebox_override("panel", s)


# ── UI construction ───────────────────────────────────────────────────────────

func _build_ui() -> void:
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 9)
	add_child(root)
	_build_available_panel(root)
	_build_active_panel(root)
	_build_complete_panel(root)


func _build_available_panel(parent: Control) -> void:
	_available_panel = VBoxContainer.new()
	_available_panel.add_theme_constant_override("separation", 7)
	parent.add_child(_available_panel)

	# Header row — icon | restaurant + badge | pay
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	_available_panel.add_child(header)

	var icon := _make_label("🛵", 28)
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(icon)

	var title_col := VBoxContainer.new()
	title_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_col)

	var badge := _make_label("NEW ORDER", 10, Color(0.35, 0.88, 0.48))
	title_col.add_child(badge)

	title_col.add_child(_make_label(_ORDER_FROM, 18))

	var pay := _make_label(_ORDER_PAY, 20, Color(0.95, 0.86, 0.15))
	pay.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(pay)

	# Item description
	_available_panel.add_child(_make_label(_ORDER_ITEM, 14, Color(0.72, 0.76, 0.86)))

	# ETA row
	var meta := HBoxContainer.new()
	_available_panel.add_child(meta)
	var eta := _make_label("⏱  " + _ORDER_ETA, 13, Color(0.58, 0.63, 0.74))
	eta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meta.add_child(eta)

	_available_panel.add_child(HSeparator.new())

	# Accept prompt — pulsed by tween
	_accept_label = _make_label("[ F ]  Accept Order  ▶", 15, Color(0.3, 0.90, 0.48))
	_accept_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_available_panel.add_child(_accept_label)


func _build_active_panel(parent: Control) -> void:
	_active_panel = VBoxContainer.new()
	_active_panel.add_theme_constant_override("separation", 9)
	parent.add_child(_active_panel)

	# Header
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	_active_panel.add_child(header)

	var icon := _make_label("🛵", 22)
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(icon)

	var title := _make_label("ACTIVE DELIVERY", 15, Color(0.3, 0.88, 0.48))
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	# Map placeholder
	var map_outer := PanelContainer.new()
	map_outer.custom_minimum_size = Vector2(262.0, 105.0)
	_active_panel.add_child(map_outer)

	var ms := StyleBoxFlat.new()
	ms.bg_color = Color(0.07, 0.10, 0.18)
	ms.border_color = Color(0.18, 0.30, 0.54, 0.65)
	ms.set_border_width_all(1)
	ms.set_corner_radius_all(5)
	map_outer.add_theme_stylebox_override("panel", ms)

	var map_center := CenterContainer.new()
	map_outer.add_child(map_center)

	var map_lbl := _make_label("MAP\n(coming soon)", 13, Color(0.28, 0.38, 0.56))
	map_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	map_center.add_child(map_lbl)

	# Progress tracker (custom drawn)
	_tracker = _ProgressTracker.new()
	_tracker.custom_minimum_size = Vector2(262.0, 55.0)
	_active_panel.add_child(_tracker)


func _build_complete_panel(parent: Control) -> void:
	_complete_panel = VBoxContainer.new()
	_complete_panel.add_theme_constant_override("separation", 7)
	parent.add_child(_complete_panel)

	# Header
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	_complete_panel.add_child(header)

	var check := _make_label("✓", 34, Color(0.3, 0.92, 0.42))
	check.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(check)

	var title_col := VBoxContainer.new()
	title_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_col)

	title_col.add_child(_make_label("DELIVERED!", 20, Color(0.3, 0.92, 0.42)))
	title_col.add_child(_make_label(_ORDER_ITEM, 13, Color(0.65, 0.68, 0.78)))

	_complete_panel.add_child(HSeparator.new())

	_time_label = _make_label("Time:  –", 26)
	_complete_panel.add_child(_time_label)

	_complete_panel.add_child(_make_label("🌟  Great delivery!", 13, Color(0.65, 0.68, 0.78)))


# ── Input ─────────────────────────────────────────────────────────────────────

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("accept_order") and _state == State.AVAILABLE:
		get_viewport().set_input_as_handled()
		_set_state(State.ACTIVE)
		order_accepted.emit()


# ── Public API ────────────────────────────────────────────────────────────────

## Call when the car enters the pickup zone (state must be ACTIVE).
func advance_to_picked_up() -> void:
	if _state == State.ACTIVE:
		_set_state(State.PICKED_UP)


## Call on successful delivery. elapsed is the total seconds since accepting.
func complete_delivery(elapsed: float) -> void:
	if _state == State.PICKED_UP:
		_set_state(State.DELIVERED)
		var mins := int(elapsed) / 60
		var secs := int(elapsed) % 60
		_time_label.text = "Time:  %d:%02d" % [mins, secs]


# ── State machine ─────────────────────────────────────────────────────────────

func _set_state(new_state: State) -> void:
	_state = new_state

	_available_panel.visible = (_state == State.AVAILABLE)
	_active_panel.visible    = (_state == State.ACTIVE or _state == State.PICKED_UP)
	_complete_panel.visible  = (_state == State.DELIVERED)

	if _tracker != null:
		_tracker.step = (
			0 if _state == State.ACTIVE else
			1 if _state == State.PICKED_UP else
			2 if _state == State.DELIVERED else
			0
		)
		if _active_panel.visible:
			_tracker.queue_redraw()

	if _pulse_tween:
		_pulse_tween.kill()
	if _state == State.AVAILABLE:
		_start_pulse()

	call_deferred("_fit")


func _start_pulse() -> void:
	if _accept_label == null:
		return
	_pulse_tween = create_tween().set_loops()
	_pulse_tween.tween_property(_accept_label, "modulate:a", 0.3, 0.65)
	_pulse_tween.tween_property(_accept_label, "modulate:a", 1.0, 0.65)


func _fit() -> void:
	# Resize card to wrap its visible content tightly
	size = Vector2.ZERO


# ── Helpers ───────────────────────────────────────────────────────────────────

func _make_label(text: String, font_size: int, color: Color = Color.WHITE) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", font_size)
	if color != Color.WHITE:
		lbl.add_theme_color_override("font_color", color)
	return lbl


# ── Inner class: three-step progress tracker ──────────────────────────────────

class _ProgressTracker extends Control:
	var step: int = 0

	const _LABELS    : Array[String] = ["Accepted", "Picked Up", "Delivered"]
	const _C_INACTIVE := Color(0.22, 0.24, 0.32)
	const _C_DONE     := Color(0.30, 0.90, 0.42)
	const _C_CURRENT  := Color(0.95, 0.86, 0.15)

	func _draw() -> void:
		var w    := size.x
		var cy   := size.y * 0.34       # vertical centre of dots
		var r    := 8.0
		var xs   := [w * 0.13, w * 0.50, w * 0.87]

		# Connecting lines (drawn first so dots sit on top)
		for i in 2:
			draw_line(Vector2(xs[i] + r + 3.0, cy),
					  Vector2(xs[i + 1] - r - 3.0, cy),
					  _C_DONE if step > i else _C_INACTIVE, 2.0)

		# Dots
		for i in 3:
			var c: Color = _C_DONE if i < step else (_C_CURRENT if i == step else _C_INACTIVE)
			draw_circle(Vector2(xs[i], cy), r, c)

		# Labels beneath dots
		var font := ThemeDB.fallback_font
		var fsz  := 11
		for i in 3:
			var col  := _C_DONE if i <= step else Color(0.48, 0.50, 0.60)
			var tw   := font.get_string_size(_LABELS[i], HORIZONTAL_ALIGNMENT_LEFT, -1, fsz).x
			draw_string(font,
						Vector2(xs[i] - tw * 0.5, cy + r + 16.0),
						_LABELS[i], HORIZONTAL_ALIGNMENT_LEFT, -1, fsz, col)
