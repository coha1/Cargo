class_name ObjectiveCard
extends PanelContainer

## Emitted when the player accepts the order.
signal order_accepted

## Emitted when the player declines an active order, resetting back to available.
signal order_declined

enum State { AVAILABLE, ACTIVE, PICKED_UP, DELIVERED }

const _ORDER_FROM := "Taco Stand"
const _ORDER_ITEM := "3× Street Tacos"
const _ORDER_PAY  := "$6.50"
const _ORDER_ETA  := "~3 min"

var _state: State = State.AVAILABLE

# Sub-panels (one visible at a time)
var _available_panel: VBoxContainer
var _active_panel:    VBoxContainer
var _complete_panel:  VBoxContainer

# Shared refs that need live updates
var _accept_label:   Label
var _elapsed_label:  Label   # live clock in active header
var _time_label:     Label   # final time on complete panel
var _star_label:     Label
var _feedback_label: Label
var _tracker:        _ProgressTracker
var _pulse_tween:    Tween


# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	anchor_left   = 0.0
	anchor_top    = 0.0
	anchor_right  = 0.0
	anchor_bottom = 0.0
	position = Vector2(20.0, 80.0)

	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.06, 0.08, 0.15, 0.94)
	s.border_color = Color(0.25, 0.45, 0.88, 0.85)
	s.set_border_width_all(2)
	s.set_corner_radius_all(9)
	s.set_content_margin_all(14)
	add_theme_stylebox_override("panel", s)

	custom_minimum_size = Vector2(290.0, 0.0)

	_build_ui()
	_set_state(State.AVAILABLE)
	call_deferred("_fit")


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

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	_available_panel.add_child(header)

	var icon := _lbl("🛵", 28)
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(icon)

	var title_col := VBoxContainer.new()
	title_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_col)
	title_col.add_child(_lbl("NEW ORDER", 10, Color(0.35, 0.88, 0.48)))
	title_col.add_child(_lbl(_ORDER_FROM, 18))

	var pay := _lbl(_ORDER_PAY, 20, Color(0.95, 0.86, 0.15))
	pay.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(pay)

	_available_panel.add_child(_lbl(_ORDER_ITEM, 14, Color(0.72, 0.76, 0.86)))

	var meta := HBoxContainer.new()
	_available_panel.add_child(meta)
	var eta := _lbl("⏱  " + _ORDER_ETA, 13, Color(0.58, 0.63, 0.74))
	eta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meta.add_child(eta)

	_available_panel.add_child(HSeparator.new())

	_accept_label = _lbl("[ F ]  Accept Order  ▶", 15, Color(0.3, 0.90, 0.48))
	_accept_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_available_panel.add_child(_accept_label)


func _build_active_panel(parent: Control) -> void:
	_active_panel = VBoxContainer.new()
	_active_panel.add_theme_constant_override("separation", 9)
	parent.add_child(_active_panel)

	# Header: icon | "ACTIVE DELIVERY" | live elapsed clock
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	_active_panel.add_child(header)

	var icon := _lbl("🛵", 22)
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(icon)

	var title := _lbl("ACTIVE DELIVERY", 15, Color(0.3, 0.88, 0.48))
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	_elapsed_label = _lbl("0:00", 17, Color(0.95, 0.86, 0.15))
	_elapsed_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_elapsed_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header.add_child(_elapsed_label)

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
	var map_lbl := _lbl("MAP\n(coming soon)", 13, Color(0.28, 0.38, 0.56))
	map_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	map_center.add_child(map_lbl)

	# Progress tracker — draws the three-step indicator with live fill
	_tracker = _ProgressTracker.new()
	_tracker.custom_minimum_size = Vector2(262.0, 58.0)
	_active_panel.add_child(_tracker)


func _build_complete_panel(parent: Control) -> void:
	_complete_panel = VBoxContainer.new()
	_complete_panel.add_theme_constant_override("separation", 7)
	parent.add_child(_complete_panel)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	_complete_panel.add_child(header)

	var check := _lbl("✓", 34, Color(0.3, 0.92, 0.42))
	check.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(check)

	var title_col := VBoxContainer.new()
	title_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_col)
	title_col.add_child(_lbl("DELIVERED!", 20, Color(0.3, 0.92, 0.42)))
	title_col.add_child(_lbl(_ORDER_ITEM, 13, Color(0.65, 0.68, 0.78)))

	_complete_panel.add_child(HSeparator.new())

	_time_label = _lbl("Time:  –", 26)
	_complete_panel.add_child(_time_label)

	_star_label = _lbl("★★★", 28, Color(0.95, 0.86, 0.15))
	_complete_panel.add_child(_star_label)

	_feedback_label = _lbl("Perfect delivery!", 13, Color(0.65, 0.68, 0.78))
	_complete_panel.add_child(_feedback_label)


# ── Input ─────────────────────────────────────────────────────────────────────

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("accept_order") and _state == State.AVAILABLE:
		get_viewport().set_input_as_handled()
		_set_state(State.ACTIVE)
		order_accepted.emit()
	elif event.is_action_pressed("decline_order") \
			and _state != State.AVAILABLE:
		get_viewport().set_input_as_handled()
		_set_state(State.AVAILABLE)
		order_declined.emit()


# ── Public API ────────────────────────────────────────────────────────────────

## Updates the live elapsed timer shown in the active panel header.
func update_elapsed(t: float) -> void:
	if _elapsed_label == null:
		return
	_elapsed_label.text = "%d:%02d" % [int(t) / 60, int(t) % 60]


