class_name VirtualJoystick
extends Panel


## Action fired when the stick is pushed left.
@export var steer_left_action: String = "steer_left"

## Action fired when the stick is pushed right.
@export var steer_right_action: String = "steer_right"

## Max pixel distance the knob travels from the base center.
@export var max_radius: float = 62.0


@onready var _knob: Panel = $Knob


var _touch_index: int = -1
var _center: Vector2 = Vector2.ZERO


func _ready() -> void:
	_apply_base_style()
	_apply_knob_style(false)
	# Wait for the layout pass to resolve our size before centering the knob.
	await get_tree().process_frame
	_center = size * 0.5
	_reset_knob()


func _notification(what: int) -> void:
	# Keep the knob centered if the panel is resized (e.g. orientation change).
	if what != NOTIFICATION_RESIZED or not is_node_ready():
		return
	_center = size * 0.5
	if _touch_index == -1:
		_reset_knob()


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _touch_index == -1:
			var local: Vector2 = event.position - global_position
			if Rect2(Vector2.ZERO, size).has_point(local):
				_touch_index = event.index
				_update(local)
		elif not event.pressed and event.index == _touch_index:
			_release()

	elif event is InputEventScreenDrag and event.index == _touch_index:
		_update(event.position - global_position)


func _update(local_pos: Vector2) -> void:
	var offset: Vector2 = (local_pos - _center).limit_length(max_radius)
	_knob.position = _center + offset - _knob.size * 0.5
	_apply_knob_style(true)

	var x_norm: float = offset.x / max_radius
	if x_norm > 0.001:
		_send(steer_right_action, x_norm)
		_send(steer_left_action, 0.0)
	elif x_norm < -0.001:
		_send(steer_left_action, absf(x_norm))
		_send(steer_right_action, 0.0)
	else:
		_send(steer_left_action, 0.0)
		_send(steer_right_action, 0.0)


func _release() -> void:
	_touch_index = -1
	_send(steer_left_action, 0.0)
	_send(steer_right_action, 0.0)
	_reset_knob()
	_apply_knob_style(false)


func _reset_knob() -> void:
	_knob.position = _center - _knob.size * 0.5


func _send(action: String, strength: float) -> void:
	if strength > 0.001:
		Input.action_press(action, strength)
	else:
		Input.action_release(action)


func _apply_base_style() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.12, 0.22, 0.65)
	style.border_color = Color(0.30, 0.50, 0.85, 0.50)
	style.set_border_width_all(2)
	style.set_corner_radius_all(999)
	add_theme_stylebox_override("panel", style)


func _apply_knob_style(active: bool) -> void:
	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(999)
	style.set_border_width_all(2)
	if active:
		style.bg_color = Color(0.35, 0.62, 1.00, 0.90)
		style.border_color = Color(0.60, 0.82, 1.00, 0.95)
	else:
		style.bg_color = Color(0.22, 0.35, 0.72, 0.75)
		style.border_color = Color(0.45, 0.65, 0.95, 0.70)
	_knob.add_theme_stylebox_override("panel", style)