## Updates the progress fill on both connector lines. Values are 0.0 – 1.0.
## line1 = progress toward pickup; line2 = progress toward delivery (post-pickup).
func update_tracker_progress(line1: float, line2: float) -> void:
	if _tracker == null:
		return
	_tracker.line1_progress = line1
	_tracker.line2_progress = line2
	_tracker.queue_redraw()


## Advances from ACTIVE → PICKED_UP (guards state internally).
func advance_to_picked_up() -> void:
	if _state == State.ACTIVE:
		_set_state(State.PICKED_UP)


## Finalises the delivery. elapsed = total seconds; stars = 1, 2, or 3.
func complete_delivery(elapsed: float, stars: int) -> void:
	if _state == State.PICKED_UP:
		_set_state(State.DELIVERED)
		_time_label.text = "Time:  %d:%02d" % [int(elapsed) / 60, int(elapsed) % 60]
		_star_label.text    = "★".repeat(stars) + "☆".repeat(3 - stars)
		_feedback_label.text = (
			"Perfect delivery!" if stars == 3 else
			"Good job!"        if stars == 2 else
			"Delivered!"
		)
		# Colour the stars to match rating
		var star_col := (
			Color(0.95, 0.86, 0.15) if stars == 3 else
			Color(0.75, 0.75, 0.75) if stars == 2 else
			Color(0.60, 0.60, 0.60)
		)
		_star_label.add_theme_color_override("font_color", star_col)


# ── State machine ─────────────────────────────────────────────────────────────

func _set_state(new_state: State) -> void:
	_state = new_state

	_available_panel.visible = (_state == State.AVAILABLE)
	_active_panel.visible    = (_state == State.ACTIVE or _state == State.PICKED_UP)
	_complete_panel.visible  = (_state == State.DELIVERED)

	if _state == State.AVAILABLE:
		if _tracker != null:
			_tracker.line1_progress = 0.0
			_tracker.line2_progress = 0.0
		if _elapsed_label != null:
			_elapsed_label.text = "0:00"

	if _tracker != null:
		_tracker.step = (
			0 if _state == State.ACTIVE else
			1 if _state == State.PICKED_UP else
			2 if _state == State.DELIVERED else 0
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
	size = Vector2.ZERO


# ── Helper ────────────────────────────────────────────────────────────────────

func _lbl(text: String, font_size: int, color: Color = Color.WHITE) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	if color != Color.WHITE:
		l.add_theme_color_override("font_color", color)
	return l


# ── Inner class: three-step progress tracker ──────────────────────────────────

class _ProgressTracker extends Control:
	## Which step is the "current" highlighted dot (0 = accepted, 1 = picked up, 2 = delivered)
	var step: int = 0
	## 0–1 fill on the line from Accepted → Picked Up (driven by distance to pickup)
	var line1_progress: float = 0.0
	## 0–1 fill on the line from Picked Up → Delivered (driven by distance to delivery)
	var line2_progress: float = 0.0

	const _LABELS   : Array[String] = ["Accepted", "Picked Up", "Delivered"]
	const _C_TRACK  := Color(0.22, 0.24, 0.32)          # inactive track
	const _C_DONE   := Color(0.30, 0.90, 0.42)          # completed dot / line
	const _C_CUR    := Color(0.95, 0.86, 0.15)          # current dot highlight
	const _C_PROG   := Color(0.95, 0.86, 0.15)          # progress fill on line

	func _draw() -> void:
		var w: float = size.x
		var cy: float = size.y * 0.33
		var r: float = 8.0
		var xs: Array[float] = [w * 0.13, w * 0.50, w * 0.87]

		# Line segment endpoints — inset from each dot's edge
		var gap: float = r + 4.0
		var lx0: float = xs[0] + gap
		var rx0: float = xs[1] - gap
		var lx1: float = xs[1] + gap
		var rx1: float = xs[2] - gap

		# ── Inactive background tracks ────────────────────────────────────────
		draw_line(Vector2(lx0, cy), Vector2(rx0, cy), _C_TRACK, 2.0)
		draw_line(Vector2(lx1, cy), Vector2(rx1, cy), _C_TRACK, 2.0)

		# ── Progress fill — line 1 (accepted → pickup) ────────────────────────
		# Once picked up the whole line turns "done" green.
		if step >= 1:
			draw_line(Vector2(lx0, cy), Vector2(rx0, cy), _C_DONE, 3.0)
		elif line1_progress > 0.0:
			draw_line(Vector2(lx0, cy),
					  Vector2(lerpf(lx0, rx0, line1_progress), cy),
					  _C_PROG, 3.0)

		# ── Progress fill — line 2 (pickup → delivery) ───────────────────────
		if step >= 2:
			draw_line(Vector2(lx1, cy), Vector2(rx1, cy), _C_DONE, 3.0)
		elif step == 1 and line2_progress > 0.0:
			draw_line(Vector2(lx1, cy),
					  Vector2(lerpf(lx1, rx1, line2_progress), cy),
					  _C_PROG, 3.0)

		# ── Dots ──────────────────────────────────────────────────────────────
		for i in 3:
			var c: Color = _C_DONE if i < step else (_C_CUR if i == step else _C_TRACK)
			draw_circle(Vector2(xs[i], cy), r, c)

		# ── Labels below dots ─────────────────────────────────────────────────
		var font: Font = ThemeDB.fallback_font
		var fsz: int = 11
		for i in 3:
			var col: Color = _C_DONE if i <= step else Color(0.48, 0.50, 0.60)
			var tw: float = font.get_string_size(_LABELS[i], HORIZONTAL_ALIGNMENT_LEFT, -1, fsz).x
			draw_string(font,
						Vector2(xs[i] - tw * 0.5, cy + r + 15.0),
						_LABELS[i], HORIZONTAL_ALIGNMENT_LEFT, -1, fsz, col)
